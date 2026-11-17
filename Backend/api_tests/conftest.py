"""Cấu hình chung cho bộ kiểm thử API ExpenseSnap (chạy qua API Gateway)."""
import io
import os
import time
import uuid
from pathlib import Path

import jwt
import pytest
import requests
from PIL import Image


def _load_env_file():
    f = Path(__file__).with_name('.env.test')
    if f.exists():
        for line in f.read_text(encoding='utf-8').splitlines():
            if line.strip() and not line.startswith('#') and '=' in line:
                k, v = line.split('=', 1)
                os.environ.setdefault(k.strip(), v.strip())


_load_env_file()
GATEWAY = os.environ.get('GATEWAY_URL', 'http://127.0.0.1:8000').rstrip('/')
SIGNING_KEY = os.environ.get('JWT_SIGNING_KEY', '')
TIMEOUT = 20


def make_token(user_id, token_type='access', lifetime=1800, key=None):
    """Tạo JWT giống auth-service (HS256, claim user_id) để test các service chỉ kiểm tra chữ ký."""
    now = int(time.time())
    payload = {'token_type': token_type, 'exp': now + lifetime, 'iat': now,
               'jti': uuid.uuid4().hex, 'user_id': str(user_id)}
    return jwt.encode(payload, key or SIGNING_KEY, algorithm='HS256')


def auth(token):
    return {'Authorization': f'Bearer {token}'}


def image_bytes(fmt='JPEG', size=(400, 600), color=(240, 240, 230)):
    buf = io.BytesIO()
    Image.new('RGB', size, color).save(buf, fmt)
    return buf.getvalue()


class Api:
    def __init__(self, base):
        self.base = base
        self.s = requests.Session()

    def __getattr__(self, method):
        def call(path, **kw):
            kw.setdefault('timeout', TIMEOUT)
            return self.s.request(method.upper(), self.base + path, **kw)
        return call


@pytest.fixture(scope='session')
def api():
    try:
        requests.get(GATEWAY + '/health/', timeout=5)
    except requests.RequestException:
        pytest.exit(f'Không kết nối được gateway {GATEWAY}. Hãy chạy Backend/run_services.ps1 trước.', 2)
    if not SIGNING_KEY:
        pytest.exit('Chưa đặt JWT_SIGNING_KEY (trùng Backend/.env).', 2)
    return Api(GATEWAY)


@pytest.fixture(scope='session')
def user_a():
    """Người dùng A: id ngẫu nhiên lớn để không đụng dữ liệu thật trong receipt DB."""
    uid = 900000 + int(time.time()) % 90000
    return {'id': uid, 'token': make_token(uid)}


@pytest.fixture(scope='session')
def user_b(user_a):
    uid = user_a['id'] + 1
    return {'id': uid, 'token': make_token(uid)}


@pytest.fixture(scope='session')
def real_user():
    """User có thật trong auth DB (TEST_USER_ID) – cần cho /me, /overview, refresh."""
    uid = os.environ.get('TEST_USER_ID')
    if not uid:
        pytest.skip('Chưa đặt TEST_USER_ID')
    return {'id': int(uid), 'token': make_token(uid), 'refresh': make_token(uid, 'refresh', 86400)}


@pytest.fixture
def uploaded(api, user_a):
    """Tải một ảnh hóa đơn của user A, tự xóa sau test."""
    r = api.post('/api/receipts/', headers=auth(user_a['token']),
                 files={'image': ('bill.jpg', image_bytes(), 'image/jpeg')})
    assert r.status_code == 201, r.text
    data = r.json()
    yield data
    api.delete(f"/api/receipts/{data['id']}/", headers=auth(user_a['token']))
