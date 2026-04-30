from fastapi import APIRouter, Depends, HTTPException, status, Body
from sqlalchemy.orm import Session, joinedload
from sqlalchemy import func
from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.user import User, Technician
from app.models.booking import Booking, Payment, Review
from typing import List, Optional
from datetime import datetime, timedelta

router = APIRouter(prefix="/api/admin", tags=["Admin"])

def verify_admin(current_user: User = Depends(get_current_user)):
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Admin access required")
    return current_user

# ============ User Management ============

@router.get("/users")
def get_all_users(
    db: Session = Depends(get_db),
    current_user: User = Depends(verify_admin)
):
    users = db.query(User).all()
    result = [
        {
            "id": u.id,
            "name": u.name,
            "email": u.email,
            "phone": u.phone,
            "role": u.role,
            "is_active": u.is_active,
            "created_at": u.created_at.isoformat() if u.created_at else None,
        }
        for u in users
    ]
    return {
        "total": len(result),
        "active": len([u for u in result if u["is_active"]]),
        "users": result,
    }

@router.post("/users/{user_id}/suspend")
def suspend_user(
    user_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(verify_admin)
):
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
    technicians = db.query(Technician).options(joinedload(Technician.user)).all()
    result = [
        {
            "id": tech.id,
            "user_id": tech.user_id,
            "name": tech.user.name if tech.user else "N/A",
            "email": tech.user.email if tech.user else "N/A",
            "phone": tech.user.phone if tech.user else None,
            "is_active": tech.user.is_active if tech.user else False,
            "bio": tech.bio,
            "specialties": tech.specialties or [],
            "documents": tech.documents or [],
            "rating": tech.rating,
            "total_jobs": tech.total_jobs,
            "is_verified": tech.is_verified,
            "is_available": tech.is_available,
            "verification_status": tech.verification_status,
            "rejection_reason": tech.rejection_reason,
            "submitted_at": tech.submitted_at.isoformat() if tech.submitted_at else None,
            "verified_at": tech.verified_at.isoformat() if tech.verified_at else None,
        }
        for tech in technicians
    ]
    return {
        "total": len(result),
        "verified": len([r for r in result if r["is_verified"]]),
        "pending": len([r for r in result if r["verification_status"] == "pending"]),
        "technicians": result,
    }

@router.post("/technicians/{technician_id}/verify")
def verify_technician(
    technician_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(verify_admin)
):
    technician = db.query(Technician).filter(Technician.id == technician_id).first()
    if not technician:
        raise HTTPException(status_code=404, detail="Technician not found")
    technician.is_verified = True
    technician.verification_status = "verified"
    technician.verified_at = datetime.utcnow()
    technician.verified_by = current_user.id
    user = db.query(User).filter(User.id == technician.user_id).first()
    if user:
        user.is_active = True
    db.commit()
    return {"message": f"Technician {user.name if user else 'N/A'} verified"}

@router.post("/technicians/{technician_id}/reject")
def reject_technician(
    technician_id: str,
    body: dict = Body(default={}),
    db: Session = Depends(get_db),
    current_user: User = Depends(verify_admin)
):
    technician = db.query(Technician).filter(Technician.id == technician_id).first()
    if not technician:
        raise HTTPException(status_code=404, detail="Technician not found")
    technician.verification_status = "rejected"
    technician.is_verified = False
    technician.rejection_reason = body.get("reason", "")
    user = db.query(User).filter(User.id == technician.user_id).first()
    if user:
        user.is_active = False
    db.commit()
    return {"message": f"Technician {user.name if user else 'N/A'} rejected"}

@router.post("/technicians/{technician_id}/suspend")
def suspend_technician(
    technician_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(verify_admin)
):
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
    min_rating: float = 3.0,
    db: Session = Depends(get_db),
    current_user: User = Depends(verify_admin)
):
    technicians = db.query(Technician).options(joinedload(Technician.user)).filter(
        Technician.rating <= min_rating,
        Technician.total_jobs > 0,
    ).all()
    result = [
        {
            "id": tech.id,
            "name": tech.user.name if tech.user else "N/A",
            "email": tech.user.email if tech.user else "N/A",
            "rating": tech.rating,
            "total_jobs": tech.total_jobs,
            "is_verified": tech.is_verified,
        }
        for tech in technicians
    ]
    return {"count": len(result), "min_rating": min_rating, "technicians": result}

@router.get("/technicians/{technician_id}/stats")
def get_technician_stats(
    technician_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(verify_admin)
):
    technician = db.query(Technician).options(joinedload(Technician.user)).filter(
        Technician.id == technician_id
    ).first()
    if not technician:
        raise HTTPException(status_code=404, detail="Technician not found")
    bookings = db.query(Booking).filter(Booking.technician_id == technician_id).all()
    completed = [b for b in bookings if b.status == "completed"]
    payments = db.query(Payment).join(Booking, Payment.booking_id == Booking.id).filter(
        Booking.technician_id == technician_id, Payment.status == "completed"
    ).all()
    return {
        "technician_id": technician_id,
        "name": technician.user.name if technician.user else "N/A",
        "total_jobs": technician.total_jobs,
        "completed_jobs": len(completed),
        "rating": technician.rating,
        "verified": technician.is_verified,
        "total_revenue": sum(p.amount for p in payments),
        "bookings": len(bookings),
    }

# ============ Reviews Moderation ============

@router.get("/reviews")
def get_all_reviews(
    db: Session = Depends(get_db),
    current_user: User = Depends(verify_admin)
):
    reviews = db.query(Review).options(
        joinedload(Review.booking)
    ).all()
    result = [
        {
            "id": r.id,
            "booking_id": r.booking_id,
            "rating": r.rating,
            "comment": r.comment,
            "created_at": r.created_at.isoformat() if r.created_at else None,
            "customer_id": r.booking.customer_id if r.booking else None,
            "technician_id": r.booking.technician_id if r.booking else None,
        }
        for r in reviews
    ]
    return {"total": len(result), "reviews": result}

