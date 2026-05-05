from typing import Optional
from datetime import datetime
from pydantic import BaseModel, Field

from app.schemas.base_schema import Base


class PayoutCreate(Base):
    """Schema for payout creation."""
    amount              : float  = Field(..., ge=5.0)
    method              : str
    payment_account     : str


class PayoutStatusUpdate(Base):
    """Schema for payout status update."""
    reason              : Optional[str]  = None


class PayoutResponse(Base):
    """Schema for payout response."""
    id                  : str
    user_id             : str
    amount              : float
    method              : str
    status              : str
    reason              : Optional[str]
    requested_at        : datetime
    processed_at        : Optional[datetime]
    created_at          : datetime
