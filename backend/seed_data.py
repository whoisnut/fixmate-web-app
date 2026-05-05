"""
Seed script to create default data for FixMate backend.
Run this after database initialization.
"""

from app.core.system.db import engine, SessionLocal

# Import all models to register them with Base.metadata
from app.models import (
    UserModel,
    TechnicianModel,
    CategoryModel,
    ServiceModel,
    AppCredentialModel
)

# Create all tables
Base = UserModel.metadata
Base.create_all(bind=engine)

# Now import other modules
from app.core.enum import USER_ROLE_ENUM, VERIFICATION_STATUS_ENUM
from app.core.util.utils import Utils
from datetime import datetime


def seed_admin_user():
    """Create a default admin account if none exists."""
    db = SessionLocal()
    try:
        exists = db.query(UserModel).filter(
            UserModel.role == USER_ROLE_ENUM.ADMIN.value
        ).first()
        if exists:
            print("Admin user already exists. Skipping seed.")
            return

        admin_user = UserModel(
            name="Admin",
            email="admin@fixmate.dev",
            phone="+0000000000",
            password=Utils.hash_password("Admin1234"),
            role=USER_ROLE_ENUM.ADMIN.value,
            is_active=True
        )
        db.add(admin_user)
        db.commit()
        print("Admin user created successfully.")
        print("Email: admin@fixmate.dev")
        print("Password: Admin1234")
    finally:
        db.close()


def seed_demo_services():
    """Create demo services for Car and Motorbike categories."""
    db = SessionLocal()
    try:
        allowed_categories = {
            "Car": {"icon": "directions_car", "color_hex": "#1D4ED8"},
            "Motorbike": {"icon": "two_wheeler", "color_hex": "#0EA5E9"},
        }

        categories_by_name = {cat.name: cat for cat in db.query(CategoryModel).all()}

        # Deactivate categories outside the allowed list
        for category in categories_by_name.values():
            if category.name not in allowed_categories:
                category.is_active = False

        # Ensure allowed categories exist and are active
        for category_name, metadata in allowed_categories.items():
            category = categories_by_name.get(category_name)
            if category is None:
                category = CategoryModel(
                    name=category_name,
                    icon=metadata["icon"],
                    color_hex=metadata["color_hex"],
                    is_active=True
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
                for service in db.query(ServiceModel).filter(
                    ServiceModel.category_id == category.id
                ).all()
            }

            for service_data in services:
                existing = existing_services.get(service_data["name"])
                if existing is None:
                    db.add(ServiceModel(
                        category_id=category.id,
                        is_active=True,
                        **service_data
                    ))
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

        # Deactivate services under non-allowed categories and stale services
        for service in db.query(ServiceModel).all():
            category = categories_by_name.get(
                service.category.name
            ) if service.category else None
            if (
                category is None
                or category.name not in allowed_categories
                or service.name not in allowed_service_names
            ):
                service.is_active = False

        db.commit()
        print("Demo services seeded successfully.")
    finally:
        db.close()


def seed_app_credentials():
    """Create default app credentials for admin and mobile apps."""
    db = SessionLocal()
    try:
        # Check if credentials already exist
        existing_admin = db.query(AppCredentialModel).filter(
            AppCredentialModel.app_name == "admin"
        ).first()
        existing_mobile = db.query(AppCredentialModel).filter(
            AppCredentialModel.app_name == "mobile"
        ).first()

        if existing_admin and existing_mobile:
            print("App credentials already exist. Skipping seed.")
            return

        # Create admin app credential
        if not existing_admin:
            admin_api_key = Utils.generate_api_key()
            admin_credential = AppCredentialModel(
                app_name="admin",
                app_type="admin",
                api_key=admin_api_key,
                api_key_hash=Utils.hash_api_key(admin_api_key),
                description="Admin web panel credentials"
            )
            db.add(admin_credential)
            print(f"Created admin credential: {admin_api_key}")

        # Create mobile app credential
        if not existing_mobile:
            mobile_api_key = Utils.generate_api_key()
            mobile_credential = AppCredentialModel(
                app_name="mobile",
                app_type="mobile",
                api_key=mobile_api_key,
                api_key_hash=Utils.hash_api_key(mobile_api_key),
                description="Mobile app credentials"
            )
            db.add(mobile_credential)
            print(f"Created mobile credential: {mobile_api_key}")

        db.commit()
        print("App credentials seeded successfully.")
    finally:
        db.close()


if __name__ == "__main__":
    # Seed data
    seed_admin_user()
    seed_demo_services()
    seed_app_credentials()

    print("\n=== Seed Complete ===")
    print("Default Admin Credentials:")
    print("  Email: admin@fixmate.dev")
    print("  Password: Admin1234")
