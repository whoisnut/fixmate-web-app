from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.user import User
from app.models.payout import Payout
from app.schemas.payout import PayoutCreate, PayoutResponse, PayoutStatusUpdate
from datetime import datetime
from typing import List

router = APIRouter(prefix="/api/payouts", tags=["Payouts"])

def verify_admin(current_user: User = Depends(get_current_user)):
    """Verify user is admin"""
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Admin access required")
    return current_user

@router.post("", response_model=PayoutResponse)
def create_payout_request(
    payout_data: PayoutCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Create a payout request (technician only)"""
    if current_user.role != "technician":
        raise HTTPException(status_code=403, detail="Only technicians can request payouts")
    
    # Validate minimum amount (⚠️ USER INPUT: Adjust minimum payout amount)
    MIN_PAYOUT = 5.0  # Minimum $5 per payout
    if payout_data.amount < MIN_PAYOUT:
        raise HTTPException(
            status_code=400, 
            detail=f"Minimum payout amount is ${MIN_PAYOUT}"
        )
    
    payout = Payout(
        user_id=current_user.id,
        amount=payout_data.amount,
        method=payout_data.method,
        payment_account=payout_data.payment_account
    )
    
    db.add(payout)
    db.commit()
    db.refresh(payout)
    return payout

@router.get("/my-requests", response_model=List[PayoutResponse])
def get_my_payouts(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get current user's payout requests"""
    payouts = db.query(Payout).filter(Payout.user_id == current_user.id).all()
    return payouts

@router.get("/{payout_id}", response_model=PayoutResponse)
def get_payout(
    payout_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get payout details"""
    payout = db.query(Payout).filter(Payout.id == payout_id).first()
    if not payout:
        raise HTTPException(status_code=404, detail="Payout not found")
    
    # Check authorization
    if current_user.id != payout.user_id and current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Access denied")
    
    return payout

@router.get("")
def get_all_payouts(
    status: str = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(verify_admin)
):
    """Get all payout requests (admin only)"""
    query = db.query(Payout)
    
    if status:
        query = query.filter(Payout.status == status)
    
    payouts = query.all()
    return {
        "total": len(payouts),
        "pending": len([p for p in payouts if p.status == "pending"]),
        "approved": len([p for p in payouts if p.status == "approved"]),
        "payouts": payouts
    }

@router.post("/{payout_id}/approve", response_model=PayoutResponse)
def approve_payout(
    payout_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(verify_admin)
):
    """Approve a payout request (admin only)"""
    payout = db.query(Payout).filter(Payout.id == payout_id).first()
    if not payout:
        raise HTTPException(status_code=404, detail="Payout not found")
    
    if payout.status != "pending":
        raise HTTPException(status_code=400, detail="Only pending payouts can be approved")
    
    payout.status = "approved"
    payout.processed_at = datetime.utcnow()
    
    # ⚠️ USER INPUT: Integrate with ABA Pay or Wing payment gateway here
    # For now, just mark as approved. In production:
    # 1. Call ABA Pay or Wing API with payout_data
    # 2. Get transaction ID
    # 3. Mark as "completed" only after successful payment
    
    db.commit()
    db.refresh(payout)
    return payout

@router.post("/{payout_id}/reject", response_model=PayoutResponse)
def reject_payout(
    payout_id: str,
    rejection_data: PayoutStatusUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(verify_admin)
):
    """Reject a payout request (admin only)"""
    payout = db.query(Payout).filter(Payout.id == payout_id).first()
    if not payout:
        raise HTTPException(status_code=404, detail="Payout not found")
    
    if payout.status != "pending":
        raise HTTPException(status_code=400, detail="Only pending payouts can be rejected")
    
    payout.status = "rejected"
    payout.reason = rejection_data.reason
    payout.processed_at = datetime.utcnow()
    
    db.commit()
    db.refresh(payout)
    return payout

@router.post("/{payout_id}/complete", response_model=PayoutResponse)
def complete_payout(
    payout_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(verify_admin)
):
    """Mark payout as completed (admin only)"""
    payout = db.query(Payout).filter(Payout.id == payout_id).first()
    if not payout:
        raise HTTPException(status_code=404, detail="Payout not found")
    
    if payout.status != "approved":
        raise HTTPException(status_code=400, detail="Only approved payouts can be completed")
    
    payout.status = "completed"
    db.commit()
    db.refresh(payout)
    return payout

@router.get("/analytics/payouts")
def get_payout_analytics(
    db: Session = Depends(get_db),
    current_user: User = Depends(verify_admin)
):
    """Get payout analytics"""
    all_payouts = db.query(Payout).all()
    
    total_pending = sum(p.amount for p in all_payouts if p.status == "pending")
    total_completed = sum(p.amount for p in all_payouts if p.status == "completed")
    total_rejected = sum(p.amount for p in all_payouts if p.status == "rejected")
    
    return {
        "total_payouts": len(all_payouts),
        "pending": {
            "count": len([p for p in all_payouts if p.status == "pending"]),
            "amount": round(total_pending, 2)
        },
        "approved": {
            "count": len([p for p in all_payouts if p.status == "approved"]),
        },
        "completed": {
            "count": len([p for p in all_payouts if p.status == "completed"]),
            "amount": round(total_completed, 2)
        },
        "rejected": {
            "count": len([p for p in all_payouts if p.status == "rejected"]),
            "amount": round(total_rejected, 2)
        }
    }
