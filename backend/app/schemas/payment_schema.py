from typing import Optional
from datetime import datetime
from pydantic import BaseModel, Field

from app.schemas.base_schema import Base


class PaymentCreate(Base):
    """Schema for payment creation."""
    booking_id          : str
    amount              : float  = Field(..., gt=0)
    method              : str


class PaymentStatusUpdate(Base):
    """Schema for payment status update."""
    status              : str
    transaction_id      : Optional[str]  = None


class PaymentResponse(Base):
    """Schema for payment response."""
    id                  : str
    booking_id          : str
    amount              : float
    method              : str
    status              : str
    transaction_id      : Optional[str]
    paid_at             : Optional[datetime]
    created_at          : datetime


class PaymentMethodCreate(Base):
    """Schema for payment method creation."""
    cardholder_name     : str
    card_number         : str
    expiry_month        : str
    expiry_year         : str


class PaymentMethodUpdate(Base):
    """Schema for payment method update."""
    is_default          : Optional[bool] = None


class PaymentMethodResponse(Base):
    """Schema for payment method response."""
    id                  : str
    user_id             : str
    type                : str
    cardholder_name: Optional[str]
    last_four_digits: str
    expiry_month: str
    expiry_year: str
    brand: str
    is_default: bool
    created_at: datetime
