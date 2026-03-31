from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.core.database import Base, SessionLocal, engine
from app.models import user, service, booking  # noqa: F401 – registers all models
from app.models.service import Category, Service
from app.routers import auth, services, bookings, profile, payments, payment_methods

# Create all tables on startup (safe to call multiple times)
Base.metadata.create_all(bind=engine)


def seed_demo_services() -> None:
    """Ensure only Car and Motorbike categories/services are active."""
    db = SessionLocal()
    try:
        allowed_categories = {
            "Car": {"icon": "directions_car", "color_hex": "#1D4ED8"},
            "Motorbike": {"icon": "two_wheeler", "color_hex": "#0EA5E9"},
        }

        categories_by_name = {cat.name: cat for cat in db.query(Category).all()}

        # Deactivate categories outside the allowed list.
        for category in categories_by_name.values():
            if category.name not in allowed_categories:
                category.is_active = False

        # Ensure allowed categories exist and are active.
        for category_name, metadata in allowed_categories.items():
            category = categories_by_name.get(category_name)
            if category is None:
                category = Category(
                    name=category_name,
                    icon=metadata["icon"],
                    color_hex=metadata["color_hex"],
                    is_active=True,
                )
                db.add(category)
                categories_by_name[category_name] = category
            else:
                category.icon = metadata["icon"]
                category.color_hex = metadata["color_hex"]
                category.is_active = True

        db.flush()

        services_seed = {
            "Car": [
                {
                    "name": "Fix Flat Tire",
                    "description": "Patch punctures or replace flat tires.",
                    "min_price": 25,
                    "max_price": 70,
                    "urgency_level": 3,
                },
                {
                    "name": "Battery Jump Start",
                    "description": "On-site jump start for dead car batteries.",
                    "min_price": 20,
                    "max_price": 50,
                    "urgency_level": 3,
                },
                {
                    "name": "Brake Pad Replacement",
                    "description": "Inspect and replace worn brake pads.",
                    "min_price": 70,
                    "max_price": 180,
                    "urgency_level": 2,
                },
                {
                    "name": "Engine Oil Change",
                    "description": "Replace engine oil and oil filter.",
                    "min_price": 35,
                    "max_price": 120,
                    "urgency_level": 1,
                },
                {
                    "name": "Radiator Coolant Refill",
                    "description": "Top up or replace coolant and inspect leaks.",
                    "min_price": 30,
                    "max_price": 95,
                    "urgency_level": 2,
                },
                {
                    "name": "Starter Motor Check",
                    "description": "Diagnose starter and ignition crank issues.",
                    "min_price": 45,
                    "max_price": 130,
                    "urgency_level": 3,
                },
            ],
            "Motorbike": [
                {
                    "name": "Motorbike Flat Tire Repair",
                    "description": "Tube/tubeless puncture repair for motorbikes.",
                    "min_price": 15,
                    "max_price": 45,
                    "urgency_level": 3,
                },
                {
                    "name": "Chain Adjustment & Lubrication",
                    "description": "Adjust chain tension and apply lubrication.",
                    "min_price": 10,
                    "max_price": 30,
                    "urgency_level": 1,
                },
                {
                    "name": "Motorbike Brake Repair",
                    "description": "Brake pad replacement and brake system check.",
                    "min_price": 25,
                    "max_price": 80,
                    "urgency_level": 2,
                },
                {
                    "name": "Spark Plug Replacement",
                    "description": "Replace worn spark plugs to improve ignition.",
                    "min_price": 12,
                    "max_price": 35,
                    "urgency_level": 2,
                },
                {
                    "name": "Motorbike Oil Change",
                    "description": "Drain and refill engine oil for motorbikes.",
                    "min_price": 18,
                    "max_price": 50,
                    "urgency_level": 1,
                },
                {
                    "name": "Headlight/Electrical Check",
                    "description": "Fix common light and wiring issues.",
                    "min_price": 15,
                    "max_price": 55,
                    "urgency_level": 3,
                },
            ],
        }

        for category_name, services in services_seed.items():
            category = categories_by_name[category_name]
            existing_services = {
                service.name: service
                for service in db.query(Service).filter(Service.category_id == category.id).all()
            }

            for service_data in services:
                existing = existing_services.get(service_data["name"])
                if existing is None:
                    db.add(Service(category_id=category.id, is_active=True, **service_data))
                else:
                    existing.description = service_data["description"]
                    existing.min_price = service_data["min_price"]
                    existing.max_price = service_data["max_price"]
                    existing.urgency_level = service_data["urgency_level"]
                    existing.is_active = True

        allowed_service_names = {
            service_data["name"]
            for services in services_seed.values()
            for service_data in services
        }

        # Deactivate services under non-allowed categories and stale services not in the seed.
        for service in db.query(Service).all():
            category = categories_by_name.get(service.category.name) if service.category else None
            if (
                category is None
                or category.name not in allowed_categories
                or service.name not in allowed_service_names
            ):
                service.is_active = False

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
app.include_router(payment_methods.router)

@app.get("/")
def root():
    return {"message": "FixMate API 🚀", "version": "1.0.0"}

@app.get("/health")
def health():
    return {"status": "healthy"}
