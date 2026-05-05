from typing import Optional
from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.system.db import getSession
from app.core.enum import RES_CUSTOM_CODE_ENUM, RESPONSE_STATUS_ENUM
from app.schemas.base_schema import IResponseBase
from app.schemas.user_schema import (UserCreate
                                    , UserLogin
                                    , UserResponse
                                    , TechnicianRegister
                                    , TechnicianResponse
                                    , TokenResponse
                                    , RefreshTokenRequest
                                    , TechnicianLoginResponse
                                    , TechnicianVerificationStatus)
from app.services.auth_service import AuthService


router = APIRouter()


@router.post("/register"
    , summary="Register a new user"
    , description="Register a new customer or technician account"
    , response_model=IResponseBase[TokenResponse]
)
async def register(
    user_data   : UserCreate
    , session   : Session = Depends(getSession)
):
    """Register a new user."""
    try:
        user, access_token = await AuthService.register_user(session, user_data)

        return {
            "data": TokenResponse(
                access_token=access_token,
                user=UserResponse(
                    id=str(user.id),
                    name=user.name,
                    email=user.email,
                    phone=user.phone,
                    role=user.role,
                    avatar_url=user.avatar_url,
                    is_active=user.is_active,
                    created_at=user.created_at
                ),
                expires_in=3600
            ),
            "response_status": RESPONSE_STATUS_ENUM.SUCCESS,
            "response_code": int(RES_CUSTOM_CODE_ENUM.TRANSACTION_SUCCESS),
            "response_msg": "Registration successful"
        }
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )


@router.post(
    "/register/technician",
    summary="Register a new technician",
    description="Register a new technician with documents for verification",
    response_model=IResponseBase[TechnicianLoginResponse]
)
async def register_technician(
    tech_data: TechnicianRegister,
    session: Session = Depends(getSession)
):
    """Register a new technician."""
    try:
        user, technician, access_token = await AuthService.register_technician(
            session, tech_data
        )

        return {
            "data": TechnicianLoginResponse(
                access_token=access_token,
                user=UserResponse(
                    id=str(user.id),
                    name=user.name,
                    email=user.email,
                    phone=user.phone,
                    role=user.role,
                    avatar_url=user.avatar_url,
                    is_active=user.is_active,
                    created_at=user.created_at
                ),
                technician_status=technician.verification_status,
                is_verified=technician.is_verified,
                can_accept_jobs=technician.is_verified and technician.is_available,
                expires_in=3600
            ),
            "response_status": RESPONSE_STATUS_ENUM.SUCCESS,
            "response_code": int(RES_CUSTOM_CODE_ENUM.TRANSACTION_SUCCESS),
            "response_msg": "Technician registration successful"
        }
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )


@router.post(
    "/login",
    summary="User login",
    description="Login with email and password",
    response_model=IResponseBase[TokenResponse]
)
async def login(
    credentials: UserLogin,
    session: Session = Depends(getSession)
):
    """Login a user."""
    try:
        user, access_token = await AuthService.login_user(
            session, credentials.email, credentials.password
        )

        return {
            "data": TokenResponse(
                access_token=access_token,
                user=UserResponse(
                    id=str(user.id),
                    name=user.name,
                    email=user.email,
                    phone=user.phone,
                    role=user.role,
                    avatar_url=user.avatar_url,
                    is_active=user.is_active,
                    created_at=user.created_at
                ),
                expires_in=3600
            ),
            "response_status": RESPONSE_STATUS_ENUM.SUCCESS,
            "response_code": int(RES_CUSTOM_CODE_ENUM.TRANSACTION_SUCCESS),
            "response_msg": "Login successful"
        }
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e)
        )


@router.post(
    "/login/technician",
    summary="Technician login",
    description="Login as a technician with verification status",
    response_model=IResponseBase[TechnicianLoginResponse]
)
async def login_technician(
    credentials: UserLogin,
    session: Session = Depends(getSession)
):
    """Login a technician."""
    try:
        user, technician, access_token = await AuthService.login_technician(
            session, credentials.email, credentials.password
        )

        return {
            "data": TechnicianLoginResponse(
                access_token=access_token,
                user=UserResponse(
                    id=str(user.id),
                    name=user.name,
                    email=user.email,
                    phone=user.phone,
                    role=user.role,
                    avatar_url=user.avatar_url,
                    is_active=user.is_active,
                    created_at=user.created_at
                ),
                technician_status=technician.verification_status,
                is_verified=technician.is_verified,
                can_accept_jobs=technician.is_verified and technician.is_available,
                expires_in=3600
            ),
            "response_status": RESPONSE_STATUS_ENUM.SUCCESS,
            "response_code": int(RES_CUSTOM_CODE_ENUM.TRANSACTION_SUCCESS),
            "response_msg": "Login successful"
        }
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e)
        )


@router.post(
    "/refresh",
    summary="Refresh access token",
    description="Refresh access token using refresh token",
    response_model=IResponseBase[TokenResponse]
)
async def refresh_token(
    request: RefreshTokenRequest,
    session: Session = Depends(getSession)
):
    """Refresh access token."""
    try:
        user, new_access_token = await AuthService.refresh_token(
            session, request.refresh_token
        )

        return {
            "data": TokenResponse(
                access_token=new_access_token,
                user=UserResponse(
                    id=str(user.id),
                    name=user.name,
                    email=user.email,
                    phone=user.phone,
                    role=user.role,
                    avatar_url=user.avatar_url,
                    is_active=user.is_active,
                    created_at=user.created_at
                ),
                expires_in=3600
            ),
            "response_status": RESPONSE_STATUS_ENUM.SUCCESS,
            "response_code": int(RES_CUSTOM_CODE_ENUM.TRANSACTION_SUCCESS),
            "response_msg": "Token refreshed successfully"
        }
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e)
        )


@router.post(
    "/logout",
    summary="Logout user",
    description="Logout user and blacklist their current token",
    response_model=IResponseBase[dict]
)
async def logout(
    user_id: str,
    token: str,
    session: Session = Depends(getSession)
):
    """Logout a user."""
    try:
        await AuthService.logout_user(session, user_id, token)

        return {
            "data": {'message': 'Successfully logged out'},
            "response_status": RESPONSE_STATUS_ENUM.SUCCESS,
            "response_code": int(RES_CUSTOM_CODE_ENUM.TRANSACTION_SUCCESS),
            "response_msg": 'Logout successful'
        }
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e)
        )


@router.get(
    "/technician/verification-status",
    summary="Get technician verification status",
    description="Get technician verification status",
    response_model=IResponseBase[TechnicianVerificationStatus]
)
async def get_technician_verification_status(
    user_id: str,
    session: Session = Depends(getSession)
):
    """Get technician verification status."""
    try:
        user_uuid = UUID(user_id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail='Invalid user ID format'
        )
    
    technician = await AuthService.get_technician_by_user_id(session, user_uuid)
    if not technician:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail='Technician profile not found'
        )

    return {
        "data": TechnicianVerificationStatus(
            user_id=user_id,
            is_verified=technician.is_verified,
            status=technician.verification_status,
            rejection_reason=technician.rejection_reason,
            submitted_at=technician.submitted_at,
            verified_at=technician.verified_at
        ),
        "response_status": RESPONSE_STATUS_ENUM.SUCCESS,
        "response_code": int(RES_CUSTOM_CODE_ENUM.TRANSACTION_SUCCESS),
        "response_msg": 'Verification status retrieved'
    }
