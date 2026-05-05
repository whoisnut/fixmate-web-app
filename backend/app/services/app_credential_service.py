from typing import Optional
from datetime import datetime, timedelta
from sqlalchemy.orm import Session

from app.models.user_model import UserModel
from app.models.user_model import AppCredentialModel
from app.schemas.app_credential_schema import AppAuthRequest
from app.core.util.utils import Utils


class AppCredentialService:
    """Service for app credential operations."""

    @staticmethod
    async def authenticate_app(
        session       : Session
        , auth_request: AppAuthRequest
    ) -> tuple[AppCredentialModel, str]:
        """Authenticate an app and return access token."""
        # Find credential by app_name and api_key
        api_key_hash = Utils.hash_api_key(auth_request.api_key)
        credential = session.query(AppCredentialModel).filter(
            AppCredentialModel.app_name == auth_request.app_name,
            AppCredentialModel.api_key_hash == api_key_hash,
            AppCredentialModel.is_active == True
        ).first()

        if not credential:
            raise ValueError('Invalid app credentials')

        # Check expiration
        if credential.expires_at and credential.expires_at < datetime.utcnow():
            raise ValueError('App credentials have expired')

        # Update last used
        credential.last_used_at = datetime.utcnow()
        session.commit()

        # Generate access token
        from app.core.config import settings
        access_token = Utils.create_access_token({
            'sub': credential.app_name,
            'type': 'app',
            'app_type': credential.app_type
        })

        return credential, access_token

    @staticmethod
    async def get_app_credential_by_name(
        session   : Session
        , app_name: str
    ) -> Optional[AppCredentialModel]:
        """Get an app credential by name."""
        return session.query(AppCredentialModel).filter(
            AppCredentialModel.app_name == app_name
        ).first()

    @staticmethod
    async def list_app_credentials(
        session: Session
    ) -> list[AppCredentialModel]:
        """List all app credentials."""
        return session.query(AppCredentialModel).all()

    @staticmethod
    async def create_app_credential(
        session: Session,
        app_name: str,
        app_type: str,
        description: Optional[str] = None
    ) -> tuple[AppCredentialModel, str]:
        """Create a new app credential."""
        # Check if app_name already exists
        existing = session.query(AppCredentialModel).filter(
            AppCredentialModel.app_name == app_name
        ).first()
        if existing:
            raise ValueError(f'App credential for {app_name} already exists')

        # Generate API key
        api_key = Utils.generate_api_key()
        api_key_hash = Utils.hash_api_key(api_key)

        credential = AppCredentialModel(
            app_name=app_name,
            app_type=app_type,
            api_key=api_key,
            api_key_hash=api_key_hash,
            description=description
        )
        session.add(credential)
        session.commit()
        session.refresh(credential)

        return credential, api_key

    @staticmethod
    async def regenerate_api_key(
        session: Session,
        app_name: str
    ) -> tuple[AppCredentialModel, str]:
        """Regenerate API key for an app."""
        credential = await AppCredentialService.get_app_credential_by_name(
            session, app_name
        )
        if not credential:
            raise ValueError('App credential not found')

        # Generate new API key
        new_api_key = Utils.generate_api_key()
        credential.api_key = new_api_key
        credential.api_key_hash = Utils.hash_api_key(new_api_key)
        credential.updated_at = datetime.utcnow()

        session.commit()

        return credential, new_api_key

    @staticmethod
    async def toggle_app_credential(
        session: Session,
        app_name: str
    ) -> AppCredentialModel:
        """Toggle active status of an app credential."""
        credential = await AppCredentialService.get_app_credential_by_name(
            session, app_name
        )
        if not credential:
            raise ValueError('App credential not found')

        credential.is_active = not credential.is_active
        credential.updated_at = datetime.utcnow()

        session.commit()
        session.refresh(credential)

        return credential


__all__ = ["AppCredentialService"]