@router.delete("/reviews/{review_id}")
def delete_review(
    review_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(verify_admin)
):
    review = db.query(Review).filter(Review.id == review_id).first()
    if not review:
        raise HTTPException(status_code=404, detail="Review not found")
    db.delete(review)
    db.commit()
    return {"message": "Review removed"}

# ============ Analytics & Reports ============

@router.get("/analytics/overview")
def get_analytics_overview(
    days: int = 30,
    db: Session = Depends(get_db),
    current_user: User = Depends(verify_admin)
):
    cutoff = datetime.utcnow() - timedelta(days=days)
    total_bookings = db.query(Booking).count()
    recent_bookings = db.query(Booking).filter(Booking.created_at >= cutoff).count()
    completed_bookings = db.query(Booking).filter(Booking.status == "completed").count()
    pending_bookings = db.query(Booking).filter(Booking.status == "pending").count()
    cancelled_bookings = db.query(Booking).filter(Booking.status == "cancelled").count()
    in_progress_bookings = db.query(Booking).filter(Booking.status == "in_progress").count()
    all_payments = db.query(Payment).filter(Payment.status == "completed").all()
    total_revenue = sum(p.amount for p in all_payments)
    recent_revenue = sum(
        p.amount for p in all_payments if p.paid_at and p.paid_at >= cutoff
    )
    total_customers = db.query(User).filter(User.role == "customer").count()
    total_technicians = db.query(User).filter(User.role == "technician").count()
    verified_technicians = db.query(Technician).filter(Technician.is_verified == True).count()

    top_technicians_raw = db.query(Technician).options(joinedload(Technician.user)).order_by(
        Technician.rating.desc(), Technician.total_jobs.desc()
    ).limit(5).all()
    top_technicians = [
        {
            "id": t.id,
            "name": t.user.name if t.user else "N/A",
            "rating": t.rating,
            "jobs_completed": t.total_jobs,
            "earnings": 0,
        }
        for t in top_technicians_raw
    ]

    low_rated_raw = db.query(Technician).options(joinedload(Technician.user)).filter(
        Technician.rating <= 3.0, Technician.total_jobs > 0
    ).all()
    low_rated = [
        {
            "id": t.id,
            "name": t.user.name if t.user else "N/A",
            "rating": t.rating,
            "total_jobs": t.total_jobs,
        }
        for t in low_rated_raw
    ]

    return {
        "period_days": days,
        "overview": {
            "total_users": total_customers,
            "total_technicians": total_technicians,
            "total_bookings": total_bookings,
            "total_revenue": round(total_revenue, 2),
        },
        "bookings": {
            "total": total_bookings,
            "recent": recent_bookings,
            "completed": completed_bookings,
            "pending": pending_bookings,
            "in_progress": in_progress_bookings,
            "cancelled": cancelled_bookings,
        },
        "bookings_by_status": {
            "completed": completed_bookings,
            "in_progress": in_progress_bookings,
            "pending": pending_bookings,
            "cancelled": cancelled_bookings,
        },
        "revenue": {
            "total": round(total_revenue, 2),
            "recent": round(recent_revenue, 2),
        },
        "revenue_by_period": [
            {"period": f"Last {days} days", "amount": round(recent_revenue, 2)},
        ],
        "users": {
            "customers": total_customers,
            "technicians": total_technicians,
            "verified_technicians": verified_technicians,
        },
        "top_technicians": top_technicians,
        "low_rated_technicians": low_rated,
    }

@router.get("/analytics/bookings")
def get_booking_analytics(
    days: int = 30,
    db: Session = Depends(get_db),
    current_user: User = Depends(verify_admin)
):
    cutoff = datetime.utcnow() - timedelta(days=days)
    bookings = db.query(Booking).filter(Booking.created_at >= cutoff).all()
    status_counts: dict = {}
    for b in bookings:
        status_counts[b.status] = status_counts.get(b.status, 0) + 1
    avg_price = sum(b.total_price for b in bookings) / len(bookings) if bookings else 0
    return {
        "period_days": days,
        "total_bookings": len(bookings),
        "by_status": status_counts,
        "average_price": round(avg_price, 2),
    }

@router.get("/analytics/revenue")
def get_revenue_analytics(
    days: int = 30,
    db: Session = Depends(get_db),
    current_user: User = Depends(verify_admin)
):
    cutoff = datetime.utcnow() - timedelta(days=days)
    payments = db.query(Payment).filter(
        Payment.status == "completed"
    ).all()
    total_revenue = sum(p.amount for p in payments)
    method_revenue: dict = {}
    for p in payments:
        method_revenue[p.method] = method_revenue.get(p.method, 0) + p.amount
    return {
        "period_days": days,
        "total_revenue": round(total_revenue, 2),
        "transaction_count": len(payments),
        "average_transaction": round(total_revenue / len(payments), 2) if payments else 0,
        "by_method": method_revenue,
    }

@router.get("/top-technicians")
def get_top_technicians(
    limit: int = 10,
    db: Session = Depends(get_db),
    current_user: User = Depends(verify_admin)
):
    technicians = db.query(Technician).options(joinedload(Technician.user)).order_by(
        Technician.rating.desc(), Technician.total_jobs.desc()
    ).limit(limit).all()
    result = [
        {
            "id": t.id,
            "name": t.user.name if t.user else "N/A",
            "rating": t.rating,
            "total_jobs": t.total_jobs,
            "is_verified": t.is_verified,
        }
        for t in technicians
    ]
    return {"count": len(result), "technicians": result}
