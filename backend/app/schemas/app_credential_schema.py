from typing import Optional
from datetime import datetime
from pydantic import BaseModel, Field

from app.schemas.base_schema import Base


class AppCredentialResponse(Base):
    """Schema for app credential response."""
    id                      : str
    app_name                : str
    app_type                : str
    api_key_preview         : str
    oauth_client_id         : Optional[str]
    basic_username          : Optional[str]
    is_active               : bool
    last_used_at            : Optional[datetime]
    expires_at              : Optional[datetime]
    created_at              : datetime
    updated_at              : datetime
    description             : Optional[str]


class AppCredentialCreateResponse(Base):
    """Schema for app credential creation response."""
    credential              : AppCredentialResponse
    api_key                 : str
    oauth_client_secret     : Optional[str]
    basic_password          : Optional[str]
    warning                 : str


class AppAuthRequest(Base):
    """Schema for app authentication request."""
    app_name                : str
    api_key                 : str


class AppAuthResponse(Base):
    """Schema for app authentication response."""
    access_token            : str
    token_type              : str
    expires_in              : int
    app_name                : str
    app_type                : str
