from typing import Optional
from datetime import datetime
from pydantic import BaseModel, Field

from app.schemas.base_schema import Base


class CategoryCreate(Base):
    """Schema for category creation."""
    name                : str    = Field(..., min_length=1, max_length=100)
    icon                : Optional[str]  = None
    color_hex           : str    = '#000000'


class CategoryUpdate(Base):
    """Schema for category update."""
    name                : Optional[str]  = None
    icon                : Optional[str]  = None
    color_hex           : Optional[str]  = None
    is_active           : Optional[bool] = None


class CategoryResponse(Base):
    """Schema for category response."""
    id                  : str
    name                : str
    icon                : Optional[str]
    color_hex           : str
    is_active           : bool
    created_at          : datetime


class ServiceCreate(Base):
    """Schema for service creation."""
    category_id         : str
    name                : str    = Field(..., min_length=1, max_length=150)
    description         : Optional[str]  = None
    min_price           : float  = Field(..., ge=0)
    max_price           : float  = Field(..., ge=0)
    urgency_level       : int    = Field(default=1, ge=1, le=3)
    is_active           : bool   = True


class ServiceUpdate(Base):
    """Schema for service update."""
    name                : Optional[str]  = None
    description         : Optional[str]  = None
    min_price           : Optional[float] = None
    max_price           : Optional[float] = None
    urgency_level       : Optional[int]  = None
    is_active: Optional[bool] = None


class ServiceResponse(Base):
    """Schema for service response."""
    id: str
    category_id: str
    name: str
    description: Optional[str]
    min_price: float
    max_price: float
    urgency_level: int
    is_active: bool
    created_at: datetime


class ServiceWithCategoryResponse(Base):
    """Schema for service response with category."""
    id: str
    category_id: str
    name: str
    description: Optional[str]
    min_price: float
    max_price: float
    urgency_level: int
    is_active: bool
    category: CategoryResponse
