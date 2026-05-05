from typing import List, Optional
from datetime import datetime
from uuid import UUID
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_

from app.models.booking_model import BookingModel, ReviewModel, MessageModel
from app.models.user_model import TechnicianModel
from app.models.service_model import ServiceModel
from app.schemas.booking_schema import BookingCreate, ReviewCreate, MessageCreate
from app.core.enum import BOOKING_STATUS_ENUM
from app.core.util.utils import Utils


class BookingService:
    """Service for booking operations."""

    @staticmethod
    async def create_booking(
        session         : Session
        , customer_id   : UUID
        , booking_data  : BookingCreate
    ) -> BookingModel:
        """Create a new booking."""
        # Get service to validate and get price
        service = session.query(ServiceModel).filter(
            ServiceModel.id == booking_data.service_id
        ).first()
        if not service:
            raise ValueError('Service not found')

        # Calculate total price
        total_price = booking_data.total_price or service.min_price

        # Validate price is within service bounds
        if total_price < service.min_price or total_price > service.max_price:
            raise ValueError(
                f'Price must be between {service.min_price} and {service.max_price}'
            )

        booking = BookingModel(
            customer_id = customer_id
            , service_id = booking_data.service_id
            , address = booking_data.address
            , lat = booking_data.lat
            , lng = booking_data.lng
            , scheduled_at = booking_data.scheduled_at
            , notes = booking_data.notes
            , status = BOOKING_STATUS_ENUM.PENDING.value
            , total_price = total_price
        )
        session.add(booking)
        session.commit()
        session.refresh(booking)
        return booking

    @staticmethod
    async def get_booking_by_id(
        session     : Session
        , booking_id: str
    ) -> Optional[BookingModel]:
        """Get a booking by ID."""
        return session.query(BookingModel).filter(
            BookingModel.id == booking_id
        ).first()

    @staticmethod
    async def get_user_bookings(
        session: Session,
        user_id: UUID,
        user_role: str,
        status: Optional[str] = None
    ) -> List[BookingModel]:
        """Get bookings for a user."""
        if user_role == 'customer':
            query = session.query(BookingModel).filter(
                BookingModel.customer_id == user_id
            )
        elif user_role == 'technician':
            tech = session.query(TechnicianModel).filter(
                TechnicianModel.user_id == user_id
            ).first()
            if tech:
                query = session.query(BookingModel).filter(
                    BookingModel.technician_id == tech.id
                )
            else:
                return []
        elif user_role == 'admin':
            query = session.query(BookingModel)
        else:
            return []

        if status:
            query = query.filter(BookingModel.status == status)

        return query.all()

    @staticmethod
    async def get_available_bookings(
        session: Session,
        technician_id: str,
        radius_km: float = 50.0
    ) -> List[BookingModel]:
        """Get available bookings for a technician within radius."""
        # Get technician location
        tech = session.query(TechnicianModel).filter(
            TechnicianModel.id == technician_id
        ).first()
        if not tech or not tech.current_lat or not tech.current_lng:
            # Return all pending bookings if no location
            return session.query(BookingModel).filter(
                BookingModel.status == BOOKING_STATUS_ENUM.PENDING.value,
                BookingModel.technician_id == None
            ).all()

        # Get pending bookings
        bookings = session.query(BookingModel).filter(
            BookingModel.status == BOOKING_STATUS_ENUM.PENDING.value,
            BookingModel.technician_id == None
        ).all()

        # Filter by distance
        available_bookings = []
        for booking in bookings:
            distance = Utils.haversine_distance_km(
                tech.current_lat, tech.current_lng,
                booking.lat, booking.lng
            )
            if distance <= radius_km:
                available_bookings.append(booking)

        return available_bookings

    @staticmethod
    async def update_booking_status(
        session: Session,
        booking_id: str,
        new_status: str
    ) -> Optional[BookingModel]:
        """Update booking status with validation."""
        booking = await BookingService.get_booking_by_id(session, booking_id)
        if not booking:
            return None

        # Validate status transition
        valid_transitions = {
            BOOKING_STATUS_ENUM.PENDING.value: [
                BOOKING_STATUS_ENUM.ACCEPTED.value,
                BOOKING_STATUS_ENUM.CANCELLED.value
            ],
            BOOKING_STATUS_ENUM.ACCEPTED.value: [
                BOOKING_STATUS_ENUM.IN_PROGRESS.value,
                BOOKING_STATUS_ENUM.CANCELLED.value
            ],
            BOOKING_STATUS_ENUM.IN_PROGRESS.value: [
                BOOKING_STATUS_ENUM.COMPLETED.value,
                BOOKING_STATUS_ENUM.CANCELLED.value
            ],
            BOOKING_STATUS_ENUM.COMPLETED.value: [],
            BOOKING_STATUS_ENUM.CANCELLED.value: []
        }

        current_status = booking.status
        if new_status not in valid_transitions.get(current_status, []):
            raise ValueError(
                f'Cannot transition from {current_status} to {new_status}'
            )

        booking.status = new_status
        booking.updated_at = datetime.utcnow()
        session.commit()
        session.refresh(booking)
        return booking

    @staticmethod
    async def accept_booking(
        session: Session,
        booking_id: str,
        technician_id: str
    ) -> Optional[BookingModel]:
        """Technician accepts a booking."""
        booking = await BookingService.get_booking_by_id(session, booking_id)
        if not booking:
            return None

        if booking.status != BOOKING_STATUS_ENUM.PENDING.value:
            raise ValueError('Booking is not available')

        booking.technician_id = technician_id
        booking.status = BOOKING_STATUS_ENUM.ACCEPTED.value
        booking.updated_at = datetime.utcnow()
        session.commit()
        session.refresh(booking)
        return booking

    @staticmethod
    async def start_booking(
        session: Session,
        booking_id: str,
        technician_id: str
    ) -> Optional[BookingModel]:
        """Technician starts the job."""
        booking = await BookingService.get_booking_by_id(session, booking_id)
        if not booking:
            return None

        if booking.technician_id != technician_id:
            raise ValueError('This booking is not assigned to you')

        if booking.status != BOOKING_STATUS_ENUM.ACCEPTED.value:
            raise ValueError('Booking must be accepted first')

        booking.status = BOOKING_STATUS_ENUM.IN_PROGRESS.value
        booking.updated_at = datetime.utcnow()
        session.commit()
        session.refresh(booking)
        return booking

    @staticmethod
    async def complete_booking(
        session: Session,
        booking_id: str,
        technician_id: str
    ) -> Optional[BookingModel]:
        """Technician completes the job."""
        booking = await BookingService.get_booking_by_id(session, booking_id)
        if not booking:
            return None

        if booking.technician_id != technician_id:
            raise ValueError('This booking is not assigned to you')

        if booking.status != BOOKING_STATUS_ENUM.IN_PROGRESS.value:
            raise ValueError('Booking must be in progress')

        booking.status = BOOKING_STATUS_ENUM.COMPLETED.value
        booking.updated_at = datetime.utcnow()

        # Update technician job count
        tech = session.query(TechnicianModel).filter(
            TechnicianModel.id == technician_id
        ).first()
        if tech:
            tech.total_jobs += 1

        session.commit()
        session.refresh(booking)
        return booking

    @staticmethod
    async def cancel_booking(
        session: Session,
        booking_id: str
    ) -> bool:
        """Cancel a booking."""
        booking = await BookingService.get_booking_by_id(session, booking_id)
        if not booking:
            return False

        if booking.status in [
            BOOKING_STATUS_ENUM.COMPLETED.value,
            BOOKING_STATUS_ENUM.CANCELLED.value
        ]:
            raise ValueError('Cannot cancel this booking')

        booking.status = BOOKING_STATUS_ENUM.CANCELLED.value
        booking.updated_at = datetime.utcnow()
        session.commit()
        return True

    @staticmethod
    async def create_review(
        session: Session,
        booking_id: str,
        customer_id: str,
        review_data: ReviewCreate
    ) -> ReviewModel:
        """Create a review for a completed booking."""
        booking = await BookingService.get_booking_by_id(session, booking_id)
        if not booking:
            raise ValueError('Booking not found')

        if booking.status != BOOKING_STATUS_ENUM.COMPLETED.value:
            raise ValueError('Booking must be completed to review')

        if booking.customer_id != customer_id:
            raise ValueError('Only booking customer can review')

        # Check if review already exists
        existing_review = session.query(ReviewModel).filter(
            ReviewModel.booking_id == booking_id
        ).first()
        if existing_review:
            raise ValueError('Review already exists for this booking')

        review = ReviewModel(
            booking_id=booking_id,
            rating=review_data.rating,
            comment=review_data.comment
        )
        session.add(review)
        session.commit()
        session.refresh(review)

        # Update technician rating
        if booking.technician_id:
            tech = session.query(TechnicianModel).filter(
                TechnicianModel.id == booking.technician_id
            ).first()
            if tech:
                # Calculate average rating
                reviews = session.query(ReviewModel).join(
                    BookingModel, ReviewModel.booking_id == BookingModel.id
                ).filter(
                    BookingModel.technician_id == booking.technician_id
                ).all()

                if reviews:
                    avg_rating = sum(r.rating for r in reviews) / len(reviews)
                    tech.rating = round(avg_rating, 1)
                session.commit()

        return review

    @staticmethod
    async def send_message(
        session: Session,
        booking_id: str,
        sender_id: str,
        message_data: MessageCreate
    ) -> MessageModel:
        """Send a message in a booking chat."""
        booking = await BookingService.get_booking_by_id(session, booking_id)
        if not booking:
            raise ValueError('Booking not found')

        # Check if user is part of this booking
        if booking.customer_id != sender_id and booking.technician_id != sender_id:
            raise ValueError('Access denied')

        message = MessageModel(
            booking_id=booking_id,
            sender_id=sender_id,
            content=message_data.content
        )
        session.add(message)
        session.commit()
        session.refresh(message)
        return message

    @staticmethod
    async def get_booking_messages(
        session: Session,
        booking_id: str,
        limit: int = 50,
        offset: int = 0
    ) -> List[MessageModel]:
        """Get all messages for a booking."""
        return session.query(MessageModel).filter(
            MessageModel.booking_id == booking_id
        ).order_by(MessageModel.sent_at).offset(offset).limit(limit).all()


__all__ = ["BookingService"]
