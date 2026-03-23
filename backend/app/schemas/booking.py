from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class BookingCreate(BaseModel):
    service_id: str
    address: str
    lat: float
    lng: float
    scheduled_at: Optional[datetime] = None
    notes: Optional[str] = None

class BookingResponse(BaseModel):
    id: str
    customer_id: str
    technician_id: Optional[str]
    service_id: str
    status: str
    address: str
    lat: float
    lng: float
    total_price: float
    notes: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True
