"""API Gateway: điểm vào duy nhất của ứng dụng Flutter.

Gateway không có database và không giữ phiên đăng nhập (Statelessness). Nó tra địa chỉ service trong
registry (Discoverability), chuyển tiếp request (Abstraction) và ghép nhiều service thành API mới (Composability).
"""

import os
import sys
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent
sys.path.append(str(BASE_DIR.parent.parent))

from soa_common.settings_base import *  # noqa: E402,F401,F403
from soa_common.settings_base import COMMON_APPS, MIDDLEWARE, REST_FRAMEWORK, env_bool  # noqa: E402

SERVICE_NAME = 'api-gateway'
SERVICE_DESCRIPTION = 'Điểm vào duy nhất: định tuyến request tới service và cung cấp API tổng hợp.'
SERVICE_PORT = int(os.environ.get('GATEWAY_PORT', '8000'))
SERVICE_AUTO_REGISTER = env_bool('SERVICE_AUTO_REGISTER', 'True')

INSTALLED_APPS = COMMON_APPS + ['corsheaders', 'routing']

MIDDLEWARE = ['corsheaders.middleware.CorsMiddleware', *MIDDLEWARE]

DATABASES = {}

# Bảng định tuyến: tiền tố URL -> tên service trong registry. Thêm service mới chỉ cần thêm một dòng ở đây.
GATEWAY_ROUTES = [
    ('api/auth/', 'auth-service'),
    ('api/receipts/', 'receipt-service'),
    ('media/', 'receipt-service'),
]
GATEWAY_TIMEOUT_SECONDS = int(os.environ.get('GATEWAY_TIMEOUT_SECONDS', '20'))

# Gateway đọc nguyên body để chuyển tiếp, nên phải cho phép tối đa bằng kích thước ảnh hóa đơn (10MB) + phần dư
DATA_UPLOAD_MAX_MEMORY_SIZE = 12 * 1024 * 1024

# Gateway không tự xác thực: mỗi service tự kiểm tra JWT của mình
REST_FRAMEWORK = {
    **REST_FRAMEWORK,
    'DEFAULT_AUTHENTICATION_CLASSES': [],
    'DEFAULT_PERMISSION_CLASSES': ['rest_framework.permissions.AllowAny'],
}

# Flutter web chạy trên cổng localhost ngẫu nhiên khi phát triển
CORS_ALLOW_ALL_ORIGINS = DEBUG

SPECTACULAR_SETTINGS = {'TITLE': 'ExpenseSnap API Gateway', 'VERSION': '1.0.0', 'SERVE_INCLUDE_SCHEMA': False}
