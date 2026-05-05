from typing import List, Optional
from datetime import datetime
from sqlalchemy.orm import Session

from app.models.service_model import CategoryModel, ServiceModel
from app.schemas.service_schema import CategoryCreate, ServiceCreate


class ServiceService:
    """Service for service and category operations."""

    @staticmethod
    async def get_categories(
        session       : Session
        , active_only : bool = False
    ) -> List[CategoryModel]:
        """Get all categories."""
        query = session.query(CategoryModel)
        if active_only:
            query = query.filter(CategoryModel.is_active == True)
        return query.all()

    @staticmethod
    async def get_category_by_id(
        session       : Session
        , category_id : str
    ) -> Optional[CategoryModel]:
        """Get a category by ID."""
        return session.query(CategoryModel).filter(
            CategoryModel.id == category_id
        ).first()

    @staticmethod
    async def create_category(
        session          : Session
        , category_data  : CategoryCreate
    ) -> CategoryModel:
        """Create a new category."""
        category = CategoryModel(
            name        = category_data.name
            , icon      = category_data.icon
            , color_hex = category_data.color_hex
            , is_active = True
        )
        session.add(category)
        session.commit()
        session.refresh(category)
        return category

    @staticmethod
    async def update_category(
        session       : Session
        , category_id : str
        , **kwargs
    ) -> Optional[CategoryModel]:
        """Update a category."""
        category = await ServiceService.get_category_by_id(session, category_id)
        if not category:
            return None

        for key, value in kwargs.items():
            if hasattr(category, key) and value is not None:
                setattr(category, key, value)

        category.updated_at = datetime.utcnow()
        session.commit()
        session.refresh(category)
        return category

    @staticmethod
    async def delete_category(
        session: Session,
        category_id: str
    ) -> bool:
        """Delete a category (soft delete by setting is_active to False)."""
        category = await ServiceService.get_category_by_id(session, category_id)
        if not category:
            return False

        category.is_active = False
        category.updated_at = datetime.utcnow()
        session.commit()
        return True

    @staticmethod
    async def get_services(
        session: Session,
        category_id: Optional[str] = None,
        active_only: bool = False
    ) -> List[ServiceModel]:
        """Get all services."""
        query = session.query(ServiceModel)
        if category_id:
            query = query.filter(ServiceModel.category_id == category_id)
        if active_only:
            query = query.filter(ServiceModel.is_active == True)
        return query.all()

    @staticmethod
    async def get_service_by_id(
        session: Session,
        service_id: str
    ) -> Optional[ServiceModel]:
        """Get a service by ID."""
        return session.query(ServiceModel).filter(
            ServiceModel.id == service_id
        ).first()

    @staticmethod
    async def create_service(
        session: Session,
        service_data: ServiceCreate
    ) -> ServiceModel:
        """Create a new service."""
        service = ServiceModel(
            category_id=service_data.category_id,
            name=service_data.name,
            description=service_data.description,
            min_price=service_data.min_price,
            max_price=service_data.max_price,
            urgency_level=service_data.urgency_level,
            is_active=service_data.is_active
        )
        session.add(service)
        session.commit()
        session.refresh(service)
        return service

    @staticmethod
    async def update_service(
        session: Session,
        service_id: str,
        **kwargs
    ) -> Optional[ServiceModel]:
        """Update a service."""
        service = await ServiceService.get_service_by_id(session, service_id)
        if not service:
            return None

        for key, value in kwargs.items():
            if hasattr(service, key) and value is not None:
                setattr(service, key, value)

        service.updated_at = datetime.utcnow()
        session.commit()
        session.refresh(service)
        return service

    @staticmethod
    async def delete_service(
        session: Session,
        service_id: str
    ) -> bool:
        """Delete a service (soft delete by setting is_active to False)."""
        service = await ServiceService.get_service_by_id(session, service_id)
        if not service:
            return False

        service.is_active = False
        service.updated_at = datetime.utcnow()
        session.commit()
        return True


__all__ = ["ServiceService"]
