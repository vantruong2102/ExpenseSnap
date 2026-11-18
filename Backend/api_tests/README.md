# Kiểm thử tự động API – ExpenseSnap (Nhóm 5)

40 test case gọi **API Gateway** (`http://127.0.0.1:8000`) để kiểm thử auth-service, receipt-service và các tính chất SOA (định tuyến, 503 khi service tắt, JWT phi trạng thái, cô lập dữ liệu người dùng).

## Cách chạy

```powershell
# 1. Bật backend (thư mục Backend)
.\run_services.ps1 -Migrate

# 2. Cài thư viện test (dùng chung .venv của Backend cũng được)
cd api_tests
pip install -r requirements.txt

# 3. Cấu hình
copy .env.test.example .env.test   # sửa JWT_SIGNING_KEY cho trùng Backend/.env, TEST_USER_ID = id user có thật

# 4. Chạy và xuất báo cáo HTML
pytest -v --html=report.html --self-contained-html --junitxml=result.xml

# 5. Test chịu lỗi: tắt cửa sổ receipt_service :8002, chờ ~10 giây rồi
$env:RECEIPT_DOWN=1; pytest -v -k TC_GW_06
```

- `TEST_USER_ID`: đăng nhập app một lần rồi xem `id` trả về từ `GET /api/auth/me/` (hoặc Django shell của auth-service).
- Test cần Firebase (TC-AU-02, TC-AU-03, TC-AU-11) tự **Skip** khi auth-service chưa có `GOOGLE_APPLICATION_CREDENTIALS` hoặc chưa đặt `FIREBASE_WEB_API_KEY`, `TEST_EMAIL`, `TEST_PASSWORD`.
- TC-AU-99 (giới hạn 5 yêu cầu OTP/phút) làm cạn hạn mức của IP trong 1 phút; chạy lại cả bộ cần chờ 60 giây.
- Người dùng giả lập của receipt-service có `user_id` ≥ 900000 nên không đụng dữ liệu thật; mọi ảnh tải lên đều bị xóa sau test.

## Cấu trúc

| Tệp | Nội dung |
|---|---|
| `conftest.py` | Cấu hình, tạo JWT HS256 giống auth-service, fixture người dùng A/B, ảnh mẫu |
| `test_gateway.py` | TC-GW-01 → 08: danh mục service, health, OpenAPI, 404, overview, 503 khi tắt receipt-service |
| `test_auth.py` | TC-AU-01 → 13, 99: đăng nhập Firebase → JWT, /me, refresh, quên mật khẩu OTP, rate limit |
| `test_receipts.py` | TC-RC-01 → 18: upload JPG/PNG, kiểm tra ảnh, 10 MB, cô lập người dùng, xóa tệp, token hết hạn, hiệu năng |
