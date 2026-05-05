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


class CategoryModel(Base):
    """Service category model."""
    __tablename__ = 'categories'

    id              : Mapped[UUID]              = Column(sqlalchemyUUID, primary_key=True, default=uuid4)
    name            : Mapped[str]               = Column(String(100), nullable=False)
    icon            : Mapped[Optional[str]]     = Column(String(100), nullable=True)
    color_hex       : Mapped[str]               = Column(String(7), default='#000000')
    is_active       : Mapped[bool]              = Column(Boolean, default=True)
    created_at      : Mapped[datetime]          = Column(DateTime, default=datetime.utcnow)
    updated_at      : Mapped[datetime]          = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    services        : Mapped[List['ServiceModel']] = relationship('ServiceModel', back_populates='category')


class ServiceModel(Base):
    """Service model."""
    __tablename__ = 'services'

    id              : Mapped[UUID]              = Column(sqlalchemyUUID, primary_key=True, default=uuid4)
    category_id     : Mapped[UUID]              = Column(ForeignKey('categories.id'))
    name            : Mapped[str]               = Column(String(150), nullable=False)
    description     : Mapped[Optional[str]]     = Column(Text, nullable=True)
    min_price       : Mapped[float]             = Column(Float, default=0)
    max_price       : Mapped[float]             = Column(Float, default=0)
    urgency_level   : Mapped[int]               = Column(Integer, default=1)
    is_active       : Mapped[bool]              = Column(Boolean, default=True)
    created_at      : Mapped[datetime]          = Column(DateTime, default=datetime.utcnow)
    updated_at      : Mapped[datetime]          = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    category        : Mapped['CategoryModel']   = relationship('CategoryModel', back_populates='services')
