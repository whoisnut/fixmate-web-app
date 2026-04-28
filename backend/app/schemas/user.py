from pydantic import BaseModel, EmailStr, Field
from typing import Optional, List
from datetime import datetime

class UserCreate(BaseModel):
    name: str
    email: EmailStr
    phone: Optional[str] = None
    password: str
    role: str = "customer"

class TechnicianRegister(BaseModel):
    name: str
    email: EmailStr
    phone: str
    password: str
    bio: str = ""
    specialties: List[str] = []
    documents: List[str] = []  # Array of base64 encoded documents or file URLs

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class RefreshTokenRequest(BaseModel):
    refresh_token: str

class TechnicianInfo(BaseModel):
    id: str
    user_id: str
    bio: str
    specialties: List[str]
    rating: float
    total_jobs: int
    is_verified: bool
    is_available: bool
    documents: List[dict]
    
    class Config:
        from_attributes = True

class UserResponse(BaseModel):
    id: str
    name: str
    email: str
    phone: Optional[str]
    role: str
    avatar_url: Optional[str]
    is_active: bool
    created_at: datetime
    technician: Optional[TechnicianInfo] = None

    class Config:
        from_attributes = True

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse
    expires_in: int = 86400  # 24 hours in seconds

class TechnicianLoginResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse
    technician_status: str  # pending, verified, rejected
    is_verified: bool
    can_accept_jobs: bool
    expires_in: int = 86400

class UserUpdate(BaseModel):
    name: Optional[str] = None
    phone: Optional[str] = None
    avatar_url: Optional[str] = None

class TechnicianVerificationStatus(BaseModel):
    user_id: str
    is_verified: bool
    status: str  # pending, verified, rejected
    rejection_reason: Optional[str] = None
    submitted_at: Optional[datetime] = None
    verified_at: Optional[datetime] = None
