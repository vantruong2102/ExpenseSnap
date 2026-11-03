import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants/api_constants.dart';
import '../models/app_user.dart';
import 'api_exception.dart';

/// Holds the signed-in user and JWT tokens for the current app session.
class AuthSession {
  AuthSession._();

  static final AuthSession instance = AuthSession._();

  AppUser? user;
  String? accessToken;
  String? refreshToken;

  bool get isSignedIn => accessToken != null;

  void clear() {
    user = null;
    accessToken = null;
    refreshToken = null;
  }
}

class AuthService {
  AuthService({http.Client? client, AuthSession? session})
    : _client = client ?? http.Client(),
      _session = session ?? AuthSession.instance;

  final http.Client _client;
  final AuthSession _session;

  Future<AppUser> register({
    required String fullName,
    required String email,
    required String password,
    required String passwordConfirm,
  }) async {
    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.register}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'full_name': fullName.trim(),
              'email': email.trim(),
              'password': password,
              'password_confirm': passwordConfirm,
            }),
          )
          .timeout(ApiConstants.timeout);
    } on TimeoutException {
      throw ApiException.network;
    } on http.ClientException {
      throw ApiException.network;
    }

    if (response.statusCode != 201) throw ApiException.fromResponse(response);

    final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final user = AppUser.fromJson(body['user'] as Map<String, dynamic>);
    _session
      ..user = user
      ..accessToken = body['access'] as String
      ..refreshToken = body['refresh'] as String;
    return user;
  }
}
