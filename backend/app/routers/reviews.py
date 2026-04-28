from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func
from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.user import User, Technician
from app.models.booking import Booking, Review
from app.schemas.booking import ReviewCreate, ReviewResponse
from typing import List

router = APIRouter(prefix="/api/reviews", tags=["Reviews"])

@router.post("/{booking_id}", response_model=ReviewResponse)
def create_review(
    booking_id: str,
    review_data: ReviewCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Create a review for a completed booking"""
    # Verify booking exists and is completed
    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    
    if booking.status != "completed":
        raise HTTPException(status_code=400, detail="Booking must be completed to review")
    
    # Verify customer is the one leaving the review
    if booking.customer_id != current_user.id:
        raise HTTPException(status_code=403, detail="Only booking customer can review")
    
    # Check if review already exists
    existing_review = db.query(Review).filter(Review.booking_id == booking_id).first()
    if existing_review:
        raise HTTPException(status_code=400, detail="Review already exists for this booking")
    
    # Validate rating (1-5)
    if review_data.rating < 1 or review_data.rating > 5:
        raise HTTPException(status_code=400, detail="Rating must be between 1 and 5")
    
    review = Review(
        booking_id=booking_id,
        rating=review_data.rating,
        comment=review_data.comment
    )
    
    db.add(review)
    db.commit()
    db.refresh(review)
    
    # Update technician rating
    if booking.technician_id:
        technician = db.query(Technician).filter(Technician.id == booking.technician_id).first()
        if technician:
            # Calculate average rating
            reviews = db.query(Review).join(
                Booking, Review.booking_id == Booking.id
            ).filter(Booking.technician_id == booking.technician_id).all()
            
            if reviews:
                avg_rating = sum(r.rating for r in reviews) / len(reviews)
                technician.rating = round(avg_rating, 1)
                db.commit()
    
    return review

@router.get("/{booking_id}", response_model=ReviewResponse)
def get_review(
    booking_id: str,
    db: Session = Depends(get_db)
):
    """Get review for a booking"""
    review = db.query(Review).filter(Review.booking_id == booking_id).first()
    if not review:
        raise HTTPException(status_code=404, detail="Review not found")
    return review

@router.get("/technician/{technician_id}")
def get_technician_reviews(
    technician_id: str,
    db: Session = Depends(get_db)
):
    """Get all reviews for a technician"""
    reviews = db.query(Review).join(
        Booking, Review.booking_id == Booking.id
    ).filter(
        Booking.technician_id == technician_id
    ).all()
    
    return {
        "count": len(reviews),
        "average_rating": round(sum(r.rating for r in reviews) / len(reviews), 1) if reviews else 0,
        "reviews": reviews
    }

@router.put("/{review_id}", response_model=ReviewResponse)
def update_review(
    review_id: str,
    review_data: ReviewCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Update a review (only by reviewer)"""
    review = db.query(Review).filter(Review.id == review_id).first()
    if not review:
        raise HTTPException(status_code=404, detail="Review not found")
    
    # Verify reviewer is the current user
    booking = db.query(Booking).filter(Booking.id == review.booking_id).first()
    if booking.customer_id != current_user.id:
        raise HTTPException(status_code=403, detail="Access denied")
    
    review.rating = review_data.rating
    review.comment = review_data.comment
    db.commit()
    db.refresh(review)
    return review

@router.delete("/{review_id}")
def delete_review(
    review_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Delete a review (only by reviewer)"""
    review = db.query(Review).filter(Review.id == review_id).first()
    if not review:
        raise HTTPException(status_code=404, detail="Review not found")
    
    # Verify reviewer is the current user
    booking = db.query(Booking).filter(Booking.id == review.booking_id).first()
    if booking.customer_id != current_user.id:
        raise HTTPException(status_code=403, detail="Access denied")
    
    db.delete(review)
    db.commit()
    return {"message": "Review deleted"}
