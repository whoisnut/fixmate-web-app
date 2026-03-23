from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.user import User, Technician
from app.schemas.user import UserResponse, UserUpdate
from typing import Optional

router = APIRouter(prefix="/api/profile", tags=["Profile"])

@router.get("", response_model=UserResponse)
def get_profile(current_user: User = Depends(get_current_user)):
    """Get current user's profile"""
    return current_user

@router.put("", response_model=UserResponse)
def update_profile(
    update_data: UserUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Update current user's profile"""
    if update_data.name:
        current_user.name = update_data.name
    if update_data.phone:
        current_user.phone = update_data.phone
    if update_data.avatar_url:
        current_user.avatar_url = update_data.avatar_url
    
    db.commit()
    db.refresh(current_user)
    return current_user

@router.get("/technician/stats")
def get_technician_stats(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get technician statistics"""
    if current_user.role != "technician":
        raise HTTPException(status_code=403, detail="Only technicians can access this")
    
    technician = db.query(Technician).filter(Technician.user_id == current_user.id).first()
    if not technician:
        raise HTTPException(status_code=404, detail="Technician profile not found")
    
    return {
        "rating": technician.rating,
        "total_jobs": technician.total_jobs,
        "is_verified": technician.is_verified,
        "is_available": technician.is_available,
        "specialties": technician.specialties,
        "bio": technician.bio
    }

@router.put("/technician/availability")
def update_technician_availability(
    is_available: bool,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Update technician availability status"""
    if current_user.role != "technician":
        raise HTTPException(status_code=403, detail="Only technicians can access this")
    
    technician = db.query(Technician).filter(Technician.user_id == current_user.id).first()
    if not technician:
        raise HTTPException(status_code=404, detail="Technician profile not found")
    
    technician.is_available = is_available
    db.commit()
    db.refresh(technician)
    
    return {"is_available": technician.is_available}

@router.put("/technician/location")
def update_technician_location(
    lat: float,
    lng: float,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Update technician's current location"""
    if current_user.role != "technician":
        raise HTTPException(status_code=403, detail="Only technicians can access this")
    
    technician = db.query(Technician).filter(Technician.user_id == current_user.id).first()
    if not technician:
        raise HTTPException(status_code=404, detail="Technician profile not found")
    
    technician.current_lat = lat
    technician.current_lng = lng
    db.commit()
    db.refresh(technician)
    
    return {"current_lat": technician.current_lat, "current_lng": technician.current_lng}
