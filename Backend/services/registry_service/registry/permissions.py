import hmac

from django.conf import settings
from rest_framework.permissions import SAFE_METHODS, BasePermission


class IsRegisteredServiceOrReadOnly(BasePermission):
    """Ai cũng tra cứu được, nhưng chỉ service có token nội bộ mới được đăng ký / hủy đăng ký."""

    message = 'Thiếu hoặc sai X-Service-Token.'

    def has_permission(self, request, view):
        if request.method in SAFE_METHODS:
            return True
        token = request.headers.get('X-Service-Token', '')
        return hmac.compare_digest(token, settings.SERVICE_REGISTRY_TOKEN)
