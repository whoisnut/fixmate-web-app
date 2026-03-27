from pydantic import BaseModel, validator
from typing import Optional
from datetime import datetime

class PaymentMethodCreate(BaseModel):
    cardholder_name: str
    card_number: str
    expiry_month: str
    expiry_year: str
    cvc: str

class PaymentMethodResponse(BaseModel):
    id: str
    type: str
    cardholder_name: str
    last_four_digits: str
    expiry_month: str
    expiry_year: str
    brand: str
    is_default: bool
    created_at: datetime

    @validator("is_default", pre=True)
    def parse_is_default(cls, value):
        if isinstance(value, str):
            return value == "1"
        return bool(value)

    class Config:
        from_attributes = True

class PaymentMethodUpdate(BaseModel):
    is_default: Optional[bool] = None