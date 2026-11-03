# Quy ước viết code – ExpenseSnap

Tài liệu này quy định cách viết code, đặt tên nhánh, commit và quy trình đưa code lên Git cho tất cả thành viên trong dự án **ExpenseSnap**. Mọi thành viên phải đọc và tuân thủ trước khi bắt đầu code.

Dự án gồm hai phần:

| Phần | Công nghệ | Thư mục |
|------|-----------|---------|
| Backend | Python, Django, Django REST Framework, Simple JWT, Firebase Admin | `Backend/` |
| Frontend | Flutter / Dart, Firebase | `Frontend/` |

---

## 1. Quy tắc chung

- Code, tên biến, tên hàm, tên class viết bằng **tiếng Anh**. Comment và tài liệu có thể viết tiếng Việt (có dấu).
- Encoding file: **UTF-8**, xuống dòng kiểu **LF**.
- Không commit thông tin nhạy cảm: `SECRET_KEY`, mật khẩu, API key, file `google-services.json`, `GoogleService-Info.plist`, file service account của Firebase, file `.env`.
- Không commit file sinh ra tự động hoặc dữ liệu cục bộ: `.venv/`, `__pycache__/`, `db.sqlite3`, `build/`, `.dart_tool/`, `.idea/`, `.vscode/` (trừ khi cả nhóm thống nhất).
- Không để lại code chết, code bị comment, `print()` dùng để debug khi tạo Pull Request.
- Mỗi hàm chỉ làm **một việc**; hàm dài quá ~50 dòng nên tách nhỏ.
- Không hard-code chuỗi URL, key, cấu hình — đưa vào biến môi trường (backend) hoặc file hằng số (frontend).

---

## 2. Quy ước cho Backend (Python / Django)

### 2.1. Phong cách code

- Tuân theo **PEP 8**. Thụt lề **4 dấu cách**, không dùng tab.
- Độ dài dòng tối đa **120 ký tự**.
- Dùng **dấu nháy đơn** `'...'` cho chuỗi (giống code Django hiện có trong `config/settings.py`).
- Thứ tự import: thư viện chuẩn → thư viện bên thứ ba → module trong dự án, mỗi nhóm cách nhau một dòng trống.

```python
from datetime import date

from django.db import models
from rest_framework import serializers

from transactions.models import Transaction
```

### 2.2. Đặt tên

| Thành phần | Quy tắc | Ví dụ |
|-----------|---------|-------|
| Module / file | `snake_case` | `serializers.py`, `receipt_utils.py` |
| Biến, hàm, method | `snake_case` | `total_amount`, `get_monthly_report()` |
| Class, Model, Serializer, View | `PascalCase` | `Transaction`, `TransactionSerializer`, `TransactionViewSet` |
| Hằng số | `UPPER_SNAKE_CASE` | `MAX_RECEIPT_SIZE_MB` |
| Django app | danh từ số nhiều, chữ thường | `transactions`, `categories`, `users` |
| Trường model | `snake_case`, rõ nghĩa | `created_at`, `receipt_image_url` |
| URL | chữ thường, gạch ngang, danh từ số nhiều | `/api/transactions/`, `/api/monthly-reports/` |

### 2.3. Cấu trúc một Django app

```text
transactions/
├── migrations/
├── __init__.py
├── admin.py          # Đăng ký model với Django admin
├── apps.py
├── models.py         # Định nghĩa model
├── serializers.py    # Serializer của DRF
├── views.py          # ViewSet / APIView
├── urls.py           # Router của app, được include vào config/urls.py
└── tests.py          # Hoặc thư mục tests/ khi có nhiều test
```

- Mọi app mới phải được khai báo trong `INSTALLED_APPS` ở `config/settings.py`.
- URL của từng app khai báo trong `<app>/urls.py`, sau đó `include()` vào `config/urls.py` dưới tiền tố `api/`.
- Model nên có `__str__()` và `class Meta` (ít nhất `ordering`) khi cần.
- API dùng **Django REST Framework**, xác thực bằng **Simple JWT**; ưu tiên `ModelViewSet` + `DefaultRouter` cho CRUD.

