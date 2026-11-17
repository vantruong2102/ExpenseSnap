"""auth-service qua gateway – US-01, US-02, US-03, US-06, NFR-02, NFR-03."""
import os

import pytest
import requests

from conftest import auth, make_token


def skip_if_firebase_missing(r):
    if r.status_code == 503 and 'Firebase Admin' in r.text:
        pytest.skip('auth-service chưa cấu hình Firebase Admin (GOOGLE_APPLICATION_CREDENTIALS) – chạy lại trên máy có service account')

FB = 'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key='


def test_TC_AU_01_firebase_login_requires_id_token(api):
    r = api.post('/api/auth/firebase/', json={})
    assert r.status_code == 400
    assert 'id_token' in r.json()


def test_TC_AU_02_firebase_login_rejects_fake_id_token(api):
    """US-02: ID token giả không được cấp JWT (400/401). 503 nếu auth-service chưa cấu hình Firebase Admin."""
    r = api.post('/api/auth/firebase/', json={'id_token': 'gia-mao'})
    skip_if_firebase_missing(r)
    assert r.status_code in (400, 401), f'{r.status_code} {r.text[:200]}'


@pytest.mark.firebase
@pytest.mark.skipif(not os.environ.get('FIREBASE_WEB_API_KEY'), reason='Chưa cấu hình tài khoản Firebase test')
def test_TC_AU_03_firebase_login_returns_jwt(api):
    """US-02: đăng nhập Firebase thật → /api/auth/firebase/ trả user, access, refresh; access dùng được cho /me."""
    fb = requests.post(FB + os.environ['FIREBASE_WEB_API_KEY'], json={
        'email': os.environ['TEST_EMAIL'], 'password': os.environ['TEST_PASSWORD'], 'returnSecureToken': True}, timeout=20)
    assert fb.status_code == 200, fb.text
    r = api.post('/api/auth/firebase/', json={'id_token': fb.json()['idToken']})
    assert r.status_code == 200, r.text
    body = r.json()
    assert {'user', 'access', 'refresh'} <= set(body)
    me = api.get('/api/auth/me/', headers=auth(body['access']))
    assert me.status_code == 200 and me.json()['email'] == os.environ['TEST_EMAIL'].lower()


def test_TC_AU_04_me_requires_token(api):
    assert api.get('/api/auth/me/').status_code == 401


def test_TC_AU_05_me_rejects_expired_token(api, real_user):
    expired = make_token(real_user['id'], lifetime=-60)
    assert api.get('/api/auth/me/', headers=auth(expired)).status_code == 401


def test_TC_AU_06_me_returns_profile(api, real_user):
    r = api.get('/api/auth/me/', headers=auth(real_user['token']))
    assert r.status_code == 200
    assert {'id', 'email', 'full_name', 'date_joined'} <= set(r.json())


def test_TC_AU_07_refresh_returns_new_access(api, real_user):
    """US-06: refresh token hợp lệ → access mới dùng được."""
    r = api.post('/api/auth/token/refresh/', json={'refresh': real_user['refresh']})
    assert r.status_code == 200, r.text[:200]
    assert api.get('/api/auth/me/', headers=auth(r.json()['access'])).status_code == 200


def test_TC_AU_08_refresh_rejects_garbage(api):
    assert api.post('/api/auth/token/refresh/', json={'refresh': 'abc'}).status_code == 401


def test_TC_AU_09_refresh_for_deleted_user_is_401_not_500(api):
    """US-06: refresh token của user không còn tồn tại phải bị từ chối (401), không được gây lỗi 500."""
    r = api.post('/api/auth/token/refresh/', json={'refresh': make_token(987654321, 'refresh', 3600)})
    assert r.status_code == 401, f'Nhận {r.status_code}'


def test_TC_AU_10_reset_request_rejects_invalid_email(api):
    """US-03: email sai định dạng → 400 kèm lỗi trường email."""
    r = api.post('/api/auth/password-reset/request/', json={'email': 'khong-phai-email'})
    assert r.status_code == 400
    assert 'email' in r.json()


def test_TC_AU_11_reset_request_unknown_email_same_answer(api):
    """US-03: email chưa đăng ký nhận cùng câu trả lời 200 (không lộ tài khoản). 503 nếu chưa cấu hình Firebase Admin."""
    r = api.post('/api/auth/password-reset/request/', json={'email': 'chua-dang-ky-qa@example.com'})
    skip_if_firebase_missing(r)
    assert r.status_code == 200, f'{r.status_code} {r.text[:200]}'


def test_TC_AU_12_reset_verify_rejects_wrong_otp(api):
    r = api.post('/api/auth/password-reset/verify/', json={'email': 'chua-dang-ky-qa@example.com', 'otp': '000000'})
    assert r.status_code == 400
    assert 'otp' in r.json()


def test_TC_AU_13_reset_complete_rejects_invalid_token(api):
    r = api.post('/api/auth/password-reset/complete/', json={'reset_token': 'gia', 'password': 'MatKhau@2026'})
    assert r.status_code == 400
    assert 'reset_token' in r.json()


def test_TC_AU_99_reset_request_is_rate_limited(api):
    """NFR-03: quá 5 yêu cầu OTP/phút từ một IP → 429. (Chạy cuối vì làm cạn hạn mức của IP.)"""
    codes = [api.post('/api/auth/password-reset/request/', json={'email': 'x'}).status_code for _ in range(7)]
    assert 429 in codes, codes
