"""Cấu hình Django dùng chung. Mỗi service import file này rồi bổ sung phần riêng của mình.

Biến môi trường đọc từ Backend/.env (xem .env.example).
"""

import os
from datetime import timedelta
from pathlib import Path

from django.core.exceptions import ImproperlyConfigured
from dotenv import load_dotenv

BACKEND_DIR = Path(__file__).resolve().parent.parent

load_dotenv(BACKEND_DIR / '.env')


def env_bool(name, default='False'):
    return os.environ.get(name, default).lower() in ('true', '1', 'yes')


def env_list(name, default=''):
    return [item.strip() for item in os.environ.get(name, default).split(',') if item.strip()]


def require_env(name):
    value = os.environ.get(name)
    if not value:
        raise ImproperlyConfigured(f'{name} is not set. Copy .env.example to .env and fill it in.')
    return value


SECRET_KEY = require_env('DJANGO_SECRET_KEY')
DEBUG = env_bool('DJANGO_DEBUG')
ALLOWED_HOSTS = env_list('DJANGO_ALLOWED_HOSTS', '127.0.0.1,localhost')

COMMON_APPS = [
    'django.contrib.staticfiles',
    'rest_framework',
    'drf_spectacular',
    'soa_common',
]

# Không có SessionMiddleware: mọi service đều phi trạng thái (Statelessness), xác thực bằng JWT trong từng request
MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.middleware.common.CommonMiddleware',
]

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {'context_processors': ['django.template.context_processors.request']},
    },
]

WSGI_APPLICATION = 'config.wsgi.application'
ROOT_URLCONF = 'config.urls'
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

LANGUAGE_CODE = 'vi'
TIME_ZONE = 'Asia/Ho_Chi_Minh'
USE_I18N = True
USE_TZ = True

STATIC_URL = 'static/'

# Hợp đồng dịch vụ chuẩn hóa (Standardized Service Contract): mọi service dùng chung định dạng JSON,
# cùng cơ chế xác thực và tự sinh tài liệu OpenAPI 3 tại /api/schema/
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework_simplejwt.authentication.JWTStatelessUserAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
    'DEFAULT_RENDERER_CLASSES': ['rest_framework.renderers.JSONRenderer'],
    'DEFAULT_SCHEMA_CLASS': 'drf_spectacular.openapi.AutoSchema',
    'UNAUTHENTICATED_USER': None,
}

# Chỉ auth_service phát hành token; các service khác chỉ kiểm tra chữ ký bằng khóa chung
SIMPLE_JWT = {
    'SIGNING_KEY': require_env('JWT_SIGNING_KEY'),
    'ALGORITHM': 'HS256',
    'ACCESS_TOKEN_LIFETIME': timedelta(minutes=30),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=7),
    'AUTH_HEADER_TYPES': ('Bearer',),
}

SPECTACULAR_SETTINGS = {
    'VERSION': '1.0.0',
    'SERVE_INCLUDE_SCHEMA': False,
}

# Service Registry (Discoverability)
SERVICE_REGISTRY_URL = os.environ.get('SERVICE_REGISTRY_URL', 'http://127.0.0.1:8010')
SERVICE_REGISTRY_TOKEN = require_env('SERVICE_REGISTRY_TOKEN')
SERVICE_HOST = os.environ.get('SERVICE_HOST', '127.0.0.1')
SERVICE_HEARTBEAT_SECONDS = int(os.environ.get('SERVICE_HEARTBEAT_SECONDS', '20'))
