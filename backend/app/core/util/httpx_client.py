import httpx
from typing import Optional

from app.core.config import settings

_global_httpx_client: Optional[httpx.AsyncClient] = None


def create_httpx_client() -> httpx.AsyncClient:
    """Create and return a new httpx async client."""
    return httpx.AsyncClient(
        timeout=httpx.Timeout(30.0),
        verify=False  # Disable SSL verification for development
    )


def set_global_httpx_client(client: Optional[httpx.AsyncClient]) -> None:
    """Set the global httpx client."""
    global _global_httpx_client
    _global_httpx_client = client


def get_global_httpx_client() -> Optional[httpx.AsyncClient]:
    """Get the global httpx client."""
    return _global_httpx_client


__all__ = [
    "create_httpx_client",
    "set_global_httpx_client",
    "get_global_httpx_client"
]
