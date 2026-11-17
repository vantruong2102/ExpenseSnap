"""SOA / API Gateway – NFR-05, NFR-09."""
import os

import pytest

from conftest import auth, make_token


def test_TC_GW_01_service_catalog_lists_services_up(api):
    """GET /api/services/ liệt kê gateway, auth, receipt với status UP."""
    r = api.get('/api/services/')
    assert r.status_code == 200
    names = {s['name']: s['status'] for s in r.json()}
    for name in ('api-gateway', 'auth-service', 'receipt-service'):
        assert names.get(name) == 'UP', names


def test_TC_GW_02_health_endpoint(api):
    r = api.get('/health/')
    assert r.status_code == 200


def test_TC_GW_03_openapi_contract_published(api):
    r = api.get('/api/schema/')
    assert r.status_code == 200
    assert 'openapi' in r.headers['content-type'] or r.text.lstrip().startswith('openapi')


def test_TC_GW_04_unknown_prefix_returns_404(api):
    assert api.get('/api/khong-ton-tai/').status_code == 404


def test_TC_GW_05_overview_requires_token(api):
    assert api.get('/api/overview/').status_code == 401


def test_TC_GW_07_overview_composes_auth_and_receipt(api, real_user):
    """US-23 (một phần): /api/overview/ ghép /me của auth-service và /stats của receipt-service."""
    r = api.get('/api/overview/', headers=auth(real_user['token']))
    assert r.status_code == 200, r.text
    body = r.json()
    assert body['user']['id'] == real_user['id']
    assert set(body['receipts']) == {'total', 'today'}


def test_TC_GW_08_forged_token_rejected_by_every_service(api):
    """NFR-02: token ký bằng khóa khác bị từ chối ở cả auth và receipt."""
    bad = make_token(1, key='khoa-gia-mao-0123456789abcdef0123')
    assert api.get('/api/auth/me/', headers=auth(bad)).status_code == 401
    assert api.get('/api/receipts/', headers=auth(bad)).status_code == 401


@pytest.mark.destructive
@pytest.mark.skipif(os.environ.get('RECEIPT_DOWN') != '1', reason='Chỉ chạy khi đã tắt receipt-service (RECEIPT_DOWN=1)')
def test_TC_GW_06_receipt_down_returns_503_and_auth_still_works(api, user_a):
    """NFR-05: dừng receipt-service → /api/receipts/ trả 503 tiếng Việt, /api/auth/ vẫn trả lời."""
    r = api.get('/api/receipts/', headers=auth(user_a['token']))
    assert r.status_code == 503
    assert 'receipt-service' in r.json()['detail']
    assert api.post('/api/auth/password-reset/request/', json={'email': 'sai'}).status_code in (400, 429)
