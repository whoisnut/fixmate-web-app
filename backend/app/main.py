from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.core.database import Base, engine
from app.models import user, service, booking  # noqa: F401 – registers all models
from app.routers import auth, services, bookings

# Create all tables on startup (safe to call multiple times)
Base.metadata.create_all(bind=engine)

app = FastAPI(title="FixMate API", description="On-demand technician booking", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS.split(","),
    allow_origin_regex=settings.ALLOWED_ORIGIN_REGEX,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(services.router)
app.include_router(bookings.router)

@app.get("/")
def root():
    return {"message": "FixMate API 🚀", "version": "1.0.0"}

@app.get("/health")
def health():
    return {"status": "healthy"}
