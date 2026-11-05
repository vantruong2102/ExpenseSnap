import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
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

/// Firebase Auth lo phần đăng nhập; backend (auth-service) đổi Firebase ID token lấy JWT của hệ thống
/// để gọi các service khác (hóa đơn...).
class AuthService {
  AuthService({http.Client? client, AuthSession? session, FirebaseAuth? firebaseAuth})
    : _client = client ?? http.Client(),
      _session = session ?? AuthSession.instance,
      // Lấy instance khi cần, để test không dùng Firebase vẫn tạo được AuthService
      _authProvider = firebaseAuth == null ? (() => FirebaseAuth.instance) : (() => firebaseAuth);

  final http.Client _client;
  final AuthSession _session;
  final FirebaseAuth Function() _authProvider;

  FirebaseAuth get _auth => _authProvider();

  /// Tạo tài khoản Firebase rồi tạo phiên backend. Nếu backend lỗi thì xóa tài khoản Firebase vừa tạo.
  Future<AppUser> registerWithEmail({required String fullName, required String email, required String password}) async {
    final credential = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
    try {
      await credential.user?.updateDisplayName(fullName.trim());
      return await signInToBackend(fullName: fullName);
    } on ApiException {
      await _rollbackFirebaseUser(credential.user);
      rethrow;
    }
  }

  /// Dùng người dùng Firebase đang đăng nhập để lấy JWT backend.
  /// [forceRefresh] lấy ID token mới từ Firebase (dùng khi JWT backend đã hết hạn).
  Future<AppUser> signInToBackend({String? fullName, bool forceRefresh = false}) async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      throw const ApiException('Phiên đăng nhập đã hết. Vui lòng đăng nhập lại.');
    }
    final idToken = await firebaseUser.getIdToken(forceRefresh);
    if (idToken == null) {
      throw const ApiException('Không lấy được phiên đăng nhập Firebase. Vui lòng đăng nhập lại.');
    }
    return exchangeIdToken(idToken, fullName: fullName);
  }

  Future<AppUser> exchangeIdToken(String idToken, {String? fullName}) async {
    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.firebaseLogin}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'id_token': idToken, if (fullName != null) 'full_name': fullName.trim()}),
          )
          .timeout(ApiConstants.timeout);
    } on TimeoutException {
      throw ApiException.network;
    } on http.ClientException {
      throw ApiException.network;
    }

    if (response.statusCode != 200) throw ApiException.fromResponse(response);

    final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final user = AppUser.fromJson(body['user'] as Map<String, dynamic>);
    _session
      ..user = user
      ..accessToken = body['access'] as String
      ..refreshToken = body['refresh'] as String;
    return user;
  }

  Future<void> signOut() async {
    _session.clear();
    await _auth.signOut();
  }

  Future<void> _rollbackFirebaseUser(User? user) async {
    try {
      await user?.delete();
      await _auth.signOut();
    } on FirebaseAuthException {
      // Giữ nguyên lỗi gốc của backend để hiển thị cho người dùng
    }
  }
}
