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
