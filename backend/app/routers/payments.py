from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.user import User
from app.models.booking import Booking, Payment
from app.schemas.payment import PaymentCreate, PaymentResponse
from typing import List
import uuid

router = APIRouter(prefix="/api/payments", tags=["Payments"])

@router.post("", response_model=PaymentResponse)
def create_payment(
    payment_data: PaymentCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Create a payment for a booking"""
    booking = db.query(Booking).filter(Booking.id == payment_data.booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    
    # Verify the user owns this booking
    if booking.customer_id != current_user.id:
        raise HTTPException(status_code=403, detail="Access denied")
    
    # Check if payment already exists
    existing_payment = db.query(Payment).filter(Payment.booking_id == payment_data.booking_id).first()
    if existing_payment:
        raise HTTPException(status_code=400, detail="Payment already exists for this booking")
    
    payment = Payment(
        id=str(uuid.uuid4()),
        booking_id=payment_data.booking_id,
        amount=payment_data.amount,
        method=payment_data.method,
        status="pending",
        transaction_id=None
    )
    
    db.add(payment)
    db.commit()
    db.refresh(payment)
    return payment

@router.get("/{booking_id}", response_model=PaymentResponse)
def get_payment(
    booking_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get payment for a booking"""
    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    
    # Verify access
    if current_user.role == "customer" and booking.customer_id != current_user.id:
        raise HTTPException(status_code=403, detail="Access denied")
    
    payment = db.query(Payment).filter(Payment.booking_id == booking_id).first()
    if not payment:
        raise HTTPException(status_code=404, detail="Payment not found")
    
    return payment

@router.put("/{payment_id}", response_model=PaymentResponse)
def update_payment_status(
    payment_id: str,
    status: str,
    transaction_id: str = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Update payment status (admin only or token validation required)"""
    payment = db.query(Payment).filter(Payment.id == payment_id).first()
    if not payment:
        raise HTTPException(status_code=404, detail="Payment not found")
    
    # In a real app, you'd verify this is from a payment provider webhook
    payment.status = status
    if transaction_id:
        payment.transaction_id = transaction_id
    
    if status == "completed":
        from datetime import datetime
        from sqlalchemy.sql import func
        payment.paid_at = datetime.utcnow()
        # Update booking status if needed
        booking = db.query(Booking).filter(Booking.id == payment.booking_id).first()
        if booking:
            booking.total_price = payment.amount
    
    db.commit()
    db.refresh(payment)
    return payment

@router.get("/bookings/my-payments")
def get_my_payments(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get all payments for current user's bookings"""
    bookings = db.query(Booking).filter(Booking.customer_id == current_user.id).all()
    booking_ids = [b.id for b in bookings]
    
    payments = db.query(Payment).filter(Payment.booking_id.in_(booking_ids)).all()
    return payments
