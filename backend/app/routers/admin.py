from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func
from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.user import User, Technician
from app.models.booking import Booking, Payment
from typing import List, Optional
from datetime import datetime, timedelta

router = APIRouter(prefix="/api/admin", tags=["Admin"])

def verify_admin(current_user: User = Depends(get_current_user)):
    """Verify user is admin"""
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Admin access required")
    return current_user

# ============ User Management ============

@router.get("/users")
def get_all_users(
    db: Session = Depends(get_db),
    current_user: User = Depends(verify_admin)
):
    """Get all users (admin only)"""
    users = db.query(User).all()
    return {
        "total": len(users),
        "active": len([u for u in users if u.is_active]),
        "users": users
    }

@router.post("/users/{user_id}/suspend")
def suspend_user(
    user_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(verify_admin)
):
    """Suspend a user account"""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    user.is_active = False
    db.commit()
    return {"message": f"User {user.email} suspended"}

@router.post("/users/{user_id}/unsuspend")
def unsuspend_user(
    user_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(verify_admin)
):
    """Unsuspend a user account"""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    user.is_active = True
    db.commit()
    return {"message": f"User {user.email} unsuspended"}

# ============ Technician Management ============

@router.get("/technicians")
def get_all_technicians(
    db: Session = Depends(get_db),
    current_user: User = Depends(verify_admin)
):
    """Get all technicians"""
    technicians = db.query(Technician).all()
    return {
        "total": len(technicians),
        "verified": len([t for t in technicians if t.is_verified]),
        "technicians": technicians
    }

@router.post("/technicians/{technician_id}/verify")
def verify_technician(
    technician_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(verify_admin)
):
    """Verify a technician account"""
    technician = db.query(Technician).filter(Technician.id == technician_id).first()
    if not technician:
        raise HTTPException(status_code=404, detail="Technician not found")
    
    technician.is_verified = True
    user = db.query(User).filter(User.id == technician.user_id).first()
    if user:
        user.is_active = True
    
    db.commit()
    return {"message": f"Technician {user.name if user else 'N/A'} verified"}

@router.post("/technicians/{technician_id}/suspend")
def suspend_technician(
    technician_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(verify_admin)
):
    """Suspend a technician"""
    technician = db.query(Technician).filter(Technician.id == technician_id).first()
    if not technician:
        raise HTTPException(status_code=404, detail="Technician not found")
    
    user = db.query(User).filter(User.id == technician.user_id).first()
    if user:
        user.is_active = False
    
    db.commit()
    return {"message": f"Technician {user.name if user else 'N/A'} suspended"}

@router.get("/technicians/low-rated")
def get_low_rated_technicians(
    min_rating: float = 2.5,
    db: Session = Depends(get_db),
    current_user: User = Depends(verify_admin)
):
    """Get technicians with low ratings"""
    technicians = db.query(Technician).filter(
        Technician.rating <= min_rating,
        Technician.is_verified == True
    ).all()
    
    return {
        "count": len(technicians),
        "min_rating": min_rating,
        "technicians": technicians
    }

@router.get("/technicians/{technician_id}/stats")
def get_technician_stats(
    technician_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(verify_admin)
):
    """Get detailed technician statistics"""
    technician = db.query(Technician).filter(Technician.id == technician_id).first()
    if not technician:
        raise HTTPException(status_code=404, detail="Technician not found")
    
    # Get booking stats
    bookings = db.query(Booking).filter(Booking.technician_id == technician_id).all()
    completed_bookings = [b for b in bookings if b.status == "completed"]
    
    # Get revenue
    completed_payments = db.query(Payment).join(
        Booking, Payment.booking_id == Booking.id
    ).filter(
        Booking.technician_id == technician_id,
        Payment.status == "completed"
    ).all()
    
    total_revenue = sum(p.amount for p in completed_payments)
    
    return {
        "technician_id": technician_id,
        "name": technician.user.name if technician.user else "N/A",
        "total_jobs": technician.total_jobs,
        "completed_jobs": len(completed_bookings),
        "rating": technician.rating,
        "verified": technician.is_verified,
        "total_revenue": total_revenue,
        "bookings": len(bookings)
    }

# ============ Analytics & Reports ============

@router.get("/analytics/overview")
def get_analytics_overview(
    days: int = 30,
    db: Session = Depends(get_db),
    current_user: User = Depends(verify_admin)
):
    """Get overall analytics"""
    cutoff_date = datetime.utcnow() - timedelta(days=days)
    
    # Bookings
    total_bookings = db.query(Booking).count()
    recent_bookings = db.query(Booking).filter(Booking.created_at >= cutoff_date).count()
    completed_bookings = db.query(Booking).filter(Booking.status == "completed").count()
    
    # Revenue
    completed_payments = db.query(Payment).filter(Payment.status == "completed").all()
    total_revenue = sum(p.amount for p in completed_payments)
    recent_revenue = sum(
        p.amount for p in completed_payments 
        if p.paid_at and p.paid_at >= cutoff_date
    )
    
    # Users
    total_users = db.query(User).filter(User.role == "customer").count()
    total_technicians = db.query(User).filter(User.role == "technician").count()
    verified_technicians = db.query(Technician).filter(Technician.is_verified == True).count()
    
    return {
        "period_days": days,
        "bookings": {
            "total": total_bookings,
            "recent": recent_bookings,
            "completed": completed_bookings
        },
        "revenue": {
            "total": total_revenue,
            "recent": recent_revenue
        },
        "users": {
            "customers": total_users,
            "technicians": total_technicians,
            "verified_technicians": verified_technicians
        }
    }

@router.get("/analytics/bookings")
def get_booking_analytics(
    days: int = 30,
    db: Session = Depends(get_db),
    current_user: User = Depends(verify_admin)
):
    """Get booking analytics"""
    cutoff_date = datetime.utcnow() - timedelta(days=days)
    
    bookings = db.query(Booking).filter(Booking.created_at >= cutoff_date).all()
    
    # Count by status
    status_counts = {}
    for booking in bookings:
        status = booking.status
        status_counts[status] = status_counts.get(status, 0) + 1
    
    # Average price
    avg_price = sum(b.total_price for b in bookings) / len(bookings) if bookings else 0
    
    return {
        "period_days": days,
        "total_bookings": len(bookings),
        "by_status": status_counts,
        "average_price": round(avg_price, 2)
    }

@router.get("/analytics/revenue")
def get_revenue_analytics(
    days: int = 30,
    db: Session = Depends(get_db),
    current_user: User = Depends(verify_admin)
):
    """Get revenue analytics"""
    cutoff_date = datetime.utcnow() - timedelta(days=days)
    
    payments = db.query(Payment).filter(
        Payment.created_at >= cutoff_date,
        Payment.status == "completed"
    ).all()
    
    total_revenue = sum(p.amount for p in payments)
    
    # By payment method
    method_revenue = {}
    for payment in payments:
        method = payment.method
        method_revenue[method] = method_revenue.get(method, 0) + payment.amount
    
    return {
        "period_days": days,
        "total_revenue": round(total_revenue, 2),
        "transaction_count": len(payments),
        "average_transaction": round(total_revenue / len(payments), 2) if payments else 0,
        "by_method": method_revenue
    }

@router.get("/top-technicians")
def get_top_technicians(
    limit: int = 10,
    db: Session = Depends(get_db),
    current_user: User = Depends(verify_admin)
):
    """Get top performing technicians"""
    technicians = db.query(Technician).order_by(
        Technician.rating.desc(),
        Technician.total_jobs.desc()
    ).limit(limit).all()
    
    return {
        "count": len(technicians),
        "technicians": technicians
    }
