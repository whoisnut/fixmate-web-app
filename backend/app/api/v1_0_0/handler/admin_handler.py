from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session

from app.core.system.db import getSession
from app.core.enum import RES_CUSTOM_CODE_ENUM, RESPONSE_STATUS_ENUM
from app.schemas.base_schema import IResponseBase
from app.models.user_model import UserModel, TechnicianModel
from app.schemas.user_schema import UserResponse

router = APIRouter()


@router.get("/users"
    , summary="Get all users"
    , description="Get all users (admin only)"
    , response_model=IResponseBase[dict]
)
async def get_users(
    role    : Optional[str] = None
    , session: Session = Depends(getSession)
):
    """Get all users."""
    query = session.query(UserModel)
    if role:
        query = query.filter(UserModel.role == role)
    
    users = query.all()

    return {
        "data": {
            "users": [
                UserResponse(
                    id=str(user.id),
                    name=user.name,
                    email=user.email,
                    phone=user.phone,
                    role=user.role,
                    avatar_url=user.avatar_url,
                    is_active=user.is_active,
                    created_at=user.created_at
                )
                for user in users
            ]
        },
        "response_status": RESPONSE_STATUS_ENUM.SUCCESS,
        "response_code": int(RES_CUSTOM_CODE_ENUM.TRANSACTION_SUCCESS),
        "response_msg": 'Users retrieved successfully'
    }


@router.get(
    "/technicians",
    summary="Get all technicians",
    description="Get all technicians with verification status",
    response_model=IResponseBase[dict]
)
async def get_technicians(
    status: Optional[str] = None,
    session: Session = Depends(getSession)
):
    """Get all technicians."""
    query = session.query(TechnicianModel).join(UserModel)
    if status:
        query = query.filter(TechnicianModel.verification_status == status)
    
    technicians = query.all()

    return {
        "data": {
            "technicians": [
                {
                    "id": str(tech.id),
                    "user_id": str(tech.user_id),
                    "name": tech.user.name,
                    "email": tech.user.email,
                    "specialties": tech.specialties,
                    "verification_status": tech.verification_status,
                    "is_verified": tech.is_verified,
                    "rating": tech.rating,
                    "total_jobs": tech.total_jobs,
                    "created_at": tech.created_at.isoformat()
                }
                for tech in technicians
            ]
        },
        "response_status": RESPONSE_STATUS_ENUM.SUCCESS,
        "response_code": int(RES_CUSTOM_CODE_ENUM.TRANSACTION_SUCCESS),
        "response_msg": 'Technicians retrieved successfully'
    }
