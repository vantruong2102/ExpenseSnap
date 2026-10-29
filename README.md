# ExpenseSnap

ExpenseSnap là dự án ứng dụng quản lý chi tiêu cá nhân, hướng tới việc lưu thông tin các khoản chi cùng ảnh hóa đơn để người dùng tiện theo dõi.


## Công nghệ

- **Frontend:** Flutter / Dart
- **Backend:** FrameWork Django và Python
- **Thư viện đã khai báo:** Firebase (Flutter), Django REST Framework, Simple JWT và Firebase Admin (backend)

Các thư viện đã khai báo chưa đồng nghĩa những tích hợp hoặc tính năng tương ứng đã được cấu hình và hoạt động.

## Cấu trúc dự án

```text
ExpenseSnap/
├── Backend/
│   ├── config/          # Cấu hình Django và URL
│   ├── transactions/    # App giao dịch (chưa có model/API nghiệp vụ)
│   ├── manage.py
│   └── requirements.txt
└── Frontend/
    ├── lib/             # Mã nguồn Flutter
    ├── test/            # Widget tests
    └── pubspec.yaml
```

## Yêu cầu

- Python tương thích với phiên bản Django được ghim trong `Backend/requirements.txt`
- Flutter SDK tương thích với ràng buộc Dart trong `Frontend/pubspec.yaml`
- Git (nếu clone dự án)

## Chạy backend

Trong PowerShell, từ thư mục gốc dự án:

```powershell
cd Backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
python manage.py migrate
python manage.py runserver
```

Mặc định Django chạy tại <http://127.0.0.1:8000/>. Hiện tại URL được khai báo là `/admin/`; chưa có API giao dịch để frontend sử dụng.

## Chạy frontend

Mở terminal thứ hai tại thư mục gốc:

```powershell
cd Frontend
flutter pub get
flutter run
```

Chọn thiết bị hoặc emulator đang hoạt động khi được Flutter yêu cầu. Ứng dụng hiện khởi chạy màn hình Flutter mẫu.

## Kiểm thử

Chạy widget test của Flutter:

```powershell
cd Frontend
flutter test
```

Chạy Django checks:

```powershell
cd Backend
python manage.py check
```

## Cấu hình và lưu ý

- Backend hiện dùng SQLite theo cấu hình mặc định của Django.
- Các gói Firebase có trong dependencies, nhưng cấu hình Firebase và luồng xác thực/lưu trữ chưa được thiết lập trong ứng dụng.
- Cấu hình Django hiện dành cho phát triển cục bộ. Trước khi triển khai, cần chuyển các giá trị nhạy cảm sang biến môi trường và cấu hình `DEBUG`, `ALLOWED_HOSTS`, cơ sở dữ liệu cùng các thiết lập bảo mật phù hợp.
