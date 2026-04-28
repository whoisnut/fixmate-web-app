from fastapi import APIRouter, Depends, HTTPException, status, Header
from sqlalchemy.orm import Session
from sqlalchemy import func
from sqlalchemy.exc import IntegrityError
from app.core.database import get_db
from app.core.security import hash_password, verify_password, create_access_token, decode_token, create_refresh_token, verify_token
from app.core.deps import get_current_user
from app.models.user import User, Technician, TokenBlacklist
from app.schemas.user import (
    UserCreate, UserLogin, TokenResponse, UserResponse, RefreshTokenRequest,
    TechnicianRegister, TechnicianLoginResponse, TechnicianVerificationStatus
)
from datetime import datetime, timedelta
from app.core.config import settings
from typing import List

router = APIRouter(prefix="/api/auth", tags=["Authentication"])

@router.post("/register", response_model=TokenResponse)
def register(user_data: UserCreate, db: Session = Depends(get_db)):
    normalized_email = user_data.email.strip().lower()
    normalized_phone = user_data.phone.strip() if user_data.phone else None

    if db.query(User).filter(func.lower(User.email) == normalized_email).first():
        raise HTTPException(status_code=409, detail="Email already registered")

    if normalized_phone and db.query(User).filter(User.phone == normalized_phone).first():
        raise HTTPException(status_code=409, detail="Phone number already registered")
    
    user = User(
        name=user_data.name,
        email=normalized_email,
        phone=normalized_phone,
        password=hash_password(user_data.password),
        role=user_data.role
    )
    db.add(user)
    try:
        db.commit()
        db.refresh(user)
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=409, detail="Account already exists")
    
    if user.role == "technician":
        tech = Technician(
            user_id=user.id,
            verification_status="pending",
            submitted_at=datetime.utcnow()
        )
        db.add(tech)
        db.commit()
    
    access_token = create_access_token({"sub": user.id, "role": user.role})
    return TokenResponse(
        access_token=access_token,
        user=UserResponse.from_orm(user),
        expires_in=86400
    )

@router.post("/register/technician", response_model=TechnicianLoginResponse)
def register_technician(tech_data: TechnicianRegister, db: Session = Depends(get_db)):
    """Register as a technician with documents for verification"""
    normalized_email = tech_data.email.strip().lower()
    normalized_phone = tech_data.phone.strip()
    
    # Check if email exists
    if db.query(User).filter(func.lower(User.email) == normalized_email).first():
        raise HTTPException(status_code=409, detail="Email already registered")
    
    # Check if phone exists
    if db.query(User).filter(User.phone == normalized_phone).first():
        raise HTTPException(status_code=409, detail="Phone number already registered")
    
    # Create user account
    user = User(
        name=tech_data.name,
        email=normalized_email,
        phone=normalized_phone,
        password=hash_password(tech_data.password),
        role="technician"
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    
    # Create technician profile
    technician = Technician(
        user_id=user.id,
        bio=tech_data.bio,
        specialties=tech_data.specialties,
        documents=[{"url": doc, "type": "document"} for doc in tech_data.documents],
        verification_status="pending",
        submitted_at=datetime.utcnow()
    )
    db.add(technician)
    db.commit()
    db.refresh(technician)
    
    # Create access token
    access_token = create_access_token({"sub": user.id, "role": user.role})
    
    # Refresh user to get technician relationship
    db.refresh(user)
    
    return TechnicianLoginResponse(
        access_token=access_token,
        user=UserResponse.from_orm(user),
        technician_status="pending",
        is_verified=False,
        can_accept_jobs=False,
        expires_in=86400
    )

@router.post("/login", response_model=TokenResponse)
def login(credentials: UserLogin, db: Session = Depends(get_db)):
    normalized_email = credentials.email.strip().lower()
    user = db.query(User).filter(func.lower(User.email) == normalized_email).first()
    if not user or not verify_password(credentials.password, user.password):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
    if not user.is_active:
        raise HTTPException(status_code=403, detail="Account has been suspended")
    
    # Load technician data if user is technician
    db.refresh(user)
    
    access_token = create_access_token({"sub": user.id, "role": user.role})
    return TokenResponse(
        access_token=access_token,
        user=UserResponse.from_orm(user),
        expires_in=86400
    )

@router.post("/login/technician", response_model=TechnicianLoginResponse)
def login_technician(credentials: UserLogin, db: Session = Depends(get_db)):
    """Technician login with verification status"""
    normalized_email = credentials.email.strip().lower()
    user = db.query(User).filter(
        func.lower(User.email) == normalized_email,
        User.role == "technician"
    ).first()
    
    if not user or not verify_password(credentials.password, user.password):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
    if not user.is_active:
        raise HTTPException(status_code=403, detail="Account has been suspended")
    
    # Get technician profile
    tech = db.query(Technician).filter(Technician.user_id == user.id).first()
    if not tech:
        raise HTTPException(status_code=500, detail="Technician profile not found")
    
    # Refresh to load relationships
    db.refresh(user)
    db.refresh(tech)
    
    access_token = create_access_token({"sub": user.id, "role": user.role})
    
    return TechnicianLoginResponse(
        access_token=access_token,
        user=UserResponse.from_orm(user),
        technician_status=tech.verification_status,
        is_verified=tech.is_verified,
        can_accept_jobs=tech.is_verified and tech.is_available,
        expires_in=86400
    )

@router.post("/refresh", response_model=TokenResponse)
def refresh_token(
    request: RefreshTokenRequest,
    db: Session = Depends(get_db)
):
    """Refresh access token using refresh token"""
    payload = decode_token(request.refresh_token)
    if not payload:
        raise HTTPException(status_code=401, detail="Invalid refresh token")
    
    user_id = payload.get("sub")
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=401, detail="User not found")
    
    # Check if token is blacklisted
    is_blacklisted = db.query(TokenBlacklist).filter(
        TokenBlacklist.token == request.refresh_token,
        TokenBlacklist.user_id == user_id
    ).first()
    if is_blacklisted:
        raise HTTPException(status_code=401, detail="Token has been revoked")
    
    new_access_token = create_access_token({"sub": user.id, "role": user.role})
    return TokenResponse(access_token=new_access_token, user=UserResponse.from_orm(user))

