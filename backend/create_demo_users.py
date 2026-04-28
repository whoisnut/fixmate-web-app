#!/usr/bin/env python3
import sys
from sqlalchemy.orm import Session
from app.core.database import SessionLocal
from app.models.user import User, Technician
from app.core.security import hash_password
from datetime import datetime

db = SessionLocal()

try:
    # Create demo customer user
    demo_user = User(
        name="Demo User",
        email="demo.login@fixmate.dev",
        phone="+1234567890",
        password=hash_password("Pass1234"),
        role="customer",
        is_active=True,
        created_at=datetime.utcnow()
    )
    db.add(demo_user)
    db.commit()
    print("✅ Demo customer created")
    
    # Create demo technician user
    demo_tech = User(
        name="Demo Technician",
        email="demo.tech@fixmate.dev",
        phone="+1987654321",
        password=hash_password("Pass1234"),
        role="technician",
        is_active=True,
        created_at=datetime.utcnow()
    )
    db.add(demo_tech)
    db.commit()
    db.refresh(demo_tech)
    print("✅ Demo technician created")
    
    # Create technician profile
    tech_profile = Technician(
        user_id=demo_tech.id,
        verification_status="approved",
        submitted_at=datetime.utcnow(),
        verified_at=datetime.utcnow()
    )
    db.add(tech_profile)
    db.commit()
    print("✅ Technician profile created")
    
    print("\n✅ All demo users created successfully!")
    
except Exception as e:
    print(f"❌ Error: {e}")
    db.rollback()
    
finally:
    db.close()
