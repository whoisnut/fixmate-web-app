from typing import Optional
from datetime import datetime
from pydantic import BaseModel, Field

from app.schemas.base_schema import Base


class BookingCreate(Base):
    """Schema for booking creation."""
    service_id          : str
    address             : str
    lat                 : float
    lng                 : float
    scheduled_at        : Optional[datetime]   = None
    notes               : Optional[str]        = None
    total_price         : Optional[float]      = None


class BookingStatusUpdate(Base):
    """Schema for booking status update."""
    status              : str


class BookingResponse(Base):
    """Schema for booking response."""
    id                  : str
    customer_id         : str
    technician_id       : Optional[str]
    service_id          : str
    address             : str
    lat                 : float
    lng                 : float
    scheduled_at        : Optional[datetime]
    status              : str
    total_price         : float
    notes               : Optional[str]
    created_at          : datetime
    updated_at          : datetime


class BookingWithDetailsResponse(Base):
    """Schema for booking response with service details."""
    id                  : str
    customer_id         : str
    technician_id       : Optional[str]
    service_id          : str
    address             : str
    lat                 : float
    lng                 : float
    scheduled_at        : Optional[datetime]
    status              : str
    total_price         : float
    notes               : Optional[str]
    created_at          : datetime
    updated_at          : datetime
    service             : Optional['ServiceResponse']  = None


class ReviewCreate(Base):
    """Schema for review creation."""
    rating              : int  = Field(..., ge=1, le=5)
    comment             : Optional[str]  = None


class ReviewResponse(Base):
    """Schema for review response."""
    id                  : str
    booking_id          : str
    rating              : int
    comment             : Optional[str]
    created_at: datetime


class MessageCreate(Base):
    """Schema for message creation."""
    content: str


class MessageResponse(Base):
    """Schema for message response."""
    id: str
    booking_id: str
    sender_id: str
    content: str
    sent_at: datetime
    is_read: bool
