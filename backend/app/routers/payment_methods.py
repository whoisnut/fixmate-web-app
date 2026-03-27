from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.user import User
from app.models.booking import PaymentMethod
from app.schemas.payment_method import PaymentMethodCreate, PaymentMethodResponse, PaymentMethodUpdate
from typing import List
import uuid
import re

router = APIRouter(prefix="/api/payment-methods", tags=["Payment Methods"])

def detect_card_brand(card_number: str) -> str:
    """Detect card brand from card number"""
    card_number = card_number.replace(" ", "").replace("-", "")

    if re.match(r"^4", card_number):
        return "visa"
    elif re.match(r"^5[1-5]", card_number) or re.match(r"^2[2-7]", card_number):
        return "mastercard"
    elif re.match(r"^3[47]", card_number):
        return "amex"
    elif re.match(r"^6(?:011|5)", card_number):
        return "discover"
    else:
        return "unknown"

@router.get("", response_model=List[PaymentMethodResponse])
def get_payment_methods(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get all payment methods for current user"""
    payment_methods = db.query(PaymentMethod).filter(
        PaymentMethod.user_id == current_user.id
    ).all()
    return payment_methods

@router.post("", response_model=PaymentMethodResponse)
def create_payment_method(
    payment_method_data: PaymentMethodCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Create a new payment method"""
    # Validate card number format
    card_number = payment_method_data.card_number.replace(" ", "").replace("-", "")
    if not re.match(r"^\d{13,19}$", card_number):
        raise HTTPException(status_code=400, detail="Invalid card number")

    # Validate expiry
    try:
        expiry_month = int(payment_method_data.expiry_month)
        expiry_year = int(payment_method_data.expiry_year)
        if not (1 <= expiry_month <= 12):
            raise ValueError()
        if expiry_year < 2024:
            raise ValueError()
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid expiry date")

    # Detect brand
    brand = detect_card_brand(card_number)
    if brand == "unknown":
        raise HTTPException(status_code=400, detail="Unsupported card type")

    # Check if this is the first payment method (make it default)
    existing_methods = db.query(PaymentMethod).filter(
        PaymentMethod.user_id == current_user.id
    ).count()

    # In a real app, you'd tokenize the card with Stripe here
    # For now, we'll just store the last 4 digits
    last_four = card_number[-4:]

    payment_method = PaymentMethod(
        id=str(uuid.uuid4()),
        user_id=current_user.id,
        type="credit_card",
        cardholder_name=payment_method_data.cardholder_name,
        last_four_digits=last_four,
        expiry_month=payment_method_data.expiry_month.zfill(2),
        expiry_year=payment_method_data.expiry_year,
        brand=brand,
        is_default="1" if existing_methods == 0 else "0",
        stripe_payment_method_id=None  # Would be set after Stripe tokenization
    )

    db.add(payment_method)
    db.commit()
    db.refresh(payment_method)
    return payment_method

@router.put("/{payment_method_id}", response_model=PaymentMethodResponse)
def update_payment_method(
    payment_method_id: str,
    update_data: PaymentMethodUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Update a payment method"""
    payment_method = db.query(PaymentMethod).filter(
        PaymentMethod.id == payment_method_id,
        PaymentMethod.user_id == current_user.id
    ).first()

    if not payment_method:
        raise HTTPException(status_code=404, detail="Payment method not found")

    if update_data.is_default is not None:
        if update_data.is_default:
            # Unset other default methods
            db.query(PaymentMethod).filter(
                PaymentMethod.user_id == current_user.id,
                PaymentMethod.id != payment_method_id
            ).update({"is_default": "0"})

        payment_method.is_default = "1" if update_data.is_default else "0"

    db.commit()
    db.refresh(payment_method)
    return payment_method

@router.patch("/{payment_method_id}/set-default")
def set_default_payment_method(
    payment_method_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Set the given payment method as default"""
    payment_method = db.query(PaymentMethod).filter(
        PaymentMethod.id == payment_method_id,
        PaymentMethod.user_id == current_user.id
    ).first()

    if not payment_method:
        raise HTTPException(status_code=404, detail="Payment method not found")

    # Unset all other methods for this user
    db.query(PaymentMethod).filter(
        PaymentMethod.user_id == current_user.id,
        PaymentMethod.id != payment_method_id
    ).update({"is_default": "0"})

    payment_method.is_default = "1"
    db.commit()
    db.refresh(payment_method)

    return {"message": "Payment method set as default"}

@router.delete("/{payment_method_id}")
def delete_payment_method(
    payment_method_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Delete a payment method"""
    payment_method = db.query(PaymentMethod).filter(
        PaymentMethod.id == payment_method_id,
        PaymentMethod.user_id == current_user.id
    ).first()

    if not payment_method:
        raise HTTPException(status_code=404, detail="Payment method not found")

    # Don't allow deleting the last payment method if there are pending bookings
    # (simplified check - in real app, check for unpaid bookings)
    other_methods = db.query(PaymentMethod).filter(
        PaymentMethod.user_id == current_user.id,
        PaymentMethod.id != payment_method_id
    ).count()

    if other_methods == 0:
        # Check if user has any pending payments
        from app.models.booking import Booking, Payment
        pending_payments = db.query(Payment).join(Booking).filter(
            Booking.customer_id == current_user.id,
            Payment.status == "pending"
        ).count()

        if pending_payments > 0:
            raise HTTPException(
                status_code=400,
                detail="Cannot delete last payment method with pending payments"
            )

    db.delete(payment_method)
    db.commit()
    return {"message": "Payment method deleted successfully"}