### 2.4. Migration

- Sau khi sửa model: chạy `python manage.py makemigrations` và **commit file migration** cùng với thay đổi model.
- Không sửa migration đã được merge vào `develop`. Muốn thay đổi thì tạo migration mới.
- Nếu bị conflict migration khi merge, báo nhóm trưởng trước khi xử lý.

### 2.5. Cấu hình và bảo mật

- `SECRET_KEY`, `DEBUG`, `ALLOWED_HOSTS`, thông tin database, đường dẫn file Firebase đọc từ biến môi trường qua `python-dotenv` (file `.env`, **không commit**). Commit file mẫu `.env.example` chứa tên biến, không chứa giá trị thật.
- Khi cài thêm thư viện: `pip install <gói>` rồi cập nhật `requirements.txt` (`pip freeze > requirements.txt`) trong cùng commit.

---

## 3. Quy ước cho Frontend (Flutter / Dart)

### 3.1. Phong cách code

- Tuân theo [Effective Dart](https://dart.dev/effective-dart/style) và bộ lint `flutter_lints` đã cấu hình trong `analysis_options.yaml`.
- Thụt lề **2 dấu cách**.
- Luôn format bằng `dart format .` trước khi commit.
- `flutter analyze` phải **không còn lỗi và cảnh báo** trước khi tạo Pull Request.
- Thêm dấu phẩy cuối (trailing comma) ở danh sách tham số/widget nhiều dòng để `dart format` xuống dòng đẹp.
- Dùng `const` constructor ở mọi chỗ có thể.
- Không dùng `print()`; dùng `debugPrint()` khi thật sự cần và xoá trước khi merge.

### 3.2. Đặt tên

| Thành phần | Quy tắc | Ví dụ |
|-----------|---------|-------|
| File, thư mục | `snake_case` | `transaction_list_screen.dart` |
| Class, Widget, Enum | `PascalCase` | `TransactionListScreen`, `ExpenseCategory` |
| Biến, hàm, tham số | `camelCase` | `totalAmount`, `fetchTransactions()` |
| Hằng số | `camelCase` (theo chuẩn Dart) | `const defaultPadding = 16.0;` |
| Thành phần private | tiền tố `_` | `_counter`, `_loadData()` |
| Màn hình | hậu tố `Screen` | `LoginScreen`, `AddExpenseScreen` |
| Widget dùng lại | tên mô tả, không hậu tố | `ExpenseCard`, `CategoryChip` |
| Service gọi API / Firebase | hậu tố `Service` | `AuthService`, `TransactionService` |
| Model dữ liệu | danh từ số ít | `Transaction`, `Category` |

### 3.3. Cấu trúc thư mục `lib/`

```text
lib/
├── main.dart              # Điểm khởi chạy, chỉ cấu hình app và route
├── core/
│   ├── constants/         # Màu sắc, kích thước, URL API, chuỗi cố định
│   ├── theme/             # ThemeData
│   └── utils/             # Hàm tiện ích (định dạng tiền, ngày tháng...)
├── models/                # Lớp dữ liệu + fromJson / toJson
├── services/              # Gọi API backend (http), Firebase Auth/Firestore/Storage
├── screens/               # Mỗi màn hình một thư mục con
│   └── home/
│       ├── home_screen.dart
│       └── widgets/       # Widget chỉ dùng trong màn hình này
└── widgets/               # Widget dùng chung nhiều màn hình
```

- Mỗi file chỉ chứa **một widget public** chính.
- Widget dài (hàm `build` > ~80 dòng) phải tách thành widget con.
- Không gọi `http` hoặc Firebase trực tiếp trong widget; gọi qua lớp trong `services/`.
- URL backend đặt trong `core/constants/`, không viết rải rác.
- Test đặt trong `test/`, tên file kết thúc bằng `_test.dart`.

---

## 4. Quy tắc đặt tên nhánh

### 4.1. Các nhánh chính

| Nhánh | Mục đích | Ai được merge vào |
|-------|----------|-------------------|
| `main` | Code **ổn định**, đã kiểm thử, dùng để nộp/demo | Chỉ nhóm trưởng, qua Pull Request từ `develop` |
| `develop` | Nhánh tích hợp, gộp code của tất cả thành viên | Qua Pull Request từ các nhánh `dev_<tên>` |

> **Tuyệt đối không push trực tiếp lên `main` và `develop`.** Mọi thay đổi phải đi qua Pull Request (Merge Request).

### 4.2. Nhánh cá nhân

Mỗi thành viên được giao nhiệm vụ làm việc trên nhánh riêng, đặt tên theo mẫu:

```text
dev_<tên>
```

- `<tên>` là tên của thành viên, viết **chữ thường, không dấu, không khoảng trắng**.
- Nếu trùng tên, thêm chữ cái đầu của họ và tên đệm: `dev_truong_nv`.
- Nhánh cá nhân luôn được tạo từ **`develop`** (không tạo từ `main`).

Ví dụ:

| Thành viên | Tên nhánh |
|-----------|-----------|
| Nguyễn Văn Trường | `dev_truong` |
| Trần Thị Lan | `dev_lan` |
| Lê Minh An / Phạm Thu An | `dev_an_lm` / `dev_an_pt` |

---

## 5. Quy ước commit message

Viết theo dạng:

```text
<loại>(<phạm vi>): <mô tả ngắn>
```

| Loại | Dùng khi |
|------|----------|
| `feat` | Thêm chức năng mới |
| `fix` | Sửa lỗi |
| `refactor` | Sửa cấu trúc code, không đổi chức năng |
| `style` | Format, đổi tên, không ảnh hưởng logic |
| `docs` | Sửa tài liệu, README |
| `test` | Thêm/sửa test |
| `chore` | Cập nhật thư viện, cấu hình, `.gitignore` |

- `<phạm vi>`: `backend`, `frontend`, hoặc tên module (`transactions`, `auth`...).
- Mô tả ngắn gọn, tối đa ~72 ký tự, có thể viết tiếng Việt.
- Mỗi commit chỉ chứa **một thay đổi có ý nghĩa**. Không dùng các message chung chung như `update`, `fix`, `abc`.

Ví dụ:

```text
feat(backend): thêm API CRUD cho giao dịch
fix(frontend): sửa lỗi không hiển thị ảnh hóa đơn
chore(backend): cập nhật requirements.txt
```

---

## 6. Quy trình làm việc với Git

Sơ đồ tổng quát:

```text
dev_<tên>  ──PR──▶  develop  ──(kiểm thử toàn bộ, không còn lỗi)──PR──▶  main
```

### Bước 1 – Lấy code mới nhất và tạo nhánh cá nhân (làm một lần)

```bash
git clone https://github.com/vantruong2102/ExpenseSnap.git
cd ExpenseSnap
git checkout develop
git pull origin develop
git checkout -b dev_<tên>
git push -u origin dev_<tên>
```

### Bước 2 – Code trên nhánh cá nhân

Trước mỗi buổi làm việc, cập nhật code mới nhất từ `develop` vào nhánh của mình:

```bash
git checkout dev_<tên>
git pull origin develop
```

Nếu có conflict: sửa conflict, kiểm tra lại code chạy được, rồi `git add` và `git commit`.

### Bước 3 – Kiểm tra trước khi commit

**Backend** (trong thư mục `Backend/`, đã kích hoạt `.venv`):

```bash
python manage.py check
python manage.py makemigrations --check --dry-run   # đảm bảo không quên migration
python manage.py test
```

**Frontend** (trong thư mục `Frontend/`):

```bash
dart format .
flutter analyze
flutter test
```

Tất cả lệnh trên phải chạy **không có lỗi** thì mới được commit.

### Bước 4 – Commit và push lên nhánh cá nhân

```bash
git status                     # xem lại các file thay đổi
git add <các file liên quan>   # hạn chế dùng "git add ." để tránh commit nhầm file
git commit -m "feat(frontend): thêm màn hình danh sách chi tiêu"
git push origin dev_<tên>
```

### Bước 5 – Tạo Pull Request (Merge Request) vào `develop`

1. Lên GitHub, chọn **Pull requests → New pull request**.
2. **base:** `develop` ← **compare:** `dev_<tên>`.
3. Tiêu đề theo quy ước commit; phần mô tả ghi rõ:
   - Đã làm gì, liên quan nhiệm vụ nào.
   - Cách kiểm thử (ảnh chụp màn hình nếu là giao diện).
   - Có thay đổi model/migration, thư viện mới hay biến môi trường mới không.
4. Gán ít nhất **1 thành viên khác** review.
5. Người review kiểm tra code, kéo nhánh về chạy thử nếu cần. Có góp ý thì người tạo PR sửa tiếp trên `dev_<tên>` và push lại (PR tự cập nhật).
6. Khi được **Approve** và không còn conflict, nhóm trưởng (hoặc người được phân quyền) bấm **Merge** vào `develop`.

Không tự merge PR của chính mình khi chưa có người review.

### Bước 6 – Kiểm thử trên `develop`

Sau khi các PR của một đợt đã được gộp vào `develop`, nhóm trưởng (hoặc người được giao) thực hiện:

```bash
git checkout develop
git pull origin develop
```

- Chạy lại đầy đủ các lệnh kiểm tra ở **Bước 3** cho cả Backend và Frontend.
- Chạy backend (`python manage.py migrate`, `python manage.py runserver`) và frontend (`flutter run`), kiểm tra thủ công các chức năng chính hoạt động cùng nhau.
- Nếu phát hiện lỗi: thành viên phụ trách sửa trên nhánh `dev_<tên>` của mình rồi tạo PR mới vào `develop`. **Không sửa trực tiếp trên `develop`.**

### Bước 7 – Tạo Pull Request từ `develop` vào `main`

**Chỉ thực hiện khi chắc chắn `develop` không còn lỗi**, tức là:

- [ ] Toàn bộ lệnh kiểm tra ở Bước 3 đều chạy thành công.
- [ ] App chạy được, các chức năng của đợt này đã được kiểm thử thủ công.
- [ ] Không còn PR nào đang mở cần gộp cho đợt này.
- [ ] Không có thông tin nhạy cảm trong code.

Sau đó:

1. Trên GitHub tạo Pull Request: **base:** `main` ← **compare:** `develop`.
2. Mô tả liệt kê các chức năng/sửa lỗi có trong đợt phát hành.
3. Nhóm trưởng review lần cuối và **Merge** vào `main`.

---

## 7. Cấu hình bảo vệ nhánh trên GitHub (dành cho nhóm trưởng)

Vào **Settings → Branches → Add branch protection rule** cho `main` và `develop`:

- Bật **Require a pull request before merging**.
- Bật **Require approvals** (tối thiểu 1).
- Bật **Do not allow bypassing the above settings** để tránh push trực tiếp.

---

## 8. Checklist trước khi tạo Pull Request

- [ ] Nhánh đã được cập nhật code mới nhất từ `develop`, không còn conflict.
- [ ] Code đúng quy ước đặt tên và cấu trúc thư mục ở mục 2 và 3.
- [ ] Backend: `check`, `makemigrations --check`, `test` đều thành công.
- [ ] Frontend: `dart format`, `flutter analyze`, `flutter test` đều thành công.
- [ ] Đã commit file migration (nếu sửa model) và `requirements.txt` / `pubspec.yaml` (nếu thêm thư viện).
- [ ] Không có `print`/`debugPrint` debug, code bị comment, file rác, thông tin nhạy cảm.
- [ ] Commit message đúng quy ước ở mục 5.
