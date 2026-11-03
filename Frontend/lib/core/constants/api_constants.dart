import 'package:flutter/foundation.dart';

class ApiConstants {
  ApiConstants._();

  /// Override when running on a real device:
  /// `flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000`
  static const String _overrideBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_overrideBaseUrl.isNotEmpty) return _overrideBaseUrl;
    // The Android emulator reaches the host machine through 10.0.2.2
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  static const String register = '/api/auth/register/';
  static const String login = '/api/auth/login/';
  static const String receipts = '/api/receipts/';

  static const Duration timeout = Duration(seconds: 20);
}
