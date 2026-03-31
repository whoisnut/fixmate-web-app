from pydantic import BaseModel
from typing import Optional


class CategoryResponse(BaseModel):
    id: str
    name: str
    icon: Optional[str]
    color_hex: str
    is_active: bool

    class Config:
        from_attributes = True


class ServiceResponse(BaseModel):
    id: str
    category_id: str
    name: str
    description: Optional[str]
    min_price: float
    max_price: float
    urgency_level: int
    is_active: bool

    class Config:
        from_attributes = True


class CategoryCreate(BaseModel):
    name: str
    icon: Optional[str] = None
    color_hex: str = "#0EA5E9"


class CategoryUpdate(BaseModel):
    name: Optional[str] = None
    icon: Optional[str] = None
    color_hex: Optional[str] = None
    is_active: Optional[bool] = None


class ServiceCreate(BaseModel):
    category_id: str
    name: str
    description: Optional[str] = None
    min_price: float = 0
    max_price: float = 0
    urgency_level: int = 1
    is_active: bool = True


class ServiceUpdate(BaseModel):
    category_id: Optional[str] = None
    name: Optional[str] = None
    description: Optional[str] = None
    min_price: Optional[float] = None
    max_price: Optional[float] = None
    urgency_level: Optional[int] = None
    is_active: Optional[bool] = None
