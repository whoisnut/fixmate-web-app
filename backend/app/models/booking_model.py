from typing import List, Optional
from uuid import UUID, uuid4
from datetime import datetime

from sqlalchemy        import UUID as sqlalchemyUUID
from sqlalchemy        import Column
from sqlalchemy        import String
from sqlalchemy        import Boolean
from sqlalchemy        import Integer
from sqlalchemy        import Float
from sqlalchemy        import Text
from sqlalchemy        import ForeignKey
from sqlalchemy        import DateTime
from sqlalchemy.orm    import Mapped, mapped_column, relationship

from app.models.base_model import Base
from app.core.enum import BOOKING_STATUS_ENUM, PAYMENT_STATUS_ENUM


class BookingModel(Base):
    """Booking model."""
    __tablename__ = 'bookings'

    id              : Mapped[UUID]              = Column(sqlalchemyUUID, primary_key=True, default=uuid4)
    customer_id     : Mapped[UUID]              = Column(ForeignKey('users.id'), nullable=False)
    technician_id   : Mapped[Optional[UUID]]    = Column(ForeignKey('technicians.id'), nullable=True)
    service_id      : Mapped[UUID]              = Column(ForeignKey('services.id'), nullable=False)
    address         : Mapped[str]               = Column(String(255), nullable=False)
    lat             : Mapped[float]             = Column(Float, nullable=False)
    lng             : Mapped[float]             = Column(Float, nullable=False)
    scheduled_at    : Mapped[Optional[datetime]]= Column(DateTime, nullable=True)
    status          : Mapped[str]               = Column(String(20), default=BOOKING_STATUS_ENUM.PENDING.value)
    total_price     : Mapped[float]             = Column(Float, nullable=False)
    notes           : Mapped[Optional[str]]     = Column(Text, nullable=True)
    created_at      : Mapped[datetime]          = Column(DateTime, default=datetime.utcnow)
    updated_at      : Mapped[datetime]          = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class PaymentModel(Base):
    """Payment model."""
    __tablename__ = 'payments'

    id              : Mapped[UUID]              = Column(sqlalchemyUUID, primary_key=True, default=uuid4)
    booking_id      : Mapped[UUID]              = Column(ForeignKey('bookings.id'), nullable=False)
    amount          : Mapped[float]             = Column(Float, nullable=False)
    method          : Mapped[str]               = Column(String(50), nullable=False)
    status          : Mapped[str]               = Column(String(20), default=PAYMENT_STATUS_ENUM.PENDING.value)
    transaction_id  : Mapped[Optional[str]]     = Column(String(255), nullable=True)
    paid_at         : Mapped[Optional[datetime]]= Column(DateTime, nullable=True)
    created_at      : Mapped[datetime]          = Column(DateTime, default=datetime.utcnow)
    updated_at      : Mapped[datetime]          = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class PaymentMethodModel(Base):
    """Payment method model."""
    __tablename__ = 'payment_methods'

    id              : Mapped[UUID]              = Column(sqlalchemyUUID, primary_key=True, default=uuid4)
    user_id         : Mapped[UUID]              = Column(ForeignKey('users.id'), nullable=False)
    type: Mapped[str] = Column(String(50), nullable=False)
    cardholder_name: Mapped[Optional[str]] = Column(String(100), nullable=True)
    last_four_digits: Mapped[str] = Column(String(4), nullable=False)
    expiry_month: Mapped[str] = Column(String(2), nullable=False)
    expiry_year: Mapped[str] = Column(String(4), nullable=False)
    brand: Mapped[str] = Column(String(50), nullable=False)
    is_default: Mapped[bool] = Column(Boolean, default=False)
    stripe_payment_method_id: Mapped[Optional[str]] = Column(String(255), nullable=True)
    created_at: Mapped[datetime] = Column(DateTime, default=datetime.utcnow)
    updated_at: Mapped[datetime] = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class MessageModel(Base):
    """Message model for booking chat."""
    __tablename__ = 'messages'

    id: Mapped[UUID] = Column(sqlalchemyUUID, primary_key=True, default=uuid4)
    booking_id: Mapped[UUID] = Column(ForeignKey('bookings.id'), nullable=False)
    sender_id: Mapped[UUID] = Column(ForeignKey('users.id'), nullable=False)
    content: Mapped[str] = Column(Text, nullable=False)
    sent_at: Mapped[datetime] = Column(DateTime, default=datetime.utcnow)
    is_read: Mapped[bool] = Column(Boolean, default=False)


class ReviewModel(Base):
    """Review model."""
    __tablename__ = 'reviews'

    id: Mapped[UUID] = Column(sqlalchemyUUID, primary_key=True, default=uuid4)
    booking_id: Mapped[UUID] = Column(ForeignKey('bookings.id'), nullable=False)
    rating: Mapped[int] = Column(Integer, nullable=False)
    comment: Mapped[Optional[str]] = Column(Text, nullable=True)
    created_at: Mapped[datetime] = Column(DateTime, default=datetime.utcnow)
    updated_at: Mapped[datetime] = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
