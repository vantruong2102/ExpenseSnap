# Kiến trúc SOA của ExpenseSnap

Backend ExpenseSnap được xây dựng theo **kiến trúc hướng dịch vụ (SOA)**. Mỗi nghiệp vụ là một service độc lập: chạy ở tiến trình và cổng riêng, có database riêng, và chỉ giao tiếp với service khác qua hợp đồng HTTP/JSON.

## 1. Sơ đồ tổng quan

```text
                    ┌───────────────────────────┐
  Flutter app ────► │  API Gateway        :8000 │──── tra cứu địa chỉ ───┐
  (mobile / web)    │  routing, /api/overview/  │                        ▼
                    └──────┬─────────────┬──────┘          ┌───────────────────────┐
                           │             │                 │ Registry Service :8010│
              /api/auth/*  │             │ /api/receipts/* │ danh bạ + heartbeat   │
                           ▼             ▼   /media/*      └───────────────────────┘
              ┌────────────────┐   ┌───────────────────┐        ▲          ▲
              │ Auth Service   │   │ Receipt Service   │        │ đăng ký  │
              │ :8001          │   │ :8002             │────────┘ + heartbeat
              │ accounts       │   │ receipts          │                   │
              │ db.sqlite3 (U) │   │ db.sqlite3 (R)    │                   │
              └───────┬────────┘   │ media/            │                   │
                      │            └───────────────────┘                   │
                      └────────────────────────────────────────────────────┘
          JWT do Auth ký ──► Receipt tự kiểm tra chữ ký, không cần gọi Auth
```

| Service | Cổng | Trách nhiệm | Dữ liệu sở hữu |
|---------|------|-------------|----------------|
| `api-gateway` | 8000 | Điểm vào duy nhất cho client; định tuyến; API tổng hợp `/api/overview/`; danh mục `/api/services/` | Không có |
| `auth-service` | 8001 | Đổi Firebase ID token lấy JWT (`/api/auth/firebase/`), làm mới token, `me`, quên mật khẩu bằng OTP qua email | Bảng User + liên kết Firebase UID |
| `receipt-service` | 8002 | Upload / liệt kê / xem / xóa / thống kê ảnh hóa đơn | Bảng Receipt + file ảnh |
| `registry-service` | 8010 | Service đăng ký, gửi heartbeat và tra cứu nhau | Bảng ServiceInstance |

Thư viện `soa_common/` chứa phần dùng chung: settings nền, client gọi registry, endpoint `/health/`, `/api/schema/`, `/api/docs/` và cơ chế heartbeat.

## 2. Áp dụng các nguyên tắc SOA

Bảng dưới đi theo 8 nguyên tắc thiết kế service của Thomas Erl. Danh sách "7 tính chất" trong giáo trình là tập con của 8 nguyên tắc này (tùy tài liệu, mục *Hợp đồng chuẩn hóa* hoặc *Khả năng kết hợp* được gộp vào mục khác).

| # | Nguyên tắc | Áp dụng trong ExpenseSnap | Code |
|---|-----------|---------------------------|------|
| 1 | **Hợp đồng dịch vụ chuẩn hóa** (Standardized Service Contract) | Mọi service dùng cùng chuẩn: REST + JSON, JWT `Bearer`, định dạng lỗi DRF (`{"detail": ...}` hoặc `{"<field>": [...]}`). Mỗi service tự sinh hợp đồng **OpenAPI 3** tại `/api/schema/` và trang Swagger tại `/api/docs/`. | `soa_common/settings_base.py` (`REST_FRAMEWORK`, `SPECTACULAR_SETTINGS`), `soa_common/views.py` |
| 2 | **Liên kết lỏng** (Loose Coupling) | Không service nào import code hay khóa ngoại sang database của service khác. `Receipt` chỉ lưu `user_id` (số nguyên) thay cho `ForeignKey(User)`. Gateway không biết địa chỉ cố định của service nào mà tra cứu lúc chạy. | `receipt_service/receipts/models.py`, `gateway/routing/client.py` |
| 3 | **Trừu tượng hóa** (Service Abstraction) | Client chỉ biết địa chỉ gateway và hợp đồng API, còn cổng nội bộ, database, nơi lưu file đều bị ẩn. Link ảnh trả về dùng host của gateway (`X-Forwarded-Host` + `USE_X_FORWARDED_HOST`), ảnh được phục vụ lại qua `/media/` của gateway. Gateway chỉ chuyển tiếp các header được phép. | `gateway/routing/views.py`, `receipt_service/config/settings.py` |
| 4 | **Tái sử dụng** (Service Reusability) | `auth-service` là dịch vụ xác thực chung: token nó phát hành được mọi service chấp nhận. `receipt-service` không phụ thuộc client nên Flutter, trang web hay admin đều gọi được. `/api/receipts/stats/` được dùng lại trong API tổng hợp. Thư viện `soa_common` được cả 4 service dùng chung. | `soa_common/`, `receipts/views.py` (`stats`) |
| 5 | **Tự trị** (Service Autonomy) | Mỗi service có `manage.py`, settings, database, migration và cổng riêng, khởi động và tắt độc lập. `receipt-service` tự kiểm tra JWT bằng khóa ký chung nên **vẫn chạy khi auth-service tắt**. Tắt `receipt-service` thì đăng nhập vẫn hoạt động, gateway chỉ trả `503` cho phần hóa đơn. | `services/*/config/settings.py`, `JWTStatelessUserAuthentication` |
| 6 | **Phi trạng thái** (Service Statelessness) | Không dùng session: đã bỏ `SessionMiddleware`. Mỗi request tự mang JWT. Gateway không có database. `receipt-service` nhận diện người dùng từ claim `user_id` trong token, không truy vấn bảng User. | `soa_common/settings_base.py` (`MIDDLEWARE`), `gateway/config/settings.py` (`DATABASES = {}`) |
| 7 | **Khả năng khám phá** (Service Discoverability) | Khi khởi động, service tự đăng ký với `registry-service` (tên, phiên bản, URL, link hợp đồng, mô tả) và gửi heartbeat mỗi 20 giây. Service quá 60 giây không gửi heartbeat bị coi là `DOWN` và không được trả về khi tra cứu. Có thể xem danh mục tại `GET /api/services/`. | `soa_common/apps.py`, `soa_common/registry_client.py`, `registry_service/registry/` |
| 8 | **Khả năng kết hợp** (Service Composability) | `GET /api/overview/` của gateway ghép `auth-service /api/auth/me/` với `receipt-service /api/receipts/stats/` thành một API mới (thông tin người dùng + số hóa đơn tổng và hôm nay). | `gateway/routing/views.py` (`OverviewView`) |

