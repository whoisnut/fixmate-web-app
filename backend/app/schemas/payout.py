from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class PayoutCreate(BaseModel):
    amount: float
    method: str  # "aba_pay", "wing", "bank_transfer"
    payment_account: str  # Account number or payment ID

class PayoutStatusUpdate(BaseModel):
    status: str  # "approved" or "rejected"
    reason: Optional[str] = None  # Required for rejection

class PayoutResponse(BaseModel):
    id: str
    user_id: str
    amount: float
    method: str
    status: str
    payment_account: str
    reason: Optional[str]
    requested_at: datetime
    processed_at: Optional[datetime]

    class Config:
        from_attributes = True
