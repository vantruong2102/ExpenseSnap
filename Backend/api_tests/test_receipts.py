"""receipt-service qua gateway – US-09, US-11, US-12, US-16, US-17, US-18, US-23, NFR-01, NFR-02, NFR-06."""
import io
import os
import statistics
import time
from urllib.parse import urlparse

import pytest
from PIL import Image

from conftest import GATEWAY, auth, image_bytes, make_token


def upload(api, user, data=None, name='bill.jpg', ctype='image/jpeg'):
    return api.post('/api/receipts/', headers=auth(user['token']),
                    files={'image': (name, data if data is not None else image_bytes(), ctype)})


def test_TC_RC_01_list_requires_token(api):
    assert api.get('/api/receipts/').status_code == 401


def test_TC_RC_02_upload_jpg_returns_201_with_gateway_url(api, user_a):
    """US-12, US-16: tải JPG → 201; URL ảnh dùng host của gateway, không lộ cổng 8002."""
    r = upload(api, user_a)
    assert r.status_code == 201, r.text
    body = r.json()
    assert {'id', 'image', 'created_at'} <= set(body)
    assert urlparse(body['image']).netloc == urlparse(GATEWAY).netloc
    assert f"/media/receipts/{user_a['id']}/" in body['image']
    api.delete(f"/api/receipts/{body['id']}/", headers=auth(user_a['token']))


def test_TC_RC_03_upload_png(api, user_a):
    r = upload(api, user_a, image_bytes('PNG'), 'bill.png', 'image/png')
    assert r.status_code == 201
    assert r.json()['image'].endswith('.png')
    api.delete(f"/api/receipts/{r.json()['id']}/", headers=auth(user_a['token']))


def test_TC_RC_04_upload_rejects_non_image(api, user_a):
    r = upload(api, user_a, b'day khong phai anh', 'bill.jpg', 'image/jpeg')
    assert r.status_code == 400 and 'image' in r.json()


def test_TC_RC_05_upload_rejects_missing_file(api, user_a):
    r = api.post('/api/receipts/', headers=auth(user_a['token']), data={})
    assert r.status_code == 400 and 'image' in r.json()


@pytest.mark.slow
def test_TC_RC_06_upload_rejects_image_over_10mb(api, user_a):
    """NFR-06: ảnh hợp lệ nhưng > 10 MB → 400 'không được vượt quá 10MB'."""
    buf = io.BytesIO()
    Image.frombytes('RGB', (2000, 1800), os.urandom(2000 * 1800 * 3)).save(buf, 'PNG', compress_level=0)
    assert buf.tell() > 10 * 1024 * 1024
    r = upload(api, user_a, buf.getvalue(), 'big.png', 'image/png')
    assert r.status_code == 400, r.status_code
    assert '10MB' in r.json()['image'][0]


def test_TC_RC_07_filename_cannot_escape_user_folder(api, user_a):
    """NFR-02: tên tệp chứa ../ vẫn được lưu trong receipts/{user_id}/ với tên uuid."""
    r = upload(api, user_a, name='../../../evil.jpg')
    assert r.status_code == 201
    path = urlparse(r.json()['image']).path
    assert '..' not in path and 'evil' not in path and path.startswith(f"/media/receipts/{user_a['id']}/")
    api.delete(f"/api/receipts/{r.json()['id']}/", headers=auth(user_a['token']))


def test_TC_RC_08_list_returns_own_receipts_newest_first(api, user_a, user_b):
    """US-09, NFR-02: danh sách chỉ chứa hóa đơn của mình, mới nhất trước."""
    ids = []
    for _ in range(2):
        ids.append(upload(api, user_a).json()['id'])
        time.sleep(0.05)
    other = upload(api, user_b).json()['id']
    data = api.get('/api/receipts/', headers=auth(user_a['token'])).json()
    got = [x['id'] for x in data]
    assert other not in got
    assert got.index(ids[1]) < got.index(ids[0])
    for i in ids:
        api.delete(f'/api/receipts/{i}/', headers=auth(user_a['token']))
    api.delete(f'/api/receipts/{other}/', headers=auth(user_b['token']))


def test_TC_RC_09_detail_own_receipt(api, user_a, uploaded):
    r = api.get(f"/api/receipts/{uploaded['id']}/", headers=auth(user_a['token']))
    assert r.status_code == 200 and r.json()['id'] == uploaded['id']


def test_TC_RC_10_detail_other_users_receipt_is_404(api, user_b, uploaded):
    assert api.get(f"/api/receipts/{uploaded['id']}/", headers=auth(user_b['token'])).status_code == 404


def test_TC_RC_11_image_served_through_gateway(api, uploaded):
    """US-18: tải ảnh qua /media/ của gateway."""
    r = api.get(urlparse(uploaded['image']).path)
    assert r.status_code == 200
    assert r.headers['content-type'].startswith('image/')


def test_TC_RC_12_stats_counts_total_and_today(api, user_a):
    """US-23 (một phần): /stats/ tăng đúng 1 sau khi tải ảnh."""
    before = api.get('/api/receipts/stats/', headers=auth(user_a['token'])).json()
    rid = upload(api, user_a).json()['id']
    after = api.get('/api/receipts/stats/', headers=auth(user_a['token'])).json()
    assert after['total'] == before['total'] + 1 and after['today'] == before['today'] + 1
    api.delete(f'/api/receipts/{rid}/', headers=auth(user_a['token']))


def test_TC_RC_13_cannot_delete_other_users_receipt(api, user_b, uploaded):
    assert api.delete(f"/api/receipts/{uploaded['id']}/", headers=auth(user_b['token'])).status_code == 404


def test_TC_RC_14_delete_removes_record_and_file(api, user_a):
    """US-11, US-17: xóa → 204; bản ghi và tệp ảnh đều không còn."""
    body = upload(api, user_a).json()
    media = urlparse(body['image']).path
    assert api.get(media).status_code == 200
    assert api.delete(f"/api/receipts/{body['id']}/", headers=auth(user_a['token'])).status_code == 204
    assert api.get(f"/api/receipts/{body['id']}/", headers=auth(user_a['token'])).status_code == 404
    assert api.get(media).status_code == 404


def test_TC_RC_15_expired_token_rejected(api, user_a):
    assert api.get('/api/receipts/', headers=auth(make_token(user_a['id'], lifetime=-5))).status_code == 401


def test_TC_RC_16_refresh_token_cannot_be_used_as_access(api, user_a):
    """NFR-02: refresh token (token_type=refresh) không được dùng thay access token."""
    r = api.get('/api/receipts/', headers=auth(make_token(user_a['id'], 'refresh', 3600)))
    assert r.status_code == 401


def test_TC_RC_17_update_not_supported_yet(api, user_a, uploaded):
    """US-10 chưa cài đặt: PATCH trả 405 (ghi nhận trạng thái, không phải lỗi)."""
    r = api.patch(f"/api/receipts/{uploaded['id']}/", headers=auth(user_a['token']), json={'note': 'x'})
    assert r.status_code == 405


@pytest.mark.slow
def test_TC_RC_18_list_response_time(api, user_a):
    """NFR-01: 20 lần GET /api/receipts/ qua gateway, p95 ≤ 1 giây."""
    times = []
    for _ in range(20):
        t = time.perf_counter()
        assert api.get('/api/receipts/', headers=auth(user_a['token'])).status_code == 200
        times.append(time.perf_counter() - t)
    p95 = statistics.quantiles(times, n=20)[18]
    print(f'p95={p95 * 1000:.0f} ms, trung bình={statistics.mean(times) * 1000:.0f} ms')
    assert p95 <= 1.0
