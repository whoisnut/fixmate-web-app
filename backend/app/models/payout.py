import uuid
from sqlalchemy import Column, String, Float, DateTime, Boolean, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from datetime import datetime
from app.core.database import Base

class Payout(Base):
    __tablename__ = "payouts"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    amount = Column(Float, nullable=False)
    method = Column(String)  # "aba_pay", "wing", "bank_transfer"
    status = Column(String, default="pending")  # pending, approved, rejected, completed
    payment_account = Column(String)  # Account number or payment ID
    reason = Column(String, nullable=True)  # For rejection
    requested_at = Column(DateTime(timezone=True), server_default=func.now())
    processed_at = Column(DateTime(timezone=True), nullable=True)

    user = relationship("User", back_populates="payouts")

    class Config:
        from_attributes = True
