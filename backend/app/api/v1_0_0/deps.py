from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from sqlalchemy.orm import Session
from uuid import UUID

from app.core.config import settings
from app.core.system.db import getSession
from app.core.system.log import logger
from app.models.user_model import UserModel
from app.core.util.utils import Utils

oauth2_scheme = OAuth2PasswordBearer(tokenUrl=f"{settings.API_V1_0_0_STR}/auth/login")


async def get_current_user(
    token   : str      = Depends(oauth2_scheme)
    , session: Session = Depends(getSession)
) -> UserModel:
    """Get the current authenticated user from token."""
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(
            token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM]
        )
        user_id_str: str = payload.get("sub")
        if user_id_str is None:
            logger.error("Token payload missing 'sub'")
            raise credentials_exception
        user_id = UUID(user_id_str)
    except (JWTError, ValueError) as e:
        logger.error(f"Token validation error: {str(e)}")
        raise credentials_exception

    user = session.query(UserModel).filter(UserModel.id == user_id).first()
    if user is None:
        logger.error(f"User not found for ID: {user_id}")
        raise credentials_exception
    
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Inactive user"
        )
    
    return user
