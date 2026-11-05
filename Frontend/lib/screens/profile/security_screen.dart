import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../login/password_reset_screen.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  static const _red = Color(0xFFBD3324);
  static const _ink = Color(0xFF302B27);
  static const _grey = Color(0xFF817970);
  static const _cream = Color(0xFFFFF8F2);
  static const _line = Color(0xFFECE5DF);

  final _formKey = GlobalKey<FormState>();
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();

  bool _saving = false;
  bool _hideCurrent = true;
  bool _hideNew = true;
  bool _hideConfirm = true;

  User? get _user => FirebaseAuth.instance.currentUser;

  bool get _hasPasswordProvider => _user?.providerData.any(
        (provider) => provider.providerId == EmailAuthProvider.PROVIDER_ID,
      ) ??
      false;

  @override
  void dispose() {
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    final user = _user;
    final email = user?.email;
    if (user == null || email == null || email.isEmpty) {
      _showMessage('Không tìm thấy tài khoản đang đăng nhập.');
      return;
    }

    setState(() => _saving = true);
    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: _currentPassword.text,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(_newPassword.text);
      if (!mounted) return;
      _currentPassword.clear();
      _newPassword.clear();
      _confirmPassword.clear();
      Navigator.of(context).pop(true);
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      final message = switch (error.code) {
        'wrong-password' || 'invalid-credential' => 'Mật khẩu hiện tại không chính xác.',
        'weak-password' => 'Mật khẩu mới chưa đủ mạnh.',
        'requires-recent-login' => 'Phiên đăng nhập đã cũ. Hãy đăng nhập lại rồi thử lại.',
        'network-request-failed' => 'Không có kết nối mạng. Hãy thử lại.',
        _ => error.message ?? 'Không thể đổi mật khẩu lúc này.',
      };
      _showMessage(message);
    } catch (_) {
      if (mounted) _showMessage('Không thể đổi mật khẩu lúc này. Hãy thử lại.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _resetByEmail() async {
    final email = _user?.email;
    final passwordChanged = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PasswordResetScreen(initialEmail: email),
      ),
    );
    if (passwordChanged == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFAF6),
        foregroundColor: _ink,
        elevation: 0,
        title: const Text(
          'Bảo mật tài khoản',
          style: TextStyle(
            fontFamily: AppFonts.body,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: _hasPasswordProvider ? _passwordForm() : _googleAccountCard(),
        ),
      ),
    );
  }

  Widget _passwordForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ĐỔI MẬT KHẨU',
            style: TextStyle(
              fontFamily: AppFonts.mono,
              fontSize: 10,
              letterSpacing: 1,
              color: _grey,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Bảo vệ tài khoản của bạn',
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _ink,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Nhập mật khẩu hiện tại để xác nhận trước khi thay đổi.',
            style: TextStyle(fontFamily: AppFonts.body, fontSize: 13, color: _grey),
          ),
          const SizedBox(height: 24),
          _label('MẬT KHẨU HIỆN TẠI'),
          const SizedBox(height: 8),
          _passwordField(
            controller: _currentPassword,
            hint: 'Nhập mật khẩu hiện tại',
            hidden: _hideCurrent,
            onToggle: () => setState(() => _hideCurrent = !_hideCurrent),
            validator: (value) => (value == null || value.isEmpty)
                ? 'Vui lòng nhập mật khẩu hiện tại.'
                : null,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _saving ? null : _resetByEmail,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Quên mật khẩu hiện tại?',
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 11,
                  color: _red,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          _label('MẬT KHẨU MỚI'),
          const SizedBox(height: 8),
          _passwordField(
            controller: _newPassword,
            hint: 'Tối thiểu 8 ký tự',
            hidden: _hideNew,
            onToggle: () => setState(() => _hideNew = !_hideNew),
            validator: (value) {
              final password = value ?? '';
              if (password.length < 8 || password.trim().isEmpty) {
                return 'Mật khẩu cần có ít nhất 8 ký tự.';
              }
              if (RegExp(r'^\d+$').hasMatch(password)) {
                return 'Mật khẩu không được chỉ gồm chữ số.';
              }
              if (password == _currentPassword.text) {
                return 'Mật khẩu mới cần khác mật khẩu hiện tại.';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),
          _label('XÁC NHẬN MẬT KHẨU MỚI'),
          const SizedBox(height: 8),
          _passwordField(
            controller: _confirmPassword,
            hint: 'Nhập lại mật khẩu mới',
            hidden: _hideConfirm,
            onToggle: () => setState(() => _hideConfirm = !_hideConfirm),
            validator: (value) => value != _newPassword.text
                ? 'Mật khẩu xác nhận chưa khớp.'
                : null,
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _changePassword,
              icon: _saving
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.lock_outline, size: 18),
              label: Text(_saving ? 'Đang cập nhật...' : 'Đổi mật khẩu'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                textStyle: const TextStyle(
                  fontFamily: AppFonts.body,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _googleAccountCard() {
    final email = _user?.email ?? 'email tài khoản';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.account_circle_outlined, color: _red, size: 38),
          const SizedBox(height: 8),
          const Text(
            'Tài khoản đăng nhập bằng Google',
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tài khoản $email chưa có mật khẩu ExpenseSnap. Bạn có thể xác minh email bằng mã OTP để thiết lập mật khẩu.',
            style: const TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 13,
              height: 1.5,
              color: _grey,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _resetByEmail,
              icon: const Icon(Icons.mark_email_read_outlined, size: 18),
              label: const Text('Nhận mã OTP qua email'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                textStyle: const TextStyle(
                  fontFamily: AppFonts.body,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontFamily: AppFonts.mono,
          fontSize: 9,
          letterSpacing: 0.8,
          color: _grey,
        ),
      );

  Widget _passwordField({
    required TextEditingController controller,
    required String hint,
    required bool hidden,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) =>
      TextFormField(
        controller: controller,
        obscureText: hidden,
        validator: validator,
        style: const TextStyle(fontFamily: AppFonts.body, fontSize: 14, color: _ink),
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
          hintStyle: const TextStyle(fontFamily: AppFonts.body, fontSize: 13, color: _grey),
          prefixIcon: const Icon(Icons.lock_outline, color: _grey, size: 19),
          suffixIcon: IconButton(
            onPressed: onToggle,
            icon: Icon(hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: const BorderSide(color: _line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: const BorderSide(color: _red, width: 1.4),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: const BorderSide(color: _red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: const BorderSide(color: _red, width: 1.4),
          ),
        ),
      );
}
