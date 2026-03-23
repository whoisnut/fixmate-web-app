from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.core.database import Base, SessionLocal, engine
from app.models import user, service, booking  # noqa: F401 – registers all models
from app.models.service import Category, Service
from app.routers import auth, services, bookings, profile, payments

# Create all tables on startup (safe to call multiple times)
Base.metadata.create_all(bind=engine)


def seed_demo_services() -> None:
    """Populate starter categories/services so new DBs are not empty."""
    db = SessionLocal()
    try:
        has_categories = db.query(Category).first() is not None
        if has_categories:
            return

        plumbing = Category(name="Plumbing", icon="plumbing", color_hex="#2563EB")
        electrical = Category(name="Electrical", icon="bolt", color_hex="#F59E0B")
        appliance = Category(name="Appliance Repair", icon="build", color_hex="#10B981")
        cleaning = Category(name="Home Cleaning", icon="cleaning_services", color_hex="#8B5CF6")

        db.add_all([plumbing, electrical, appliance, cleaning])
        db.flush()

        db.add_all(
            [
                Service(
                    category_id=plumbing.id,
                    name="Leak Repair",
                    description="Fix leaking pipes, faucets, and joints.",
                    min_price=30,
                    max_price=120,
                    urgency_level=2,
                ),
                Service(
                    category_id=plumbing.id,
                    name="Drain Unclogging",
                    description="Clear blocked sink, shower, and floor drains.",
                    min_price=25,
                    max_price=90,
                    urgency_level=2,
                ),
                Service(
                    category_id=electrical.id,
                    name="Outlet & Switch Repair",
                    description="Repair or replace faulty sockets and switches.",
                    min_price=35,
                    max_price=140,
                    urgency_level=3,
                ),
                Service(
                    category_id=electrical.id,
                    name="Lighting Installation",
                    description="Install ceiling lights, LEDs, and fixtures.",
                    min_price=40,
                    max_price=180,
                    urgency_level=2,
                ),
                Service(
                    category_id=appliance.id,
                    name="Washing Machine Repair",
                    description="Diagnose and repair common washer issues.",
                    min_price=50,
                    max_price=220,
                    urgency_level=2,
                ),
                Service(
                    category_id=cleaning.id,
                    name="Deep Home Cleaning",
                    description="Comprehensive cleaning for rooms and surfaces.",
                    min_price=45,
                    max_price=160,
                    urgency_level=1,
                ),
            ]
        )
        db.commit()
    finally:
        db.close()


seed_demo_services()

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
app.include_router(profile.router)
app.include_router(payments.router)

@app.get("/")
def root():
    return {"message": "FixMate API 🚀", "version": "1.0.0"}

@app.get("/health")
def health():
    return {"status": "healthy"}
