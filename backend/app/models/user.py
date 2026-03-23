from sqlalchemy import Column, String, DateTime, Boolean, Float, Integer, ForeignKey, Text, JSON
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.core.database import Base
import uuid

def gen_uuid(): return str(uuid.uuid4())

class User(Base):
    __tablename__ = "users"
    id = Column(String, primary_key=True, default=gen_uuid)
    name = Column(String(100), nullable=False)
    email = Column(String(150), unique=True, index=True, nullable=False)
    phone = Column(String(20), unique=True, nullable=True)
    password = Column(String, nullable=False)
    role = Column(String(20), default="customer")
    avatar_url = Column(String, nullable=True)
    is_active = Column(Boolean, default=True)
    fcm_token = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    technician = relationship("Technician", back_populates="user", uselist=False)

class Technician(Base):
    __tablename__ = "technicians"
    id = Column(String, primary_key=True, default=gen_uuid)
    user_id = Column(String, ForeignKey("users.id"), unique=True)
    bio = Column(Text, nullable=True)
    specialties = Column(JSON, default=[])
    rating = Column(Float, default=0.0)
    total_jobs = Column(Integer, default=0)
    is_verified = Column(Boolean, default=False)
    is_available = Column(Boolean, default=False)
    current_lat = Column(Float, nullable=True)
    current_lng = Column(Float, nullable=True)
    documents = Column(JSON, default=[])
    user = relationship("User", back_populates="technician")
    bookings = relationship("Booking", back_populates="technician")
