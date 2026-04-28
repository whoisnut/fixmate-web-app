from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func
from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.user import User
from app.models.service import Category, Service
from app.schemas.service import (
    CategoryCreate,
    CategoryResponse,
    CategoryUpdate,
    ServiceCreate,
    ServiceResponse,
    ServiceUpdate,
)
from typing import List

router = APIRouter(prefix="/api", tags=["Services"])
ALLOWED_CATEGORY_NAMES = ("Car", "Motorbike")

@router.get("/categories", response_model=List[CategoryResponse])
def get_categories(db: Session = Depends(get_db)):
    return (
        db.query(Category)
        .filter(Category.is_active == True)
        .filter(Category.name.in_(ALLOWED_CATEGORY_NAMES))
        .all()
    )

@router.get("/services", response_model=List[ServiceResponse])
def get_services(category_id: str = None, db: Session = Depends(get_db)):
    query = (
        db.query(Service)
        .join(Category, Service.category_id == Category.id)
        .filter(Service.is_active == True)
        .filter(Category.is_active == True)
        .filter(Category.name.in_(ALLOWED_CATEGORY_NAMES))
    )
    if category_id:
        query = query.filter(Service.category_id == category_id)
    return query.all()

@router.get("/services/{service_id}", response_model=ServiceResponse)
def get_service(service_id: str, db: Session = Depends(get_db)):
    return db.query(Service).filter(Service.id == service_id).first()


@router.post("/categories", response_model=CategoryResponse, status_code=status.HTTP_201_CREATED)
def create_category(
    category_data: CategoryCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    # Verify admin role
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Only admins can create categories")
    
    existing = (
        db.query(Category)
        .filter(func.lower(Category.name) == category_data.name.strip().lower())
        .first()
    )
    if existing:
        raise HTTPException(status_code=409, detail="Category already exists")

    category = Category(
        name=category_data.name.strip(),
        icon=category_data.icon,
        color_hex=category_data.color_hex,
        is_active=True,
    )
    db.add(category)
    db.commit()
    db.refresh(category)
    return category


@router.put("/categories/{category_id}", response_model=CategoryResponse)
def update_category(
    category_id: str,
    category_data: CategoryUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    # Verify admin role
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Only admins can update categories")
    
    category = db.query(Category).filter(Category.id == category_id).first()
    if not category:
        raise HTTPException(status_code=404, detail="Category not found")

    payload = category_data.model_dump(exclude_unset=True)
    if "name" in payload and payload["name"]:
        payload["name"] = payload["name"].strip()

    for key, value in payload.items():
        setattr(category, key, value)

    db.commit()
    db.refresh(category)
    return category


@router.delete("/categories/{category_id}")
def delete_category(
    category_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    # Verify admin role
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Only admins can delete categories")
    
    category = db.query(Category).filter(Category.id == category_id).first()
    if not category:
        raise HTTPException(status_code=404, detail="Category not found")

    category.is_active = False
    db.query(Service).filter(Service.category_id == category_id).update({"is_active": False})
    db.commit()
    return {"message": "Category deactivated"}


@router.post("/services", response_model=ServiceResponse, status_code=status.HTTP_201_CREATED)
def create_service(
    service_data: ServiceCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    # Verify admin role
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Only admins can create services")
    
    category = db.query(Category).filter(Category.id == service_data.category_id).first()
    if not category:
        raise HTTPException(status_code=404, detail="Category not found")

    service = Service(**service_data.model_dump())
    db.add(service)
    db.commit()
    db.refresh(service)
    return service


@router.put("/services/{service_id}", response_model=ServiceResponse)
def update_service(
    service_id: str,
    service_data: ServiceUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    # Verify admin role
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Only admins can update services")
    
    service = db.query(Service).filter(Service.id == service_id).first()
    if not service:
        raise HTTPException(status_code=404, detail="Service not found")

    payload = service_data.model_dump(exclude_unset=True)
    if "category_id" in payload:
        category = db.query(Category).filter(Category.id == payload["category_id"]).first()
        if not category:
            raise HTTPException(status_code=404, detail="Category not found")

    for key, value in payload.items():
        setattr(service, key, value)

    db.commit()
    db.refresh(service)
    return service


@router.delete("/services/{service_id}")
def delete_service(
    service_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    # Verify admin role
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Only admins can delete services")
    
    service = db.query(Service).filter(Service.id == service_id).first()
    if not service:
        raise HTTPException(status_code=404, detail="Service not found")

    service.is_active = False
    db.commit()
    return {"message": "Service deactivated"}
