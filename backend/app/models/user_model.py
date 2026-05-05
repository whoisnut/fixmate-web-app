from typing import List, Optional
from uuid import UUID, uuid4
from datetime import datetime

from sqlalchemy        import UUID as sqlalchemyUUID
from sqlalchemy        import Column
from sqlalchemy        import String
from sqlalchemy        import Boolean
from sqlalchemy        import DateTime
from sqlalchemy        import Text
from sqlalchemy        import Float
from sqlalchemy        import Integer
from sqlalchemy        import ForeignKey
from sqlalchemy        import JSON
from sqlalchemy.orm    import Mapped, mapped_column, relationship

from app.models.base_model import Base
from app.core.enum import USER_ROLE_ENUM

class UserModel(Base):
    """User model for customers, technicians, and admins."""
    __tablename__ = 'users'

    id              : Mapped[UUID]              = Column(sqlalchemyUUID, primary_key=True, default=uuid4)
    name            : Mapped[str]               = Column(String(100), nullable=False)
    email           : Mapped[str]               = Column(String(150), unique=True, nullable=False, index=True)
    phone           : Mapped[Optional[str]]     = Column(String(20), unique=True, nullable=True)
    password        : Mapped[str]               = Column(String, nullable=False)
    role            : Mapped[str]               = Column(String(20), default=USER_ROLE_ENUM.CUSTOMER.value)
    avatar_url      : Mapped[Optional[str]]     = Column(String, nullable=True)
    is_active       : Mapped[bool]              = Column(Boolean, default=True)
    fcm_token       : Mapped[Optional[str]]     = Column(String, nullable=True)
    created_at      : Mapped[datetime]          = Column(DateTime, default=datetime.utcnow)
    updated_at      : Mapped[datetime]          = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class TechnicianModel(Base):
    """Technician profile model."""
    __tablename__ = 'technicians'

    id                  : Mapped[UUID]              = Column(sqlalchemyUUID, primary_key=True, default=uuid4)
    user_id             : Mapped[UUID]              = Column(ForeignKey('users.id'), unique=True)
    bio                 : Mapped[Optional[str]]     = Column(Text, nullable=True)
    specialties         : Mapped[List]              = Column(JSON, default=list)
    rating              : Mapped[float]             = Column(Float, default=0.0)
    total_jobs          : Mapped[int]               = Column(Integer, default=0)
    is_verified         : Mapped[bool]              = Column(Boolean, default=False)
    is_available        : Mapped[bool]              = Column(Boolean, default=False)
    current_lat         : Mapped[Optional[float]]   = Column(Float, nullable=True)
    current_lng         : Mapped[Optional[float]]   = Column(Float, nullable=True)
    documents           : Mapped[List]              = Column(JSON, default=list)
    verification_status : Mapped[str]               = Column(String(20), default='pending')
    rejection_reason    : Mapped[Optional[str]]     = Column(Text, nullable=True)
    submitted_at        : Mapped[Optional[datetime]]= Column(DateTime, nullable=True)
    verified_at         : Mapped[Optional[datetime]]= Column(DateTime, nullable=True)
    verified_by         : Mapped[Optional[str]]     = Column(String, nullable=True)
    created_at          : Mapped[datetime]          = Column(DateTime, default=datetime.utcnow)
    updated_at          : Mapped[datetime]          = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    user                : Mapped['UserModel']       = relationship('UserModel', foreign_keys=[user_id])


class TokenBlacklistModel(Base):
    """Token blacklist model for logout functionality."""
    __tablename__ = 'token_blacklist'

    id          : Mapped[UUID]      = Column(sqlalchemyUUID, primary_key=True, default=uuid4)
    user_id     : Mapped[UUID]      = Column(ForeignKey('users.id'), nullable=False)
    token       : Mapped[str]       = Column(String, nullable=False, index=True)
    expires_at  : Mapped[datetime]  = Column(DateTime, nullable=False)
    created_at  : Mapped[datetime]  = Column(DateTime, default=datetime.utcnow)


