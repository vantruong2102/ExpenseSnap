import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants/api_constants.dart';
import 'api_exception.dart';

class PasswordResetService {
  PasswordResetService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<void> requestCode(String email) async {
    final body = await _post(ApiConstants.passwordResetRequest, {'email': email.trim()});
    if (body['message'] is String) return;
  }

  Future<String> verifyCode({required String email, required String code}) async {
    final body = await _post(ApiConstants.passwordResetVerify, {
      'email': email.trim(),
      'otp': code,
    });
    final token = body['reset_token'];
    if (token is! String || token.isEmpty) {
      throw const ApiException('Máy chủ không trả về mã xác nhận. Vui lòng thử lại.');
    }
    return token;
  }

  Future<void> setNewPassword({required String resetToken, required String password}) async {
    await _post(ApiConstants.passwordResetComplete, {
      'reset_token': resetToken,
      'password': password,
    });
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, String> payload) async {
    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('${ApiConstants.baseUrl}$path'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(ApiConstants.timeout);
    } on TimeoutException {
      throw ApiException.network;
    } on http.ClientException {
      throw ApiException.network;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException.fromResponse(response);
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException('Phản hồi máy chủ không hợp lệ.');
    }
    return decoded;
  }
}
