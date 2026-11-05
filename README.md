# ExpenseSnap

Ứng dụng quản lý chi tiêu cá nhân: chụp và lưu ảnh hóa đơn, theo dõi các khoản chi.

## Công nghệ

- **Frontend:** Flutter / Dart, Firebase Auth (email/mật khẩu, Google), Firestore và Firebase Storage (hồ sơ cá nhân)
- **Backend:** Python, Django, Django REST Framework, Simple JWT, Firebase Admin. Kiến trúc **SOA**, xem [docs/ARCHITECTURE_SOA.md](docs/ARCHITECTURE_SOA.md)

## Cấu trúc dự án

```text
ExpenseSnap/
├── Backend/
│   ├── soa_common/            # Thư viện dùng chung: settings nền, registry client, Firebase, /health/
│   ├── services/
│   │   ├── gateway/           # :8000 – điểm vào duy nhất của app
│   │   ├── auth_service/      # :8001 – tài khoản, JWT, quên mật khẩu
│   │   ├── receipt_service/   # :8002 – ảnh hóa đơn
│   │   └── registry_service/  # :8010 – danh bạ service
│   ├── run_services.ps1       # Khởi động cả 4 service
│   └── requirements.txt
├── Frontend/
│   ├── lib/                   # Mã nguồn Flutter
│   ├── test/
│   └── run_app.ps1            # Chạy app trên mọi thiết bị (tự cấu hình adb reverse)
└── docs/
```

## Yêu cầu

- Python 3.12 trở lên (nhóm đang dùng 3.14)
- Flutter 3.47, Android SDK (có `platform-tools`)
- Quyền truy cập Firebase project `expensesnap-bae4d`

## Cài đặt lần đầu

### 1. Backend

```powershell
cd Backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
Copy-Item .env.example .env
```

Nếu PowerShell báo *"running scripts is disabled"*: chạy `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`.

Điền `Backend/.env`:

| Biến | Giá trị |
|------|---------|
| `DJANGO_SECRET_KEY`, `JWT_SIGNING_KEY`, `SERVICE_REGISTRY_TOKEN` | Ba chuỗi ngẫu nhiên khác nhau: `python -c "import secrets; print(secrets.token_urlsafe(48))"` |
| `GOOGLE_APPLICATION_CREDENTIALS` | Đường dẫn file key Firebase Admin (Firebase Console → Project settings → Service accounts → Generate new private key). Để file **ngoài** repo, **không commit**. |
| `EMAIL_HOST_USER`, `EMAIL_HOST_PASSWORD`, `DEFAULT_FROM_EMAIL` | Gmail và App Password, dùng gửi OTP quên mật khẩu |

### 2. Frontend

```powershell
cd Frontend
flutter pub get
```

Muốn **đăng nhập Google** trên máy của mình thì thêm SHA-1 debug của máy vào Firebase (Project settings → app Android `com.example.frontend` → Add fingerprint), rồi tải lại `android/app/google-services.json`. Lấy SHA-1:

```powershell
keytool -list -v -alias androiddebugkey -keystore "$env:USERPROFILE\.android\debug.keystore" -storepass android -keypass android
```

## Chạy hằng ngày

**Terminal 1 – backend:**

```powershell
cd Backend
.\run_services.ps1            # thêm -Migrate khi lần đầu chạy hoặc khi có model mới
```

Script mở 4 cửa sổ, mỗi service một cửa sổ. Kiểm tra: <http://127.0.0.1:8000/api/services/> phải có 3 service ở trạng thái `UP`. Sửa `.env` thì phải đóng 4 cửa sổ và chạy lại.

**Terminal 2 – app:**

```powershell
cd Frontend
.\run_app.ps1                 # hoặc .\run_app.ps1 -d <id thiết bị>
```

Chạy được trên **máy ảo Android, điện thoại thật (USB hoặc Wi-Fi debug), web, Windows** mà không cần sửa gì. Với Android, script chạy `adb reverse tcp:8000 tcp:8000` để cổng 8000 trên thiết bị trỏ về laptop, nên app luôn gọi `http://127.0.0.1:8000`. Vì vậy không cần biết IP laptop, không cần mở tường lửa và không cần sửa `DJANGO_ALLOWED_HOSTS`.

- Nếu dùng `flutter run` trực tiếp thì phải chạy `adb reverse tcp:8000 tcp:8000` trước. Rút cáp hoặc khởi động lại adb thì phải chạy lại lệnh này.
- Cài APK cho người khác (không có adb): `flutter build apk --debug --dart-define=API_BASE_URL=http://<IP-laptop>:8000`. Khi đó cần thêm IP đó vào `DJANGO_ALLOWED_HOSTS` và mở cổng 8000 trên tường lửa.

## API (qua gateway, cổng 8000)

Xác thực bằng header `Authorization: Bearer <access>`. Hợp đồng đầy đủ của từng service xem tại `http://127.0.0.1:<cổng>/api/docs/`.

| Method | URL | Mô tả |
|--------|-----|-------|
| POST | `/api/auth/firebase/` | Đổi Firebase ID token (`id_token`, `full_name` tùy chọn) lấy user + JWT |
| POST | `/api/auth/token/refresh/` | Làm mới access token |
| GET | `/api/auth/me/` | Thông tin người dùng hiện tại |
| POST | `/api/auth/password-reset/request/` · `verify/` · `complete/` | Quên mật khẩu bằng OTP qua email |
| GET / POST | `/api/receipts/` | Danh sách / upload ảnh hóa đơn (multipart, trường `image`, tối đa 10MB) |
| GET / DELETE | `/api/receipts/<id>/` | Xem / xóa ảnh hóa đơn |
| GET | `/api/receipts/stats/` | Số hóa đơn tổng và hôm nay |
| GET | `/api/overview/` | API tổng hợp: thông tin người dùng + thống kê hóa đơn |
| GET | `/api/services/` | Danh mục service đang chạy |

## Kiểm thử

```powershell
# Backend: chạy trong từng thư mục Backend/services/<service>/
python manage.py test

# Frontend
cd Frontend
flutter analyze
flutter test
```

## Lỗi thường gặp

| Hiện tượng | Cách xử lý |
|------------|-----------|
| Đăng nhập/đăng ký xong bị đăng xuất ngay | Đọc thông báo cuối màn hình. Thường do thiếu file key Firebase, backend chưa chạy, hoặc chưa `adb reverse` |
| *"Token used too early … clock"* | Đồng hồ máy chạy backend bị lệch: bật Settings → Time & language → Set time automatically → Sync now |
| *"Không kết nối được máy chủ"* | Backend chưa chạy, hoặc thiếu `adb reverse` (dùng `run_app.ps1`) |
| *"Dịch vụ … tạm thời không khả dụng"* | Một trong 4 cửa sổ service bị tắt hoặc đang báo lỗi |
| Google: `[16] Account reauth failed` | Chưa thêm SHA-1 của máy vào Firebase |
| `flutter run` không thấy điện thoại | `adb devices`. Nếu `unauthorized` thì bấm Cho phép trên điện thoại; nếu `offline` thì `adb kill-server` rồi cắm lại cáp |

Quy ước code, đặt tên nhánh và quy trình Git: [CODINGCONVENTION.md](CODINGCONVENTION.md).
