from typing import Optional
from uuid import UUID, uuid4
from datetime import datetime

from sqlalchemy        import UUID as sqlalchemyUUID
from sqlalchemy        import Column
from sqlalchemy        import String
from sqlalchemy        import Float
from sqlalchemy        import Text
from sqlalchemy        import ForeignKey
from sqlalchemy        import DateTime
from sqlalchemy.orm    import Mapped, mapped_column, relationship

from app.models.base_model import Base
from app.core.enum import PAYOUT_STATUS_ENUM


class PayoutModel(Base):
    """Payout model for technician withdrawals."""
    __tablename__ = 'payouts'

    id              : Mapped[UUID]              = Column(sqlalchemyUUID, primary_key=True, default=uuid4)
    user_id         : Mapped[UUID]              = Column(ForeignKey('users.id'), nullable=False)
    amount          : Mapped[float]             = Column(Float, nullable=False)
    method          : Mapped[str]               = Column(String(50), nullable=False)
    status          : Mapped[str]               = Column(String(20), default=PAYOUT_STATUS_ENUM.PENDING.value)
    payment_account : Mapped[str]               = Column(String(255), nullable=False)
    reason          : Mapped[Optional[str]]     = Column(Text, nullable=True)
    requested_at    : Mapped[datetime]          = Column(DateTime, default=datetime.utcnow)
    processed_at    : Mapped[Optional[datetime]]= Column(DateTime, nullable=True)
    created_at      : Mapped[datetime]          = Column(DateTime, default=datetime.utcnow)
    updated_at      : Mapped[datetime]          = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
