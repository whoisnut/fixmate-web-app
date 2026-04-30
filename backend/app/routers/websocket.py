from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends, Query
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.security import decode_token
from app.models.user import User, Technician
from app.models.booking import Booking
from app.websockets.manager import manager
import json

router = APIRouter(tags=["WebSocket"])


@router.websocket("/api/ws/{user_id}")
async def websocket_endpoint(
    websocket: WebSocket,
    user_id: str,
    token: str = Query(...),
    db: Session = Depends(get_db),
):
    # Verify token belongs to this user
    payload = decode_token(token)
    if not payload or payload.get("sub") != user_id:
        await websocket.close(code=4001)
        return

    await manager.connect(user_id, websocket)
    try:
        while True:
            raw = await websocket.receive_text()
            try:
                msg = json.loads(raw)
            except json.JSONDecodeError:
                continue

            msg_type = msg.get("type")
            data = msg.get("data", {})

            if msg_type == "location_update":
                # Technician sends their current location
                lat = data.get("lat")
                lng = data.get("lng")
                booking_id = data.get("booking_id")

                if lat and lng:
                    tech = db.query(Technician).filter(Technician.user_id == user_id).first()
                    if tech:
                        tech.current_lat = lat
                        tech.current_lng = lng
                        db.commit()

                if booking_id:
                    booking = db.query(Booking).filter(Booking.id == booking_id).first()
                    if booking:
                        await manager.send(booking.customer_id, {
                            "type": "location_update",
                            "data": {"lat": lat, "lng": lng, "booking_id": booking_id},
                        })

            elif msg_type == "booking_status":
                booking_id = data.get("booking_id")
                new_status = data.get("status")
                if booking_id and new_status:
                    booking = db.query(Booking).filter(Booking.id == booking_id).first()
                    if booking:
                        # Notify customer of status change
                        await manager.send(booking.customer_id, {
                            "type": "booking_status",
                            "data": {"booking_id": booking_id, "status": new_status},
                        })

            elif msg_type == "eta_update":
                booking_id = data.get("booking_id")
                eta_minutes = data.get("eta_minutes")
                message_text = data.get("message", "")
                if booking_id:
                    booking = db.query(Booking).filter(Booking.id == booking_id).first()
                    if booking:
                        await manager.send(booking.customer_id, {
                            "type": "eta_update",
                            "data": {
                                "booking_id": booking_id,
                                "eta_minutes": eta_minutes,
                                "message": message_text,
                            },
                        })

            elif msg_type == "new_message":
                # Chat message notification
                booking_id = data.get("booking_id")
                recipient_id = data.get("recipient_id")
                if recipient_id:
                    await manager.send(recipient_id, {
                        "type": "new_message",
                        "data": data,
                    })

    except WebSocketDisconnect:
        manager.disconnect(user_id)
