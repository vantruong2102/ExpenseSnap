import 'dart:convert';

import 'package:http/http.dart' as http;

/// Error returned by the backend, with per-field messages from DRF when available.
class ApiException implements Exception {
  const ApiException(this.message, {this.fieldErrors = const {}});

  final String message;
  final Map<String, String> fieldErrors;

  factory ApiException.fromResponse(http.Response response) {
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is Map<String, dynamic>) {
        final fieldErrors = <String, String>{};
        body.forEach((key, value) {
          final text = value is List ? value.join('\n') : value.toString();
          fieldErrors[key] = text;
        });
        final message = fieldErrors['detail'] ?? fieldErrors['non_field_errors'] ?? fieldErrors.values.first;
        return ApiException(message, fieldErrors: fieldErrors);
      }
    } catch (_) {
      // Fall through to the generic message below
    }
    return ApiException('Máy chủ gặp lỗi (mã ${response.statusCode}). Vui lòng thử lại.');
  }

  static const ApiException network = ApiException('Không kết nối được máy chủ. Vui lòng kiểm tra mạng và thử lại.');

  @override
  String toString() => message;
}
