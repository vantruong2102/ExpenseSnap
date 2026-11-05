"""Service Registry: danh bạ để các service đăng ký và tìm thấy nhau (Discoverability)."""

import os
import sys
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent
sys.path.append(str(BASE_DIR.parent.parent))

from soa_common.settings_base import *  # noqa: E402,F401,F403
from soa_common.settings_base import COMMON_APPS, REST_FRAMEWORK  # noqa: E402

SERVICE_NAME = 'registry-service'
SERVICE_DESCRIPTION = 'Danh bạ dịch vụ: đăng ký, heartbeat và tra cứu địa chỉ service.'
SERVICE_PORT = int(os.environ.get('REGISTRY_SERVICE_PORT', '8010'))
# Registry không tự đăng ký với chính nó
SERVICE_AUTO_REGISTER = False

# Service không gửi heartbeat quá thời gian này bị coi là đã tắt
SERVICE_TTL_SECONDS = int(os.environ.get('SERVICE_TTL_SECONDS', '60'))

INSTALLED_APPS = COMMON_APPS + ['registry']

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}

REST_FRAMEWORK = {
    **REST_FRAMEWORK,
    'DEFAULT_AUTHENTICATION_CLASSES': [],
    'DEFAULT_PERMISSION_CLASSES': ['rest_framework.permissions.AllowAny'],
}

SPECTACULAR_SETTINGS = {'TITLE': 'ExpenseSnap Registry Service', 'VERSION': '1.0.0', 'SERVE_INCLUDE_SCHEMA': False}
