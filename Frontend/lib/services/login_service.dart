import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'api_exception.dart';
import 'auth_service.dart';

class LoginService {
  LoginService({AuthService? authService}) : _authService = authService ?? AuthService();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final AuthService _authService;

  // Đăng nhập bằng Email và Mật khẩu
  Future<UserCredential> loginWithEmail({required String email, required String password}) async {
    final credential = await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
    await _connectBackend();
    return credential;
  }

  // Đăng nhập bằng Google
  Future<UserCredential> loginWithGoogle() async {
    await _googleSignIn.initialize();

    final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

    final GoogleSignInAuthentication googleAuth = googleUser.authentication;

    final credential = GoogleAuthProvider.credential(idToken: googleAuth.idToken);

    final userCredential = await _auth.signInWithCredential(credential);
    await _connectBackend();
    return userCredential;
  }

  // Lấy người dùng đang đăng nhập
  User? get currentUser => _auth.currentUser;

  // Đăng xuất (cả Firebase lẫn phiên backend)
  Future<void> logout() async {
    await _authService.signOut();
    await _googleSignIn.signOut();
  }

  // Đổi Firebase ID token lấy JWT backend để dùng các chức năng hóa đơn.
  // Nếu backend lỗi thì đăng xuất Firebase, tránh trạng thái nửa đăng nhập.
  Future<void> _connectBackend() async {
    try {
      await _authService.signInToBackend();
    } on ApiException {
      await logout();
      rethrow;
    }
  }
}
