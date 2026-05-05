from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session

from app.core.system.db import getSession
from app.core.enum import RES_CUSTOM_CODE_ENUM, RESPONSE_STATUS_ENUM
from app.schemas.base_schema import IResponseBase
from app.schemas.service_schema import (CategoryCreate
                                        , CategoryResponse
                                        , ServiceCreate
                                        , ServiceResponse
                                        , ServiceWithCategoryResponse)
from app.services.service_service import ServiceService


router = APIRouter()


@router.get("/categories"
    , summary="Get all categories"
    , description="Get all service categories"
    , response_model=IResponseBase[List[CategoryResponse]]
)
async def get_categories(
    active_only : bool = Query(False, description="Filter by active status only")
    , session   : Session = Depends(getSession)
):
    """Get all categories."""
    categories = await ServiceService.get_categories(session, active_only)

    return {
        "data": [
            CategoryResponse(
                id=str(cat.id),
                name=cat.name,
                icon=cat.icon,
                color_hex=cat.color_hex,
                is_active=cat.is_active,
                created_at=cat.created_at
            )
            for cat in categories
        ],
        "response_status": RESPONSE_STATUS_ENUM.SUCCESS,
        "response_code": int(RES_CUSTOM_CODE_ENUM.TRANSACTION_SUCCESS),
        "response_msg": 'Categories retrieved successfully'
    }


@router.post(
    "/categories",
    summary="Create a new category",
    description="Create a new service category",
    response_model=IResponseBase[CategoryResponse]
)
async def create_category(
    category_data: CategoryCreate,
    session: Session = Depends(getSession)
):
    """Create a new category."""
    try:
        category = await ServiceService.create_category(session, category_data)

        return {
            "data": CategoryResponse(
                id=str(category.id),
                name=category.name,
                icon=category.icon,
                color_hex=category.color_hex,
                is_active=category.is_active,
                created_at=category.created_at
            ),
            "response_status": RESPONSE_STATUS_ENUM.SUCCESS,
            "response_code": int(RES_CUSTOM_CODE_ENUM.TRANSACTION_SUCCESS),
            "response_msg": 'Category created successfully'
        }
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )


@router.put(
    "/categories/{category_id}",
    summary="Update a category",
    description="Update an existing category",
    response_model=IResponseBase[CategoryResponse]
)
async def update_category(
    category_id: str,
    name: Optional[str] = None,
    icon: Optional[str] = None,
    color_hex: Optional[str] = None,
    is_active: Optional[bool] = None,
    session: Session = Depends(getSession)
):
    """Update a category."""
    category = await ServiceService.update_category(
        session, category_id,
        name=name, icon=icon, color_hex=color_hex, is_active=is_active
    )

    if not category:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail='Category not found'
        )

    return {
        "data": CategoryResponse(
            id=str(category.id),
            name=category.name,
            icon=category.icon,
            color_hex=category.color_hex,
            is_active=category.is_active,
            created_at=category.created_at
        ),
        "response_status": RESPONSE_STATUS_ENUM.SUCCESS,
        "response_code": int(RES_CUSTOM_CODE_ENUM.TRANSACTION_SUCCESS),
        "response_msg": 'Category updated successfully'
    }


@router.delete(
    "/categories/{category_id}",
    summary="Delete a category",
    description="Delete (deactivate) a category",
    response_model=IResponseBase[dict]
)
async def delete_category(
    category_id: str,
    session: Session = Depends(getSession)
):
    """Delete a category."""
    success = await ServiceService.delete_category(session, category_id)

    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail='Category not found'
        )

    return {
        "data": {'message': 'Category deleted successfully'},
        "response_status": RESPONSE_STATUS_ENUM.SUCCESS,
        "response_code": int(RES_CUSTOM_CODE_ENUM.TRANSACTION_SUCCESS),
        "response_msg": 'Category deleted successfully'
    }


@router.get(
    "/",
    summary="Get all services",
    description="Get all services, optionally filtered by category",
    response_model=IResponseBase[List[ServiceResponse]]
)
async def get_services(
    category_id: Optional[str] = Query(None, description="Filter by category ID"),
    active_only: bool = Query(False, description="Filter by active status only"),
    session: Session = Depends(getSession)
):
    """Get all services."""
    services = await ServiceService.get_services(session, category_id, active_only)

    return {
        "data": [
            ServiceResponse(
                id=str(service.id),
                category_id=str(service.category_id),
                name=service.name,
                description=service.description,
                min_price=service.min_price,
                max_price=service.max_price,
                urgency_level=service.urgency_level,
                is_active=service.is_active,
                created_at=service.created_at
            )
            for service in services
        ],
        "response_status": RESPONSE_STATUS_ENUM.SUCCESS,
        "response_code": int(RES_CUSTOM_CODE_ENUM.TRANSACTION_SUCCESS),
        "response_msg": 'Services retrieved successfully'
    }


@router.post(
    "/",
    summary="Create a new service",
    description="Create a new service",
    response_model=IResponseBase[ServiceResponse]
)
async def create_service(
    service_data: ServiceCreate,
    session: Session = Depends(getSession)
):
    """Create a new service."""
    try:
        service = await ServiceService.create_service(session, service_data)

        return {
            "data": ServiceResponse(
                id=str(service.id),
                category_id=str(service.category_id),
                name=service.name,
                description=service.description,
                min_price=service.min_price,
                max_price=service.max_price,
                urgency_level=service.urgency_level,
                is_active=service.is_active,
                created_at=service.created_at
            ),
            "response_status": RESPONSE_STATUS_ENUM.SUCCESS,
            "response_code": int(RES_CUSTOM_CODE_ENUM.TRANSACTION_SUCCESS),
            "response_msg": 'Service created successfully'
        }
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )


@router.put(
    "/{service_id}",
    summary="Update a service",
    description="Update an existing service",
    response_model=IResponseBase[ServiceResponse]
)
async def update_service(
    service_id: str,
    name: Optional[str] = None,
    description: Optional[str] = None,
    min_price: Optional[float] = None,
    max_price: Optional[float] = None,
    urgency_level: Optional[int] = None,
    is_active: Optional[bool] = None,
    session: Session = Depends(getSession)
):
    """Update a service."""
    service = await ServiceService.update_service(
        session, service_id,
        name=name, description=description,
        min_price=min_price, max_price=max_price,
        urgency_level=urgency_level, is_active=is_active
    )

    if not service:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail='Service not found'
        )

    return {
        "data": ServiceResponse(
            id=str(service.id),
            category_id=str(service.category_id),
            name=service.name,
            description=service.description,
            min_price=service.min_price,
            max_price=service.max_price,
            urgency_level=service.urgency_level,
            is_active=service.is_active,
            created_at=service.created_at
        ),
        "response_status": RESPONSE_STATUS_ENUM.SUCCESS,
        "response_code": int(RES_CUSTOM_CODE_ENUM.TRANSACTION_SUCCESS),
        "response_msg": 'Service updated successfully'
    }


@router.delete(
    "/{service_id}",
    summary="Delete a service",
    description="Delete (deactivate) a service",
    response_model=IResponseBase[dict]
)
async def delete_service(
    service_id: str,
    session: Session = Depends(getSession)
):
    """Delete a service."""
    success = await ServiceService.delete_service(session, service_id)

    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail='Service not found'
        )

    return {
        "data": {'message': 'Service deleted successfully'},
        "response_status": RESPONSE_STATUS_ENUM.SUCCESS,
        "response_code": int(RES_CUSTOM_CODE_ENUM.TRANSACTION_SUCCESS),
        "response_msg": 'Service deleted successfully'
    }
