import hashlib
import secrets
from datetime import datetime, timedelta
from typing import Optional
from jose import JWTError, jwt

from app.core.config import settings


class Utils:
    """Utility class for common operations."""

    @staticmethod
    def hash_password(password: str) -> str:
        """Hash a password using SHA-256 (for demo - use bcrypt in production)."""
        return hashlib.sha256(password.encode()).hexdigest()

    @staticmethod
    def verify_password(plain: str, hashed: str) -> bool:
        """Verify a password against its hash."""
        return hashlib.sha256(plain.encode()).hexdigest() == hashed

    @staticmethod
    def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
        """Create a JWT access token."""
        to_encode = data.copy()
        expire = datetime.utcnow() + (expires_delta or timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES))
        to_encode.update({"exp": expire})
        return jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)

    @staticmethod
    def decode_token(token: str) -> Optional[dict]:
        """Decode and validate a JWT token."""
        try:
            return jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        except JWTError:
            return None

    @staticmethod
    def generate_api_key() -> str:
        """Generate a secure random API key."""
        return f"fm_{secrets.token_urlsafe(32)}"

    @staticmethod
    def hash_api_key(api_key: str) -> str:
        """Hash an API key for storage."""
        return hashlib.sha256(api_key.encode()).hexdigest()

    @staticmethod
    def mask_api_key(api_key: str) -> str:
        """Mask an API key for display (show first 8 and last 4 chars)."""
        if len(api_key) < 12:
            return "****"
        return f"{api_key[:8]}...{api_key[-4:]}"

    @staticmethod
    def generate_uuid() -> str:
        """Generate a UUID string."""
        import uuid
        return str(uuid.uuid4())

    @staticmethod
    def normalize_email(email: str) -> str:
        """Normalize email address."""
        return email.strip().lower()

    @staticmethod
    def normalize_phone(phone: Optional[str]) -> Optional[str]:
        """Normalize phone number."""
        return phone.strip() if phone else None

    @staticmethod
    def haversine_distance_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
        """Calculate distance between two points in kilometers using Haversine formula."""
        import math
        R = 6371.0
        phi1, phi2 = math.radians(lat1), math.radians(lat2)
        dphi = math.radians(lat2 - lat1)
        dlambda = math.radians(lon2 - lon1)
        a = math.sin(dphi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2) ** 2
        return 2 * R * math.asin(math.sqrt(a))


__all__ = ["Utils"]
