import json
from contextlib import contextmanager
from datetime import datetime
from time import perf_counter
from typing import Any, Awaitable, Callable, Optional, Tuple

from fastapi import Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from starlette.concurrency import iterate_in_threadpool
from starlette.exceptions import HTTPException
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import StreamingResponse

from app.core.config import settings
from app.core.enum import RES_CUSTOM_CODE_ENUM, RESPONSE_STATUS_ENUM
from app.core.system.db import getStaticSession
from app.core.system.log import logger
from app.schemas.base_schema import IResponseBase


def is_authorized(request: Request) -> bool:
    """Check if request is authorized (placeholder)."""
    return True


def _determine_log_level(http_status_code: int) -> str:
    """Determine log level based on HTTP status code."""
    return 'HIGH' if http_status_code >= 500 else 'MEDIUM'


async def _cache_request_body(request: Request) -> None:
    """Cache request body for logging purposes."""
    if request.method not in ('POST', 'PUT', 'PATCH'):
        return

    content_type = request.headers.get('content-type', '')
    if 'application/json' not in content_type:
        return

    try:
        body_bytes = await request.body()

        if body_bytes:
            try:
                request.state._cached_body = body_bytes.decode('utf-8')
            except UnicodeDecodeError:
                request.state._cached_body = f'<binary data, length: {len(body_bytes)}>'
        else:
            request.state._cached_body = None

        # Replace receive function to allow FastAPI to read body again
        request.state._body_sent = False

        async def receive():
            if request.state._body_sent:
                return {'type': 'http.request', 'body': b''}

            request.state._body_sent = True
            return {'type': 'http.request', 'body': body_bytes}

        if not hasattr(request.state, '_original_receive'):
            request.state._original_receive = request._receive
        request._receive = receive

    except Exception as body_error:
        logger.debug(f'Could not cache request body in BaseMiddleware: {str(body_error)}')
        request.state._cached_body = None


def _parse_content_type(header_content_type: Optional[str]) -> Optional[str]:
    """Parse content type header."""
    if not header_content_type:
        return None

    if header_content_type.startswith('multipart/form-data'):
        return 'multipart/form-data'
    elif header_content_type.startswith('application/x-www-form-urlencoded'):
        return 'application/x-www-form-urlencoded'
    elif header_content_type.startswith('application/json'):
        return 'application/json'

    return None


async def _extract_request_body(
    request: Request,
    content_type: Optional[str]
) -> Optional[Any]:
    """Extract request body for logging."""
    if request.method not in ('PUT', 'POST', 'PATCH'):
        return None

    if not content_type:
        return None

    try:
        if content_type == 'multipart/form-data':
            return await request.body()
        elif content_type == 'application/x-www-form-urlencoded':
            return (await request.body()).decode('utf-8')
        elif content_type == 'application/json':
            # Check if body is already cached by BaseMiddleware
            if hasattr(request.state, '_cached_body'):
                return request.state._cached_body

            # Cache body if not already cached
            try:
                body_bytes = await request.body()

                if body_bytes:
                    try:
                        request.state._cached_body = body_bytes.decode('utf-8')
                    except UnicodeDecodeError:
                        request.state._cached_body = f'<binary data, length: {len(body_bytes)}>'
                else:
                    request.state._cached_body = None

                # Replace receive function to allow FastAPI to read body again
                request.state._body_sent = False

                async def receive():
                    if request.state._body_sent:
                        return {'type': 'http.request', 'body': b''}
                    request.state._body_sent = True
                    return {'type': 'http.request', 'body': body_bytes}

                if not hasattr(request.state, '_original_receive'):
                    request.state._original_receive = request._receive
                request._receive = receive

                return request.state._cached_body
            except Exception as body_error:
                logger.debug(f'Could not cache request body in _extract_request_body: {str(body_error)}')
                return None
    except Exception as error:
        logger.error(f'Error extracting request body: {str(error)}')
        return None

    return None


