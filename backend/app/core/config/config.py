from typing import List, Union
from pathlib import Path

from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=str(Path(__file__).parent.parent.parent.parent / '.env'),
        env_file_encoding='utf-8',
        extra='ignore'
    )

    PROJECT_NAME                       : str = 'FixMate API'
    API_V1_0_0_STR                     : str = '/api/v1.0.0'
    WHITE_LIST_CORS                    : Union[str, List[str]] = ['*']
    BACKEND_CORS_ORIGINS               : Union[str, List[str]] = ['*']

    ENV                                : str = 'development'
    ENV_LIST                           : List[str] = ['LOCAL', 'DEV', 'STAGING', 'UAT', 'PROD']
    PORT                               : int = 8000

    # Security
    SECRET_KEY                         : str
    ALGORITHM                          : str = 'HS256'
    ACCESS_TOKEN_EXPIRE_MINUTES        : int = 60
    REFRESH_TOKEN_EXPIRE_DAYS          : int = 30

    # Database
    DB_USER: str = ''
    DB_PASS: str = ''
    DB_HOST: str = ''
    DB_PORT: str = ''
    DB_NAME: str = ''
    DB_DIALECT: str = 'sqlite'
    DB_SSL: str = 'false'
    DATABASE_URL: str = 'sqlite:///./fixmate.db'

    # Redis
    REDIS_SERVER: str = 'localhost'
    REDIS_PORT: str = '6379'
    REDIS_PASSWORD: str = ''
    REDIS_URL: str = 'redis://localhost:6379/0'

    # Firebase
    FIREBASE_CREDENTIALS_PATH: str = './firebase-credentials.json'
    FIREBASE_STORAGE_BUCKET: str = 'fixmate-storage.appspot.com'

    # Stripe
    STRIPE_SECRET_KEY: str = ''
    STRIPE_WEBHOOK_SECRET: str = ''
    STRIPE_PUBLISHABLE_KEY: str = ''

    # Google Maps
    GOOGLE_MAPS_API_KEY: str = ''

    @field_validator('WHITE_LIST_CORS', 'BACKEND_CORS_ORIGINS', mode='before')
    @classmethod
    def parse_cors_list(cls, v: Union[str, List[str]]) -> List[str]:
        """Parse CORS list from string or list."""
        if isinstance(v, str):
            if v == '*':
                return ['*']
            return [origin.strip() for origin in v.split(',')]
        return v

    @field_validator('SECRET_KEY')
    @classmethod
    def validate_secret_key(cls, v: str) -> str:
        """Validate that secret key is at least 32 characters."""
        if not v or len(v) < 32:
            raise ValueError('SECRET_KEY must be at least 32 characters')
        return v

    @field_validator('PORT', mode='before')
    @classmethod
    def validate_positive_int(cls, v) -> int:
        """Validate that integer configuration values are positive."""
        if isinstance(v, str):
            v = int(v)
        if v <= 0:
            raise ValueError('Configuration value must be greater than 0')
        return v


settings = Settings()
