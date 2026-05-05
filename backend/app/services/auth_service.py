from typing import Optional, Tuple
from datetime import datetime
from uuid import UUID
from sqlalchemy.orm import Session

from app.models.user_model import UserModel, TechnicianModel, TokenBlacklistModel
from app.schemas.user_schema import UserCreate, UserResponse, TechnicianRegister
from app.core.enum import USER_ROLE_ENUM, VERIFICATION_STATUS_ENUM
from app.core.util.utils import Utils


class AuthService:
    """Service for authentication operations."""

    @staticmethod
    async def register_user(
        session       : Session
        , user_data   : UserCreate
    ) -> tuple[UserModel, str]:
        """Register a new user."""
        # Check if email exists
        existing_user = session.query(UserModel).filter(
            UserModel.email == Utils.normalize_email(user_data.email)
        ).first()
        if existing_user:
            raise ValueError('Email already registered')

        # Check if phone exists
        if user_data.phone:
            existing_phone = session.query(UserModel).filter(
                UserModel.phone == Utils.normalize_phone(user_data.phone)
            ).first()
            if existing_phone:
                raise ValueError('Phone number already registered')

        # Create user
        user = UserModel(
            name       = user_data.name
            , email    = Utils.normalize_email(user_data.email)
            , phone    = Utils.normalize_phone(user_data.phone)
            , password = Utils.hash_password(user_data.password)
            , role     = user_data.role
        )
        session.add(user)
        session.flush()

        # Create technician profile if role is technician
        if user.role == USER_ROLE_ENUM.TECHNICIAN.value:
            tech = TechnicianModel(
                user_id             = user.id
                , verification_status = VERIFICATION_STATUS_ENUM.PENDING.value
                , submitted_at      = datetime.utcnow()
            )
            session.add(tech)

        session.commit()
        session.refresh(user)

        # Generate access token
        access_token = Utils.create_access_token({
            'sub': str(user.id),
            'role': user.role
        })

        return user, access_token

    @staticmethod
    async def register_technician(
        session       : Session
        , tech_data   : TechnicianRegister
    ) -> tuple[UserModel, TechnicianModel, str]:
        """Register a new technician."""
        # Check if email exists
        existing_user = session.query(UserModel).filter(
            UserModel.email == Utils.normalize_email(tech_data.email)
        ).first()
        if existing_user:
            raise ValueError('Email already registered')

        # Check if phone exists
        existing_phone = session.query(UserModel).filter(
            UserModel.phone == Utils.normalize_phone(tech_data.phone)
        ).first()
        if existing_phone:
            raise ValueError('Phone number already registered')

        # Create user
        user = UserModel(
            name       = tech_data.name
            , email    = Utils.normalize_email(tech_data.email)
            , phone    = Utils.normalize_phone(tech_data.phone)
            , password = Utils.hash_password(tech_data.password)
            , role     = USER_ROLE_ENUM.TECHNICIAN.value
        )
        session.add(user)
        session.flush()

        # Create technician profile
        technician = TechnicianModel(
            user_id             = user.id
            , bio               = tech_data.bio
            , specialties       = tech_data.specialties
            , documents         = [{'url': doc, 'type': 'document'} for doc in tech_data.documents]
            , verification_status = VERIFICATION_STATUS_ENUM.PENDING.value
            , submitted_at      = datetime.utcnow()
        )
        session.add(technician)

        session.commit()
        session.refresh(user)
        session.refresh(technician)

        # Generate access token
        access_token = Utils.create_access_token({
            'sub': str(user.id),
            'role': user.role
        })

        return user, technician, access_token

    @staticmethod
    async def login_user(
        session   : Session
        , email   : str
        , password: str
    ) -> tuple[UserModel, str]:
        """Login a user."""
        user = session.query(UserModel).filter(
            UserModel.email == Utils.normalize_email(email)
        ).first()

        if not user or not Utils.verify_password(password, user.password):
            raise ValueError('Invalid credentials')

        if not user.is_active:
            raise ValueError('Account has been suspended')

        # Generate access token
        access_token = Utils.create_access_token({
            'sub': str(user.id),
            'role': user.role
        })

        return user, access_token

    @staticmethod
    async def login_technician(
        session   : Session
        , email   : str
        , password: str
    ) -> tuple[UserModel, TechnicianModel, str]:
        """Login a technician."""
        user = session.query(UserModel).filter(
            UserModel.email == Utils.normalize_email(email),
            UserModel.role == USER_ROLE_ENUM.TECHNICIAN.value
        ).first()

        if not user or not Utils.verify_password(password, user.password):
            raise ValueError('Invalid credentials')

        if not user.is_active:
            raise ValueError('Account has been suspended')

        # Get technician profile
        tech = session.query(TechnicianModel).filter(
            TechnicianModel.user_id == user.id
        ).first()
        if not tech:
            raise ValueError('Technician profile not found')

        # Generate access token
        access_token = Utils.create_access_token({
            'sub': str(user.id),
            'role': user.role
        })

        return user, tech, access_token

    @staticmethod
    async def logout_user(
        session: Session,
        user_id: str,
        token: str
    ) -> None:
        """Logout a user by blacklisting their token."""
        # Decode token to get expiration
        payload = Utils.decode_token(token)
        if not payload:
            raise ValueError('Invalid token')

        exp_timestamp = payload.get('exp')
        expires_at = datetime.utcfromtimestamp(exp_timestamp)

        # Add token to blacklist
        blacklisted_token = TokenBlacklistModel(
            user_id=user_id,
            token=token,
            expires_at=expires_at
        )
        session.add(blacklisted_token)
        session.commit()

    @staticmethod
    async def refresh_token(
        session: Session,
        refresh_token: str
    ) -> tuple[UserModel, str]:
        """Refresh an access token using refresh token."""
        payload = Utils.decode_token(refresh_token)
        if not payload:
            raise ValueError('Invalid refresh token')

        user_id_str = payload.get('sub')
        if not user_id_str:
            raise ValueError('Invalid token payload')
        
        user_id = UUID(user_id_str)
        user = session.query(UserModel).filter(UserModel.id == user_id).first()
        if not user:
            raise ValueError('User not found')

        # Check if token is blacklisted
        is_blacklisted = session.query(TokenBlacklistModel).filter(
            TokenBlacklistModel.token == refresh_token,
            TokenBlacklistModel.user_id == user_id
        ).first()
        if is_blacklisted:
            raise ValueError('Token has been revoked')

        # Generate new access token
        new_access_token = Utils.create_access_token({
            'sub': str(user.id),
            'role': user.role
        })

        return user, new_access_token

    @staticmethod
    async def get_user_by_id(
        session: Session,
        user_id: UUID
    ) -> Optional[UserModel]:
        """Get a user by ID."""
        return session.query(UserModel).filter(UserModel.id == user_id).first()

    @staticmethod
    async def get_technician_by_user_id(
        session: Session,
        user_id: UUID
    ) -> Optional[TechnicianModel]:
        """Get a technician by user ID."""
        return session.query(TechnicianModel).filter(
            TechnicianModel.user_id == user_id
        ).first()


__all__ = ["AuthService"]
