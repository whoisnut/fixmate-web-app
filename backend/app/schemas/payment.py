from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class PaymentCreate(BaseModel):
    booking_id: str
    amount: float
    method: str  # "card", "wallet", "cash", etc.

class PaymentResponse(BaseModel):
    id: str
    booking_id: str
    amount: float
    method: str
    status: str
    transaction_id: Optional[str]
    paid_at: Optional[datetime]

    class Config:
        from_attributes = True
