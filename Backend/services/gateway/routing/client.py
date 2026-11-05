"""Gọi service phía sau gateway: tra địa chỉ qua registry rồi gửi request HTTP."""

import requests
from django.conf import settings

from soa_common.registry_client import discover

# Chỉ chuyển tiếp các header cần thiết, không làm lộ header nội bộ của client
FORWARDED_REQUEST_HEADERS = ['Authorization', 'Content-Type', 'Accept', 'Accept-Language']


def call_service(service_name, method, full_path, request=None, body=None):
    """Gửi request tới service. Ném ServiceUnavailable hoặc requests.RequestException khi lỗi."""
    base_url = discover(service_name)
    headers = {}
    if request is not None:
        headers = {name: request.headers[name] for name in FORWARDED_REQUEST_HEADERS if name in request.headers}
        # Service phía sau tạo URL (ví dụ link ảnh) theo địa chỉ gateway thay vì địa chỉ nội bộ
        headers['X-Forwarded-Host'] = request.get_host()
    return requests.request(
        method,
        f'{base_url}{full_path}',
        data=body,
        headers=headers,
        timeout=settings.GATEWAY_TIMEOUT_SECONDS,
        allow_redirects=False,
    )
