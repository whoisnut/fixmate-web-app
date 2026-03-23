from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.user import User
from app.models.booking import Booking
from app.schemas.booking import BookingCreate, BookingResponse
from typing import List

router = APIRouter(prefix="/api/bookings", tags=["Bookings"])

@router.post("", response_model=BookingResponse)
def create_booking(
    booking_data: BookingCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    booking = Booking(
        customer_id=current_user.id,
        service_id=booking_data.service_id,
        address=booking_data.address,
        lat=booking_data.lat,
        lng=booking_data.lng,
        scheduled_at=booking_data.scheduled_at,
        notes=booking_data.notes,
        status="pending"
    )
    db.add(booking)
    db.commit()
    db.refresh(booking)
    return booking

@router.get("", response_model=List[BookingResponse])
def get_bookings(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    if current_user.role == "customer":
        return db.query(Booking).filter(Booking.customer_id == current_user.id).all()
    elif current_user.role == "technician":
        return db.query(Booking).filter(Booking.technician_id == current_user.technician.id).all()
    return []

@router.get("/{booking_id}", response_model=BookingResponse)
def get_booking(booking_id: str, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    return booking