class AuthSessionModel(Base):
    """Auth session model for tracking active sessions."""
    __tablename__ = 'auth_sessions'

    id              : Mapped[UUID]              = Column(sqlalchemyUUID, primary_key=True, default=uuid4)
    user_id         : Mapped[UUID]              = Column(ForeignKey('users.id'), nullable=False, index=True)
    token_hash      : Mapped[str]               = Column(String(255), nullable=False, unique=True, index=True)
    device_type     : Mapped[str]               = Column(String(50), nullable=False)
    device_name     : Mapped[Optional[str]]     = Column(String(100), nullable=True)
    device_id       : Mapped[Optional[str]]     = Column(String(100), nullable=True)
    ip_address      : Mapped[Optional[str]]     = Column(String(45), nullable=True)
    user_agent      : Mapped[Optional[str]]     = Column(Text, nullable=True)
    location        : Mapped[Optional[str]]     = Column(String(100), nullable=True)
    is_active       : Mapped[bool]              = Column(Boolean, default=True, nullable=False, index=True)
    last_activity   : Mapped[datetime]          = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    expires_at      : Mapped[datetime]          = Column(DateTime, nullable=False, index=True)
    created_at      : Mapped[datetime]          = Column(DateTime, default=datetime.utcnow)


class ApiCredentialModel(Base):
    """API credential model for user API keys."""
    __tablename__ = 'api_credentials'

    id                      : Mapped[UUID]              = Column(sqlalchemyUUID, primary_key=True, default=uuid4)
    name                    : Mapped[str]               = Column(String(100), nullable=False)
    description             : Mapped[Optional[str]]     = Column(Text, nullable=True)
    auth_type               : Mapped[str]               = Column(String(50), nullable=False, default='bearer', index=True)
    user_id                 : Mapped[Optional[UUID]]    = Column(ForeignKey('users.id'), nullable=True, index=True)
    app_type                : Mapped[str]               = Column(String(50), nullable=False)
    app_version             : Mapped[Optional[str]]     = Column(String(50), nullable=True)
    api_key                 : Mapped[Optional[str]]     = Column(String(255), nullable=True, unique=True)
    api_key_hash            : Mapped[Optional[str]]     = Column(String(255), nullable=True, unique=True, index=True)
    oauth_client_id         : Mapped[Optional[str]]     = Column(String(255), nullable=True, unique=True)
    oauth_client_secret_hash: Mapped[Optional[str]]     = Column(String(255), nullable=True)
    oauth_redirect_uris     : Mapped[Optional[str]]     = Column(Text, nullable=True)
    oauth_scopes: Mapped[Optional[str]] = Column(Text, nullable=True)
    rate_limit_per_minute: Mapped[int] = Column(Integer, default=60)
    rate_limit_per_hour: Mapped[int] = Column(Integer, default=1000)
    is_active: Mapped[bool] = Column(Boolean, default=True, nullable=False, index=True)
    is_revoked: Mapped[bool] = Column(Boolean, default=False, nullable=False)
    last_used_at: Mapped[Optional[datetime]] = Column(DateTime, nullable=True)
    expires_at: Mapped[Optional[datetime]] = Column(DateTime, nullable=True, index=True)
    created_at: Mapped[datetime] = Column(DateTime, default=datetime.utcnow)
    updated_at: Mapped[datetime] = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    revoked_at: Mapped[Optional[datetime]] = Column(DateTime, nullable=True)
    ip_whitelist: Mapped[Optional[str]] = Column(Text, nullable=True)
    extra_data: Mapped[Optional[str]] = Column(Text, nullable=True)


class AppCredentialModel(Base):
    """App credential model for admin and mobile apps."""
    __tablename__ = 'app_credentials'

    id: Mapped[UUID] = Column(sqlalchemyUUID, primary_key=True, default=uuid4)
    app_name: Mapped[str] = Column(String(50), nullable=False, unique=True)
    app_type: Mapped[str] = Column(String(20), nullable=False)
    api_key: Mapped[str] = Column(String(255), nullable=False, unique=True, index=True)
    api_key_hash: Mapped[str] = Column(String(255), nullable=False, unique=True, index=True)
    oauth_client_id: Mapped[Optional[str]] = Column(String(255), nullable=True, unique=True)
    oauth_client_secret: Mapped[Optional[str]] = Column(String(255), nullable=True)
    basic_username: Mapped[Optional[str]] = Column(String(100), nullable=True)
    basic_password: Mapped[Optional[str]] = Column(String(255), nullable=True)
    is_active: Mapped[bool] = Column(Boolean, default=True, nullable=False)
    last_used_at: Mapped[Optional[datetime]] = Column(DateTime, nullable=True)
    expires_at: Mapped[Optional[datetime]] = Column(DateTime, nullable=True)
    created_at: Mapped[datetime] = Column(DateTime, default=datetime.utcnow)
    updated_at: Mapped[datetime] = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    description: Mapped[Optional[str]] = Column(Text, nullable=True)
