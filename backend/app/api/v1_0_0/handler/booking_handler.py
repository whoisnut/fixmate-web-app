from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session

from app.core.system.db import getSession
from app.core.enum import RES_CUSTOM_CODE_ENUM, RESPONSE_STATUS_ENUM
from app.schemas.base_schema import IResponseBase
from app.schemas.booking_schema import BookingCreate, BookingResponse
from app.services.booking_service import BookingService
from app.api.v1_0_0.deps import get_current_user
from app.models.user_model import UserModel

router = APIRouter()


@router.post("/"
    , summary="Create a booking"
    , description="Create a new service booking"
    , response_model=IResponseBase[BookingResponse]
)
async def create_booking(
    booking_data    : BookingCreate
    , current_user  : UserModel = Depends(get_current_user)
    , session       : Session = Depends(getSession)
):
    """Create a new booking."""
    try:
        booking = await BookingService.create_booking(
            session, current_user.id, booking_data
        )

        return {
            "data": BookingResponse(
                id=str(booking.id),
                customer_id=str(booking.customer_id),
                service_id=str(booking.service_id),
                technician_id=str(booking.technician_id) if booking.technician_id else None,
                status=booking.status,
                address=booking.address,
                scheduled_at=booking.scheduled_at,
                total_price=booking.total_price,
                created_at=booking.created_at
            ),
            "response_status": RESPONSE_STATUS_ENUM.SUCCESS,
            "response_code": int(RES_CUSTOM_CODE_ENUM.TRANSACTION_SUCCESS),
            "response_msg": 'Booking created successfully'
        }
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )


@router.get(
    "/",
    summary="Get user bookings",
    description="Get all bookings for the current user",
    response_model=IResponseBase[List[BookingResponse]]
)
async def get_bookings(
    status: Optional[str] = None,
    current_user: UserModel = Depends(get_current_user),
    session: Session = Depends(getSession)
):
    """Get user bookings."""
    bookings = await BookingService.get_user_bookings(
        session, current_user.id, current_user.role, status
    )

    return {
        "data": [
            BookingResponse(
                id=str(b.id),
                customer_id=str(b.customer_id),
                service_id=str(b.service_id),
                technician_id=str(b.technician_id) if b.technician_id else None,
                status=b.status,
                address=b.address,
                scheduled_at=b.scheduled_at,
                total_price=b.total_price,
                created_at=b.created_at
            )
            for b in bookings
        ],
        "response_status": RESPONSE_STATUS_ENUM.SUCCESS,
        "response_code": int(RES_CUSTOM_CODE_ENUM.TRANSACTION_SUCCESS),
        "response_msg": 'Bookings retrieved successfully'
    }
