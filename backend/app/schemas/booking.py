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
    total_price: Optional[float] = None  # Optional: defaults to service.min_price

class BookingStatusUpdate(BaseModel):
    status: str

class ServiceInBooking(BaseModel):
    id: str
    name: str
    description: Optional[str]
    min_price: float
    max_price: float

    class Config:
        from_attributes = True

class BookingResponse(BaseModel):
    id: str
    customer_id: str
    technician_id: Optional[str]
    service_id: str
    service: ServiceInBooking
    status: str
    address: str
    lat: float
    lng: float
    total_price: float
    notes: Optional[str]
    scheduled_at: Optional[datetime]
    created_at: datetime

    class Config:
        from_attributes = True

class ReviewCreate(BaseModel):
    rating: int  # 1-5
    comment: Optional[str] = None

class ReviewResponse(BaseModel):
    id: str
    booking_id: str
    rating: int
    comment: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True

class MessageCreate(BaseModel):
    content: str

class MessageResponse(BaseModel):
    id: str
    booking_id: str
    sender_id: str
    content: str
    sent_at: datetime

    class Config:
        from_attributes = True

    class Config:
        from_attributes = True