async def _extract_response_body(response: StreamingResponse) -> Tuple[list, StreamingResponse]:
    """Extract response body for logging."""
    response_body = [section async for section in response.body_iterator]
    response.body_iterator = iterate_in_threadpool(iter(response_body))
    return response_body, response


def _decode_response_body(
    response_body: list,
    max_length: int = 1000
) -> str:
    """Decode response body for logging."""
    if not response_body:
        return 'No response body'

    try:
        decoded = response_body[0].decode()
        return decoded[:max_length] if len(decoded) > max_length else decoded
    except Exception:
        return 'Unable to decode response body'


def _extract_trace_id(response_body: list) -> Optional[str]:
    """Extract trace ID from response body."""
    if not response_body:
        return None

    try:
        response_json = json.loads(response_body[0])
        return response_json.get('trace_id')
    except Exception:
        return None


def _extract_trace_id_from_json_response(response: JSONResponse) -> str:
    """Extract trace ID from JSON response."""
    try:
        response_json = json.loads(response.body)
        return response_json.get('trace_id') or ''
    except Exception:
        return ''


@contextmanager
def _get_db_session():
    """Get database session context manager."""
    session = getStaticSession()
    try:
        yield session
    finally:
        session.close()


class BaseMiddleware(BaseHTTPMiddleware):
    """Base middleware for request/response processing."""

    async def dispatch(self, request: Request, call_next):
        try:
            await _cache_request_body(request)
            return await call_next(request)

        except RequestValidationError:
            raise
        except BaseException as e:
            error_msg = f'BaseMiddleware.dispatch Exception: {str(e)}'
            logger.error(error_msg)
            return JSONResponse(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                content={
                    "trace_id": "",
                    "data": None,
                    "response_status": RESPONSE_STATUS_ENUM.FAILED,
                    "response_code": int(RES_CUSTOM_CODE_ENUM.INTERNAL_SERVER_ERROR),
                    "response_msg": "Internal Server Error"
                }
            )


class LogMiddleware:
    """Middleware for logging requests and responses."""

    @staticmethod
    async def handle_http_exception(
        request: Request,
        exc: HTTPException
    ) -> JSONResponse:
        """Handle HTTP exceptions."""
        try:
            error_msg = (
                f'HTTPException {exc.status_code} in {request.method} {request.url.path}, '
                f'detail: {str(exc.detail)}, headers: {dict(exc.headers) if exc.headers else "N/A"}'
            )
            log_level = _determine_log_level(http_status_code=exc.status_code)

            # For 401 Unauthorized — return directly without DB lookup
            if exc.status_code == status.HTTP_401_UNAUTHORIZED:
                iresponse = IResponseBase(
                    response_status=RESPONSE_STATUS_ENUM.FAILED,
                    response_code=status.HTTP_401_UNAUTHORIZED,
                    response_msg='Unauthorized.'
                )
                response = JSONResponse(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    content=iresponse.model_dump()
                )
            else:
                # Map exception to API error code
                if isinstance(exc.detail, RES_CUSTOM_CODE_ENUM):
                    api_code = exc.detail
                elif exc.detail == 'Not Found':
                    api_code = RES_CUSTOM_CODE_ENUM.INVALID_URL
                else:
                    try:
                        api_code = RES_CUSTOM_CODE_ENUM(exc.detail)
                    except (ValueError, KeyError):
                        api_code = RES_CUSTOM_CODE_ENUM.INTERNAL_SERVER_ERROR

                iresponse = IResponseBase(
                    response_status=RESPONSE_STATUS_ENUM.FAILED,
                    response_code=api_code,
                    response_msg=str(exc.detail)
                )
                response = JSONResponse(
                    status_code=exc.status_code,
                    content=iresponse.model_dump()
                )

            return response

        except Exception as error:
            logger.error(f'LogMiddleware.handle_http_exception error: {str(error)}')
            return JSONResponse(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                content={
                    "trace_id": "",
                    "data": None,
                    "response_status": RESPONSE_STATUS_ENUM.FAILED,
                    "response_code": int(RES_CUSTOM_CODE_ENUM.INTERNAL_SERVER_ERROR),
                    "response_msg": "Internal Server Error"
                }
            )

    @staticmethod
    async def handle_validation_error(
        request: Request,
        exc: RequestValidationError
    ) -> JSONResponse:
        """Handle validation errors."""
        errors = exc.errors()
        error_msg = f'RequestValidationError: {str(errors)}'

        enhanced_error_data = errors
        user_friendly_msg = 'Validation failed'

        try:
            json_decode_error = _find_json_decode_error(errors)
            wrong_content_type_error = _find_wrong_content_type_error(errors)

            if json_decode_error:
                user_friendly_msg, enhanced_error_data = _process_json_decode_error(
                    request=request,
                    json_decode_error=json_decode_error
                )
            elif wrong_content_type_error:
                content_type = request.headers.get('content-type', 'unknown')
                user_friendly_msg = (
                    f'Request body must be JSON (Content-Type: application/json). '
                    f'Received Content-Type: {content_type}'
                )
                logger.error(f'Wrong Content-Type error: {str(errors)}')
            else:
                logger.error(f'Validation errors: {str(errors)}')

        except Exception as log_error:
            logger.error(f'Error logging validation exception: {str(log_error)}')
            logger.error(f'Validation errors: {str(errors)}')

        iresponse = IResponseBase(
            response_status=RESPONSE_STATUS_ENUM.FAILED,
            response_code=RES_CUSTOM_CODE_ENUM.INVALID_DATA_VALIDATION,
            response_msg=user_friendly_msg
        )
        return JSONResponse(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            content=iresponse.model_dump()
        )


