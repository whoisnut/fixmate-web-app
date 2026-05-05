from typing import Generic, Optional, TypeVar
from pydantic import BaseModel, Field
from ulid import ULID
from uuid import UUID

DataType = TypeVar("DataType")


def _get_trace_id() -> str:
    """Generate a ULID for trace_id."""
    return str(ULID())


class Base(BaseModel):
    """Base Pydantic model with common configuration."""
    class Config:
        from_attributes = True
        use_enum_values = True
        json_encoders = {
            UUID: lambda v: str(v)
        }


class IResponseBase(BaseModel, Generic[DataType]):
    """Standard response wrapper for all API endpoints."""
    trace_id: str = Field(default_factory=_get_trace_id)
    data: Optional[DataType] = None
    response_status: int
    response_code: int
    response_msg: str


class IPageResponse(BaseModel, Generic[DataType]):
    """Paginated response wrapper."""
    trace_id: str = Field(default_factory=_get_trace_id)
    data: Optional[DataType] = None
    response_status: int
    response_code: int
    response_msg: str
    total: int
    page: int
    page_size: int
    has_next: bool
    has_prev: bool
