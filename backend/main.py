import traceback
from contextlib import asynccontextmanager
from uuid import uuid4

import httpx
import urllib3

# Suppress InsecureRequestWarning for unverified HTTPS requests
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from starlette.exceptions import HTTPException as StarletteHTTPException

# ROUTE
from app.api.v1_0_0.router import router
# APP
from app.core.config import settings
from app.core.enum import RES_CUSTOM_CODE_ENUM
from app.core.system.log import logger
from app.core.util.httpx_client import (create_httpx_client,
                                        set_global_httpx_client)
# MIDDLEWARE
from app.middleware import BaseMiddleware, LogMiddleware

process_id = uuid4()

@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info(f"Process started... {process_id}")

    # Initialize httpx client and store in app state and global
    httpx_client = create_httpx_client()
    app.state.httpx_client = httpx_client
    set_global_httpx_client(httpx_client)

    try:
        yield
    finally:
        # Cleanup: close httpx client and clear references
        try:
            await httpx_client.aclose()
        except Exception as e:
            logger.error(f"Error closing httpx client: {str(e)}")

        set_global_httpx_client(None)
        app.state.httpx_client = None
        logger.info(f"Process stopped... {process_id}")


app = FastAPI(
    title=settings.PROJECT_NAME,
    openapi_url=f"{settings.API_V1_0_0_STR}/openapi.json",
    lifespan=lifespan
)

app.add_middleware(BaseMiddleware)
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.WHITE_LIST_CORS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"]
)


@app.exception_handler(StarletteHTTPException)
async def http_exception_handler(request: Request, exc: StarletteHTTPException):
    return await LogMiddleware.handle_http_exception(request=request, exc=exc)


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    return await LogMiddleware.handle_validation_error(request=request, exc=exc)


@app.exception_handler(Exception)
async def general_exception_handler(request: Request, exc: Exception):
    """Catch all unhandled exceptions and log with full traceback."""
    error_msg = (
        f'Unhandled exception in {request.method} {request.url.path} - '
        f'Error: {str(exc)}\n'
        f'Traceback:\n{traceback.format_exc()}'
    )
    logger.error(error_msg)
    return await LogMiddleware.handle_http_exception(
        request=request,
        exc=StarletteHTTPException(
            status_code=500,
            detail=RES_CUSTOM_CODE_ENUM.INTERNAL_SERVER_ERROR
        )
    )


app.include_router(router=router, prefix=settings.API_V1_0_0_STR)


@app.get("/")
def root():
    return {"message": "FixMate API", "version": "1.0.0"}


@app.get("/health")
def health():
    return {"status": "healthy"}
