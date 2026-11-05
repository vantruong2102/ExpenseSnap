"""Receipt Service: lưu và quản lý ảnh hóa đơn. Có database và thư mục media riêng (Autonomy)."""

import os
import sys
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent
sys.path.append(str(BASE_DIR.parent.parent))

from soa_common.settings_base import *  # noqa: E402,F401,F403
from soa_common.settings_base import COMMON_APPS, env_bool  # noqa: E402

SERVICE_NAME = 'receipt-service'
SERVICE_DESCRIPTION = 'Upload, liệt kê, xem, xóa và thống kê ảnh hóa đơn của người dùng.'
SERVICE_PORT = int(os.environ.get('RECEIPT_SERVICE_PORT', '8002'))
SERVICE_AUTO_REGISTER = env_bool('SERVICE_AUTO_REGISTER', 'True')

# auth/contenttypes chỉ có mặt vì Simple JWT cần import chúng. Service không đọc bảng User:
# người dùng được nhận diện bằng user_id trong JWT đã ký (JWTStatelessUserAuthentication)
INSTALLED_APPS = COMMON_APPS + ['django.contrib.contenttypes', 'django.contrib.auth', 'receipts']

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}

MEDIA_URL = 'media/'
MEDIA_ROOT = BASE_DIR / 'media'

# Request đi qua API Gateway: URL ảnh trả về phải mang địa chỉ gateway, không lộ địa chỉ nội bộ (Abstraction)
USE_X_FORWARDED_HOST = True

SPECTACULAR_SETTINGS = {'TITLE': 'ExpenseSnap Receipt Service', 'VERSION': '1.0.0', 'SERVE_INCLUDE_SCHEMA': False}
