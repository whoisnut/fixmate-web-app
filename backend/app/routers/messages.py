from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.user import User
from app.models.booking import Booking, Message
from app.schemas.booking import MessageCreate, MessageResponse
from typing import List
from datetime import datetime

router = APIRouter(prefix="/api/messages", tags=["Messages"])

@router.get("/user/chats")
def get_user_chats(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get all chat bookings for current user"""
    # Get bookings where user is customer or technician
    bookings = db.query(Booking).filter(
        (Booking.customer_id == current_user.id) | (Booking.technician_id == current_user.id)
    ).all()
    
    chats = []
    for booking in bookings:
        # Get latest message
        latest_msg = db.query(Message).filter(
            Message.booking_id == booking.id
        ).order_by(Message.sent_at.desc()).first()
        
        # Determine the other user
        if booking.customer_id == current_user.id:
            other_user = db.query(User).filter(User.id == booking.technician_id).first()
        else:
            other_user = db.query(User).filter(User.id == booking.customer_id).first()
        
        chats.append({
            "booking_id": booking.id,
            "other_user": {
                "id": other_user.id if other_user else None,
                "name": other_user.name if other_user else "Unknown",
                "avatar_url": other_user.avatar_url if other_user else None
            },
            "booking_status": booking.status,
            "service_name": booking.service.name if booking.service else "N/A",
            "latest_message": latest_msg.content if latest_msg else None,
            "latest_message_time": latest_msg.sent_at if latest_msg else None
        })
    
    return chats

@router.post("/{booking_id}", response_model=MessageResponse)
def send_message(
    booking_id: str,
    message_data: MessageCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Send a message in a booking chat"""
    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")

    if current_user.id != booking.customer_id and current_user.id != booking.technician_id:
        raise HTTPException(status_code=403, detail="Access denied")

    message = Message(
        booking_id=booking_id,
        sender_id=current_user.id,
        content=message_data.content
    )

    db.add(message)
    db.commit()
    db.refresh(message)
    return message

@router.get("/{booking_id}", response_model=List[MessageResponse])
def get_booking_messages(
    booking_id: str,
    limit: int = 50,
    offset: int = 0,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get all messages for a booking"""
    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")

    if current_user.id != booking.customer_id and current_user.id != booking.technician_id:
        raise HTTPException(status_code=403, detail="Access denied")

    messages = db.query(Message).filter(
        Message.booking_id == booking_id
    ).order_by(Message.sent_at).offset(offset).limit(limit).all()

    return messages

@router.delete("/{message_id}")
def delete_message(
    message_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Delete a message (only by sender)"""
    message = db.query(Message).filter(Message.id == message_id).first()
    if not message:
        raise HTTPException(status_code=404, detail="Message not found")
    
    if message.sender_id != current_user.id:
        raise HTTPException(status_code=403, detail="Access denied")
    
    db.delete(message)
    db.commit()
    return {"message": "Message deleted"}

@router.put("/{message_id}")
def edit_message(
    message_id: str,
    message_data: MessageCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Edit a message (only by sender)"""
    message = db.query(Message).filter(Message.id == message_id).first()
    if not message:
        raise HTTPException(status_code=404, detail="Message not found")
    
    if message.sender_id != current_user.id:
        raise HTTPException(status_code=403, detail="Access denied")
    
    # Only allow edit within 15 minutes
    time_since_sent = datetime.utcnow() - message.sent_at
    if time_since_sent.total_seconds() > 900:  # 15 minutes
        raise HTTPException(status_code=400, detail="Message too old to edit")
    
    message.content = message_data.content
    db.commit()
    db.refresh(message)
    return message