@router.post("/logout")
def logout(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    authorization: str = Header(None)
):
    """Logout user and blacklist their current token"""
    if not authorization:
        raise HTTPException(status_code=401, detail="Authorization header missing")
    
    token = authorization.replace("Bearer ", "")
    payload = decode_token(token)
    if not payload:
        raise HTTPException(status_code=401, detail="Invalid token")
    
    # Get token expiration
    exp_timestamp = payload.get("exp")
    expires_at = datetime.utcfromtimestamp(exp_timestamp)
    
    # Add token to blacklist
    blacklisted_token = TokenBlacklist(
        user_id=current_user.id,
        token=token,
        expires_at=expires_at
    )
    db.add(blacklisted_token)
    db.commit()
    
    return {"message": "Successfully logged out"}

@router.get("/technician/verification-status", response_model=TechnicianVerificationStatus)
def get_technician_verification_status(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get technician verification status"""
    if current_user.role != "technician":
        raise HTTPException(status_code=403, detail="Only technicians can check verification status")
    
    tech = db.query(Technician).filter(Technician.user_id == current_user.id).first()
    if not tech:
        raise HTTPException(status_code=404, detail="Technician profile not found")
    
    return TechnicianVerificationStatus(
        user_id=current_user.id,
        is_verified=tech.is_verified,
        status=tech.verification_status,
        rejection_reason=tech.rejection_reason,
        submitted_at=tech.submitted_at,
        verified_at=tech.verified_at
    )

@router.post("/technician/upload-documents")
def upload_technician_documents(
    documents: List[str],  # Base64 encoded or file URLs
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Upload documents for technician verification"""
    if current_user.role != "technician":
        raise HTTPException(status_code=403, detail="Only technicians can upload documents")
    
    if not documents:
        raise HTTPException(status_code=400, detail="At least one document is required")
    
    tech = db.query(Technician).filter(Technician.user_id == current_user.id).first()
    if not tech:
        raise HTTPException(status_code=404, detail="Technician profile not found")
    
    # Update documents
    tech.documents = [
        {"url": doc, "type": "document", "uploaded_at": datetime.utcnow().isoformat()}
        for doc in documents
    ]
    tech.verification_status = "pending"
    tech.submitted_at = datetime.utcnow()
    tech.rejection_reason = None  # Clear any previous rejection
    
    db.commit()
    db.refresh(tech)
    
    return {
        "message": "Documents uploaded successfully",
        "verification_status": tech.verification_status,
        "documents_count": len(tech.documents)
    }
