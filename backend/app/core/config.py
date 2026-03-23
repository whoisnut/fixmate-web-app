from pydantic_settings import BaseSettings
from pathlib import Path
from pydantic import model_validator

BASE_DIR = Path(__file__).resolve().parents[2]

class Settings(BaseSettings):
    APP_NAME: str = "FixMate"
    APP_ENV: str = "development"
    SECRET_KEY: str
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30
    DATABASE_URL: str
    REDIS_URL: str
    FIREBASE_CREDENTIALS_PATH: str
    FIREBASE_STORAGE_BUCKET: str
    STRIPE_SECRET_KEY: str
    STRIPE_WEBHOOK_SECRET: str
    GOOGLE_MAPS_API_KEY: str
    ALLOWED_ORIGINS: str = "http://localhost:8000,http://localhost:3000,http://localhost:3001,http://10.0.2.2:8000,http://127.0.0.1:8000"
    ALLOWED_ORIGIN_REGEX: str = r"https?://(localhost|127\.0\.0\.1)(:\d+)?$"

    @model_validator(mode="after")
    def normalize_paths(self):
        if self.DATABASE_URL.startswith("sqlite:///./"):
            db_name = self.DATABASE_URL.replace("sqlite:///./", "", 1)
            self.DATABASE_URL = f"sqlite:///{(BASE_DIR / db_name).resolve()}"
        return self

    class Config:
        env_file = str(BASE_DIR / ".env")

settings = Settings()