def _find_json_decode_error(errors: list) -> Optional[dict]:
    """Find JSON decode error in validation errors."""
    for error in errors:
        if error.get('type') == 'json_invalid':
            return error
    return None


def _find_wrong_content_type_error(errors: list) -> Optional[dict]:
    """Find wrong content type error in validation errors."""
    for error in errors:
        if error.get('type') == 'model_attributes_type' and error.get('loc') == ('body',):
            return error
    return None


def _process_json_decode_error(
    request: Request,
    json_decode_error: dict
) -> Tuple[str, list]:
    """Process JSON decode error."""
    request_body = getattr(request.state, '_cached_body', None)
    ctx = json_decode_error.get('ctx', {})
    json_error_detail = ctx.get('error', 'Unknown JSON error')
    error_location = json_decode_error.get('loc', [])

    logger.error(f'JSON decode error: {json_error_detail}')
    logger.error(f'Error location: {error_location}')

    if request_body:
        body_preview = request_body[:1000] if len(request_body) > 1000 else request_body
        logger.error(f'Request body: {body_preview}')
        if len(request_body) > 1000:
            logger.error(f'Request body (truncated, total length: {len(request_body)})')

        # Generate user-friendly message based on error type
        if 'Expecting' in json_error_detail or 'delimiter' in json_error_detail:
            user_friendly_msg = (
                f'Invalid JSON syntax: {json_error_detail}. '
                'Please ensure all string values are properly quoted (e.g., "value" not value).'
            )
        else:
            user_friendly_msg = f'Invalid JSON format: {json_error_detail}'
    else:
        logger.error('Request body: <unavailable - body was not cached>')
        user_friendly_msg = f'Invalid JSON format: {json_error_detail}'

    enhanced_error_data = [{
        **json_decode_error,
        'detail': json_error_detail,
        'hint': 'Check that all string values are properly quoted with double quotes (e.g., "value" not value)'
    }]

    return user_friendly_msg, enhanced_error_data


# Maintain backward compatibility with existing code that may call these methods
LogMiddleware.HTTPException = LogMiddleware.handle_http_exception
LogMiddleware.RequestValidationError = LogMiddleware.handle_validation_error
