"""Client gọi Service Registry: đăng ký service và tra cứu địa chỉ service khác (Discoverability)."""

import time

import requests
from django.conf import settings

REQUEST_TIMEOUT_SECONDS = 3
DISCOVERY_CACHE_SECONDS = 10

_discovery_cache = {}


class ServiceUnavailable(Exception):
    """Không tìm thấy service trong registry hoặc registry không trả lời."""


def _registry_headers():
    return {'X-Service-Token': settings.SERVICE_REGISTRY_TOKEN}


def register_self():
    """Đăng ký (hoặc gia hạn heartbeat) service hiện tại với registry."""
    base_url = f'http://{settings.SERVICE_HOST}:{settings.SERVICE_PORT}'
    payload = {
        'name': settings.SERVICE_NAME,
        'version': settings.SPECTACULAR_SETTINGS['VERSION'],
        'base_url': base_url,
        'health_url': f'{base_url}/health/',
        'contract_url': f'{base_url}/api/schema/',
        'description': settings.SERVICE_DESCRIPTION,
    }
    response = requests.post(
        f'{settings.SERVICE_REGISTRY_URL}/registry/services/',
        json=payload,
        headers=_registry_headers(),
        timeout=REQUEST_TIMEOUT_SECONDS,
    )
    response.raise_for_status()


def discover(service_name):
    """Trả về base_url của service theo tên. Kết quả được cache ngắn hạn để giảm tải cho registry."""
    cached = _discovery_cache.get(service_name)
    if cached and time.monotonic() - cached[1] < DISCOVERY_CACHE_SECONDS:
        return cached[0]

    try:
        response = requests.get(
            f'{settings.SERVICE_REGISTRY_URL}/registry/services/{service_name}/',
            timeout=REQUEST_TIMEOUT_SECONDS,
        )
    except requests.RequestException as error:
        # Registry tạm thời không trả lời: dùng địa chỉ đã biết gần nhất nếu có
        if cached:
            return cached[0]
        raise ServiceUnavailable(service_name) from error

    if response.status_code != 200:
        raise ServiceUnavailable(service_name)

    base_url = response.json()['base_url']
    _discovery_cache[service_name] = (base_url, time.monotonic())
    return base_url


def list_services():
    response = requests.get(f'{settings.SERVICE_REGISTRY_URL}/registry/services/', timeout=REQUEST_TIMEOUT_SECONDS)
    response.raise_for_status()
    return response.json()


def clear_cache():
    _discovery_cache.clear()
