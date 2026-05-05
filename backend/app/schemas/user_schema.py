from typing import Optional
from datetime import datetime
from pydantic import BaseModel, EmailStr, Field

from app.schemas.base_schema import Base


class UserCreate(Base):
    """Schema for user registration."""
    name                : str             = Field(..., min_length=1, max_length=100)
    email               : EmailStr
    phone               : Optional[str]   = None
    password            : str             = Field(..., min_length=8)
    role                : str             = 'customer'


class UserLogin(Base):
    """Schema for user login."""
    email               : EmailStr
    password            : str


class UserResponse(Base):
    """Schema for user response."""
    id                  : str
    name                : str
    email               : str
    phone               : Optional[str]
    role                : str
    avatar_url          : Optional[str]
    is_active           : bool
    created_at          : datetime


class TechnicianRegister(Base):
    """Schema for technician registration."""
    name                : str             = Field(..., min_length=1, max_length=100)
    email               : EmailStr
    phone               : str
    password            : str             = Field(..., min_length=8)
    bio                 : Optional[str]   = None
    specialties         : list[str]       = []
    documents           : list[str]       = []


class TechnicianResponse(Base):
    """Schema for technician response."""
    id                  : str
    user_id             : str
    bio                 : Optional[str]
    specialties         : list[str]
    rating              : float
    total_jobs          : int
    is_verified         : bool
    is_available        : bool
    verification_status : str
    rejection_reason    : Optional[str]
    submitted_at        : Optional[datetime]
    verified_at         : Optional[datetime]


class TokenResponse(Base):
    """Schema for token response."""
    access_token        : str
    user                : UserResponse
    expires_in          : int


class RefreshTokenRequest(Base):
    """Schema for refresh token request."""
    refresh_token: str


class TechnicianLoginResponse(Base):
    """Schema for technician login response."""
    access_token: str
    user: UserResponse
    technician_status: str
    is_verified: bool
    can_accept_jobs: bool
    expires_in: int


class TechnicianVerificationStatus(Base):
    """Schema for technician verification status."""
    user_id: str
    is_verified: bool
    status: str
    rejection_reason: Optional[str]
    submitted_at: Optional[datetime]
    verified_at: Optional[datetime]
