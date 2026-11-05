"""Auth Service: quản lý tài khoản người dùng và phát hành JWT. Có database riêng (Autonomy)."""

import os
import sys
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent
sys.path.append(str(BASE_DIR.parent.parent))

from soa_common.settings_base import *  # noqa: E402,F401,F403
from soa_common.settings_base import COMMON_APPS, REST_FRAMEWORK, env_bool  # noqa: E402

SERVICE_NAME = 'auth-service'
SERVICE_DESCRIPTION = 'Đăng ký, đăng nhập, làm mới token và xem thông tin người dùng.'
SERVICE_PORT = int(os.environ.get('AUTH_SERVICE_PORT', '8001'))
SERVICE_AUTO_REGISTER = env_bool('SERVICE_AUTO_REGISTER', 'True')

INSTALLED_APPS = COMMON_APPS + [
    'django.contrib.contenttypes',
    'django.contrib.auth',
    'rest_framework_simplejwt',
    'accounts',
]

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}

AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]

# Service sở hữu bảng User nên kiểm tra token có đối chiếu với database (tài khoản bị khóa sẽ bị từ chối)
REST_FRAMEWORK = {
    **REST_FRAMEWORK,
    'DEFAULT_AUTHENTICATION_CLASSES': ['rest_framework_simplejwt.authentication.JWTAuthentication'],
    # Request đi qua API Gateway: lấy IP thật của client từ X-Forwarded-For để giới hạn tần suất (throttle) đúng người
    'NUM_PROXIES': 1,
}

# Email (gửi OTP quên mật khẩu). Thông tin Gmail SMTP đặt trong Backend/.env
EMAIL_BACKEND = os.environ.get('EMAIL_BACKEND', 'django.core.mail.backends.smtp.EmailBackend')
EMAIL_HOST = os.environ.get('EMAIL_HOST', 'smtp.gmail.com')
EMAIL_PORT = int(os.environ.get('EMAIL_PORT', '587'))
EMAIL_USE_TLS = env_bool('EMAIL_USE_TLS', 'True')
EMAIL_HOST_USER = os.environ.get('EMAIL_HOST_USER', '')
EMAIL_HOST_PASSWORD = os.environ.get('EMAIL_HOST_PASSWORD', '')
DEFAULT_FROM_EMAIL = os.environ.get('DEFAULT_FROM_EMAIL', EMAIL_HOST_USER)
EMAIL_DISPLAY_NAME = os.environ.get('EMAIL_DISPLAY_NAME', 'ExpenseSnap')

# OTP và bộ đếm throttle lưu trong bộ nhớ tiến trình: khởi động lại auth-service thì OTP đang chờ bị mất.
# Khi chạy nhiều tiến trình cần chuyển sang cache dùng chung (Redis hoặc DatabaseCache).
CACHES = {'default': {'BACKEND': 'django.core.cache.backends.locmem.LocMemCache'}}

SPECTACULAR_SETTINGS = {'TITLE': 'ExpenseSnap Auth Service', 'VERSION': '1.0.0', 'SERVE_INCLUDE_SCHEMA': False}
