from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import and_
from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.user import User, Technician
from app.models.booking import Booking
from app.schemas.booking import BookingCreate, BookingResponse
from typing import List, Optional

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
def get_bookings(
    current_user: User = Depends(get_current_user),
    status: Optional[str] = Query(None),
    db: Session = Depends(get_db)
):
    query = None
    if current_user.role == "customer":
        query = db.query(Booking).filter(Booking.customer_id == current_user.id)
    elif current_user.role == "technician":
        technician = db.query(Technician).filter(Technician.user_id == current_user.id).first()
        if technician:
            query = db.query(Booking).filter(Booking.technician_id == technician.id)
    
    if query is None:
        return []
    
    if status:
        query = query.filter(Booking.status == status)
    
    return query.all()

@router.get("/available", response_model=List[BookingResponse])
def get_available_bookings(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get all available bookings for technicians to accept"""
    if current_user.role != "technician":
        raise HTTPException(status_code=403, detail="Only technicians can access this")
    
    available_bookings = db.query(Booking).filter(
        Booking.status == "pending",
        Booking.technician_id == None
    ).all()
    return available_bookings

@router.get("/{booking_id}", response_model=BookingResponse)
def get_booking(
    booking_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    
    # Verify the user has access to this booking
    if current_user.role == "customer" and booking.customer_id != current_user.id:
        raise HTTPException(status_code=403, detail="Access denied")
    elif current_user.role == "technician":
        technician = db.query(Technician).filter(Technician.user_id == current_user.id).first()
        if booking.technician_id != technician.id:
            raise HTTPException(status_code=403, detail="Access denied")
    
    return booking

@router.put("/{booking_id}", response_model=BookingResponse)
def update_booking(
    booking_id: str,
    status: Optional[str] = Query(None),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    
    # Verify permissions
    if current_user.role == "customer" and booking.customer_id != current_user.id:
        raise HTTPException(status_code=403, detail="Access denied")
    
    if status:
        booking.status = status
    
    db.commit()
    db.refresh(booking)
    return booking

@router.post("/{booking_id}/accept", response_model=BookingResponse)
def accept_booking(
    booking_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Technician accepts a booking"""
    if current_user.role != "technician":
        raise HTTPException(status_code=403, detail="Only technicians can accept bookings")
    
    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    
    if booking.status != "pending":
        raise HTTPException(status_code=400, detail="Booking is not available")
    
    technician = db.query(Technician).filter(Technician.user_id == current_user.id).first()
    booking.technician_id = technician.id
    booking.status = "accepted"
    
    db.commit()
    db.refresh(booking)
    return booking

@router.post("/{booking_id}/start", response_model=BookingResponse)
def start_booking(
    booking_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Technician starts the job"""
    if current_user.role != "technician":
        raise HTTPException(status_code=403, detail="Only technicians can start bookings")
    
    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    
    technician = db.query(Technician).filter(Technician.user_id == current_user.id).first()
    if booking.technician_id != technician.id:
        raise HTTPException(status_code=403, detail="This booking is not assigned to you")
    
    if booking.status != "accepted":
        raise HTTPException(status_code=400, detail="Booking must be accepted first")
    
    booking.status = "in_progress"
    db.commit()
    db.refresh(booking)
    return booking

@router.post("/{booking_id}/complete", response_model=BookingResponse)
def complete_booking(
    booking_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Technician completes the job"""
    if current_user.role != "technician":
        raise HTTPException(status_code=403, detail="Only technicians can complete bookings")
    
    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    
    technician = db.query(Technician).filter(Technician.user_id == current_user.id).first()
    if booking.technician_id != technician.id:
        raise HTTPException(status_code=403, detail="This booking is not assigned to you")
    
    if booking.status != "in_progress":
        raise HTTPException(status_code=400, detail="Booking must be in progress")
    
    booking.status = "completed"
    technician.total_jobs += 1
    
    db.commit()
    db.refresh(booking)
    return booking

@router.delete("/{booking_id}")
def cancel_booking(
    booking_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    
    # Verify permissions
    if current_user.role == "customer" and booking.customer_id != current_user.id:
        raise HTTPException(status_code=403, detail="Access denied")
    
    if booking.status in ["completed", "cancelled"]:
        raise HTTPException(status_code=400, detail="Cannot cancel this booking")
    
    booking.status = "cancelled"
    db.commit()
    
    return {"message": "Booking cancelled successfully"}