## 3. Đăng nhập với Firebase

Firebase Auth là **nơi duy nhất giữ mật khẩu** (email/mật khẩu, Google). Hệ thống chỉ có một tài khoản cho mỗi người:

```text
Flutter ──(1) đăng nhập / đăng ký──► Firebase Auth ──► Firebase ID token
Flutter ──(2) POST /api/auth/firebase/ {id_token}──► Gateway ──► auth-service
                       auth-service: verify_id_token() → tìm hoặc tạo User → trả JWT hệ thống
Flutter ──(3) Authorization: Bearer <JWT>──► Gateway ──► receipt-service (tự kiểm tra JWT)
```

- Chỉ `auth-service` biết tới Firebase, qua `soa_common/firebase.py`. Các service khác chỉ tin JWT nội bộ, nên muốn thay Firebase bằng nhà cung cấp khác thì chỉ phải sửa `auth-service` (Loose Coupling, Abstraction).
- User trong database có mật khẩu không dùng được (`set_unusable_password`). Bảng `FirebaseAccount` liên kết Firebase UID với User.
- Quên mật khẩu: auth-service gửi OTP qua Gmail SMTP, xác minh OTP, rồi đổi mật khẩu trên Firebase bằng Firebase Admin.
- JWT hết hạn (30 phút) thì app tự lấy Firebase ID token mới và đổi lại JWT (`ReceiptService` thử lại một lần khi gặp 401).
- Gateway chuyển tiếp `X-Forwarded-For`, nhờ đó giới hạn tần suất gửi OTP (3 lần/giờ) được tính theo IP của người dùng, không theo gateway.

Cần cấu hình trong `Backend/.env`: `GOOGLE_APPLICATION_CREDENTIALS` (file service account) và các biến `EMAIL_*`. Thiếu cấu hình thì các endpoint liên quan trả `503`.

## 4. Luồng một request

Ví dụ: upload ảnh hóa đơn `POST /api/receipts/`.

1. Flutter gửi request multipart kèm `Authorization: Bearer <access>` tới gateway `:8000`.
2. Gateway khớp tiền tố `api/receipts/` trong `GATEWAY_ROUTES` → service `receipt-service`.
3. Gateway hỏi registry `GET /registry/services/receipt-service/` → `http://127.0.0.1:8002`. Kết quả được cache 10 giây.
4. Gateway chuyển tiếp nguyên body và các header được phép, thêm `X-Forwarded-Host`.
5. `receipt-service` kiểm tra chữ ký JWT, lưu ảnh với `user_id` lấy từ token, rồi trả về link ảnh theo host của gateway.
6. Gateway trả response về Flutter. Nếu service không chạy, gateway trả `503 {"detail": "..."}`.

## 5. Chạy hệ thống

```powershell
cd Backend
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
copy .env.example .env      # điền các khóa, EMAIL_* và GOOGLE_APPLICATION_CREDENTIALS
.\run_services.ps1 -Migrate # lần đầu; các lần sau chỉ cần .\run_services.ps1
```

Script mở 4 cửa sổ, registry chạy trước. App chạy bằng `Frontendun_app.ps1`: với Android, script tự `adb reverse tcp:8000 tcp:8000` để app luôn gọi gateway ở `http://127.0.0.1:8000`.

| Kiểm tra | URL |
|---------|-----|
| Danh mục service | http://127.0.0.1:8000/api/services/ |
| Registry | http://127.0.0.1:8010/registry/services/ |
| Hợp đồng / Swagger từng service | `http://127.0.0.1:<cổng>/api/docs/` |
| Tình trạng service | `http://127.0.0.1:<cổng>/health/` |

Chạy test: vào từng thư mục `Backend/services/<service>/` rồi chạy `python manage.py test`.

## 6. Giới hạn hiện tại và hướng mở rộng

- JWT ký bằng HS256 với khóa chung `JWT_SIGNING_KEY`, nên service nào có khóa cũng tạo được token. Nếu cần chặt hơn, chuyển sang **RS256**: auth giữ private key, các service khác chỉ giữ public key.
- Registry chỉ có một bản, nếu tắt thì gateway vẫn dùng địa chỉ đã cache nhưng service mới không đăng ký được. Khi triển khai thật có thể thay bằng Consul hoặc Eureka.
- Mỗi service hiện chạy một instance. Registry lưu theo tên nên chưa cân bằng tải giữa nhiều instance.
- Sprint 2 (số tiền, danh mục, ghi chú cho hóa đơn) thuộc `receipt-service`. Nếu thêm báo cáo chi tiêu, có thể tách thành `report-service` và ghép vào gateway theo cùng cách với `/api/overview/`.
