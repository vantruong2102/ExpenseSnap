class ApiConstants {
  ApiConstants._();

  /// Mặc định mọi nền tảng gọi gateway ở 127.0.0.1:8000.
  /// Với Android (máy ảo lẫn máy thật), `run_app.ps1` chạy `adb reverse tcp:8000 tcp:8000`
  /// để cổng 8000 trên thiết bị trỏ về laptop, nên không cần biết IP laptop.
  ///
  /// Khi cài APK mà không có adb (ví dụ gửi file cho người khác), truyền địa chỉ gateway lúc build:
  /// `flutter build apk --debug --dart-define=API_BASE_URL=http://192.168.1.10:8000`
  static const String baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://127.0.0.1:8000');

  static const String firebaseLogin = '/api/auth/firebase/';
  static const String passwordResetRequest = '/api/auth/password-reset/request/';
  static const String passwordResetVerify = '/api/auth/password-reset/verify/';
  static const String passwordResetComplete = '/api/auth/password-reset/complete/';
  static const String receipts = '/api/receipts/';

  static const Duration timeout = Duration(seconds: 20);
}
