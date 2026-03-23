from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.models.service import Category, Service
from app.schemas.service import CategoryResponse, ServiceResponse
from typing import List

router = APIRouter(prefix="/api", tags=["Services"])

@router.get("/categories", response_model=List[CategoryResponse])
def get_categories(db: Session = Depends(get_db)):
    return db.query(Category).filter(Category.is_active == True).all()

@router.get("/services", response_model=List[ServiceResponse])
def get_services(category_id: str = None, db: Session = Depends(get_db)):
    query = db.query(Service).filter(Service.is_active == True)
    if category_id:
        query = query.filter(Service.category_id == category_id)
    return query.all()

@router.get("/services/{service_id}", response_model=ServiceResponse)
def get_service(service_id: str, db: Session = Depends(get_db)):
    return db.query(Service).filter(Service.id == service_id).first()
