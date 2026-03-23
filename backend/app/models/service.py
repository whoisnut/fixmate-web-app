from sqlalchemy import Column, String, Float, Boolean, Integer, ForeignKey, Text
from sqlalchemy.orm import relationship
from app.core.database import Base
import uuid

def gen_uuid(): return str(uuid.uuid4())

class Category(Base):
    __tablename__ = "categories"
    id = Column(String, primary_key=True, default=gen_uuid)
    name = Column(String(100), nullable=False)
    icon = Column(String(100))
    color_hex = Column(String(7), default="#000000")
    is_active = Column(Boolean, default=True)
    services = relationship("Service", back_populates="category")

class Service(Base):
    __tablename__ = "services"
    id = Column(String, primary_key=True, default=gen_uuid)
    category_id = Column(String, ForeignKey("categories.id"))
    name = Column(String(150), nullable=False)
    description = Column(Text)
    min_price = Column(Float, default=0)
    max_price = Column(Float, default=0)
    urgency_level = Column(Integer, default=1)
    is_active = Column(Boolean, default=True)
    category = relationship("Category", back_populates="services")
