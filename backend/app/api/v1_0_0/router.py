from fastapi import APIRouter

from app.api.v1_0_0.handler import (auth_handler
                                    , service_handler
                                    , app_credential_handler
                                    , admin_handler
                                    , booking_handler)

router = APIRouter()

# Include all handlers
router.include_router(auth_handler.router, prefix="/auth" , tags=["Authentication"])
router.include_router(service_handler.router, prefix="/services" , tags=["Services"])
router.include_router(app_credential_handler.router, prefix="/apps" , tags=["App Credentials"])
router.include_router(admin_handler.router, prefix="/admin" , tags=["Admin"])
router.include_router(booking_handler.router, prefix="/bookings" , tags=["Bookings"])
