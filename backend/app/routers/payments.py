from fastapi import APIRouter, Depends, HTTPException, Header
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.deps import get_current_user
from app.core.security import verify_token
from app.models.user import User
from app.models.booking import Booking, Payment
from app.schemas.payment import PaymentCreate, PaymentResponse, PaymentStatusUpdate
from typing import List, Optional
from datetime import datetime
import uuid
import hmac
import hashlib
from app.core.config import settings

router = APIRouter(prefix="/api/payments", tags=["Payments"])

def verify_webhook_signature(body: str, signature: str) -> bool:
    """Verify Stripe webhook signature"""
    expected_signature = hmac.new(
        settings.STRIPE_WEBHOOK_SECRET.encode(),
        body.encode(),
        hashlib.sha256
    ).hexdigest()
    return hmac.compare_digest(signature, expected_signature)

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
    status_update: PaymentStatusUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Update payment status (admin only)"""
    # Verify admin role
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Only admins can update payment status")
    
    payment = db.query(Payment).filter(Payment.id == payment_id).first()
    if not payment:
        raise HTTPException(status_code=404, detail="Payment not found")
    
    payment.status = status_update.status
    if status_update.transaction_id:
        payment.transaction_id = status_update.transaction_id
    
    if status_update.status == "completed":
        payment.paid_at = datetime.utcnow()
        booking = db.query(Booking).filter(Booking.id == payment.booking_id).first()
        if booking:
            booking.total_price = payment.amount
    
    db.commit()
    db.refresh(payment)
    return payment

@router.post("/webhook/stripe")
def stripe_webhook(
    request_body: dict,
    x_stripe_signature: Optional[str] = Header(None),
    db: Session = Depends(get_db)
):
    """Handle Stripe webhook with signature verification"""
    if not x_stripe_signature:
        raise HTTPException(status_code=400, detail="Missing signature header")
    
    # Verify webhook signature
    import json
    body_str = json.dumps(request_body)
    if not verify_webhook_signature(body_str, x_stripe_signature):
        raise HTTPException(status_code=400, detail="Invalid signature")
    
    # Handle the webhook event
    event_type = request_body.get("type")
    event_data = request_body.get("data", {}).get("object", {})
    
    if event_type == "charge.succeeded":
        payment_intent_id = event_data.get("payment_intent")
        payment = db.query(Payment).filter(Payment.transaction_id == payment_intent_id).first()
        if payment:
            payment.status = "completed"
            payment.paid_at = datetime.utcnow()
            db.commit()
    
    return {"status": "received"}

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
