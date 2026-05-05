from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.system.db import getSession
from app.core.enum import RES_CUSTOM_CODE_ENUM, RESPONSE_STATUS_ENUM
from app.schemas.base_schema import IResponseBase
from app.schemas.app_credential_schema import AppAuthRequest, AppAuthResponse
from app.services.app_credential_service import AppCredentialService


router = APIRouter()


@router.post("/authenticate"
    , summary="Authenticate app"
    , description="Authenticate an app and return access token"
    , response_model=IResponseBase[AppAuthResponse]
)
async def authenticate_app(
    auth_request: AppAuthRequest
    , session   : Session = Depends(getSession)
):
    """Authenticate an app."""
    try:
        credential, access_token = await AppCredentialService.authenticate_app(
            session, auth_request
        )

        return {
            "data": AppAuthResponse(
                access_token=access_token,
                token_type='Bearer',
                expires_in=3600,
                app_name=credential.app_name,
                app_type=credential.app_type
            ),
            "response_status": RESPONSE_STATUS_ENUM.SUCCESS,
            "response_code": int(RES_CUSTOM_CODE_ENUM.TRANSACTION_SUCCESS),
            "response_msg": 'Authentication successful'
        }
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e)
        )


@router.get(
    "/credentials",
    summary="List all app credentials",
    description="List all app credentials (admin only)",
    response_model=IResponseBase[list]
)
async def list_app_credentials(
    session: Session = Depends(getSession)
):
    """List all app credentials."""
    credentials = await AppCredentialService.list_app_credentials(session)

    return {
        "data": [
            {
                "id": str(cred.id),
                "app_name": cred.app_name,
                "app_type": cred.app_type,
                "api_key_preview": cred.api_key[:8] + '...' + cred.api_key[-4:] if cred.api_key else '****',
                "is_active": cred.is_active,
                "last_used_at": cred.last_used_at.isoformat() if cred.last_used_at else None,
                "created_at": cred.created_at.isoformat()
            }
            for cred in credentials
        ],
        "response_status": RESPONSE_STATUS_ENUM.SUCCESS,
        "response_code": int(RES_CUSTOM_CODE_ENUM.TRANSACTION_SUCCESS),
        "response_msg": 'App credentials retrieved successfully'
    }
