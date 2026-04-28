from sqlalchemy import Column, String, Float, DateTime, ForeignKey, Text, Integer, Boolean
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.core.database import Base
import uuid

def gen_uuid(): return str(uuid.uuid4())

class Booking(Base):
    __tablename__ = "bookings"
    id = Column(String, primary_key=True, default=gen_uuid)
    customer_id = Column(String, ForeignKey("users.id"))
    technician_id = Column(String, ForeignKey("technicians.id"), nullable=True)
    service_id = Column(String, ForeignKey("services.id"))
    status = Column(String(20), default="pending")
    address = Column(Text)
    lat = Column(Float)
    lng = Column(Float)
    scheduled_at = Column(DateTime(timezone=True), nullable=True)
    total_price = Column(Float, default=0)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    customer = relationship("User", foreign_keys=[customer_id])
    technician = relationship("Technician", back_populates="bookings")
    service = relationship("Service")
    review = relationship("Review", back_populates="booking", uselist=False)
    payment = relationship("Payment", back_populates="booking", uselist=False)
    messages = relationship("Message", back_populates="booking")

class Review(Base):
    __tablename__ = "reviews"
    id = Column(String, primary_key=True, default=gen_uuid)
    booking_id = Column(String, ForeignKey("bookings.id"), unique=True)
    rating = Column(Integer)
    comment = Column(Text)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    booking = relationship("Booking", back_populates="review")

class Payment(Base):
    __tablename__ = "payments"
    id = Column(String, primary_key=True, default=gen_uuid)
    booking_id = Column(String, ForeignKey("bookings.id"), unique=True)
    amount = Column(Float)
    method = Column(String(50))
    status = Column(String(20), default="pending")
    transaction_id = Column(String, nullable=True)
    paid_at = Column(DateTime(timezone=True), nullable=True)
    booking = relationship("Booking", back_populates="payment")

class PaymentMethod(Base):
    __tablename__ = "payment_methods"
    id = Column(String, primary_key=True, default=gen_uuid)
    user_id = Column(String, ForeignKey("users.id"))
    type = Column(String(20), default="credit_card")  # credit_card, debit_card
    cardholder_name = Column(String(100))
    last_four_digits = Column(String(4))
    expiry_month = Column(String(2))
    expiry_year = Column(String(4))
    brand = Column(String(20))  # visa, mastercard, amex
    is_default = Column(Boolean, default=False)  # Use Boolean instead of String
    stripe_payment_method_id = Column(String, nullable=True)  # Stripe PM ID
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    user = relationship("User", back_populates="payment_methods")

class Message(Base):
    __tablename__ = "messages"
    id = Column(String, primary_key=True, default=gen_uuid)
    booking_id = Column(String, ForeignKey("bookings.id"))
    sender_id = Column(String, ForeignKey("users.id"))
    content = Column(Text)
    sent_at = Column(DateTime(timezone=True), server_default=func.now())
    booking = relationship("Booking", back_populates="messages")
