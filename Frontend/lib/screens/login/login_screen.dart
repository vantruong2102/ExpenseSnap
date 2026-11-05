
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/theme/app_theme.dart';
import '../../services/login_service.dart';
import '../../widgets/washi_tape.dart';
import '../home/home_screen.dart';
import 'password_reset_screen.dart';
import '../register/register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _loginService = LoginService();

  bool _loading = false;
  bool _hidePassword = true;
  bool _rememberMe = false;

  static const Color red = Color(0xFFD94332);
  static const Color dark = Color(0xFF292522);
  static const Color grey = Color(0xFF938C85);
  static const Color background = Color(0xFFF7F4EC);
  static const Color line = Color(0xFFEAE5DD);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value)),
    );
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const HomeScreen(),
      ),
      (route) => false,
    );
  }

  Future<void> _loginEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await _loginService.loginWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;
      _goHome();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message = 'Đăng nhập thất bại';

      if (e.code == 'invalid-credential' ||
          e.code == 'wrong-password' ||
          e.code == 'user-not-found') {
        message = 'Email hoặc mật khẩu không chính xác';
      } else if (e.code == 'invalid-email') {
        message = 'Email không hợp lệ';
      } else if (e.code == 'network-request-failed') {
        message = 'Không có kết nối mạng';
      } else if (e.code == 'too-many-requests') {
        message = 'Vui lòng thử lại sau';
      }

      _message(message);
    } catch (e) {
      if (mounted) _message('Có lỗi xảy ra: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginGoogle() async {
    setState(() => _loading = true);

    try {
      await _loginService.loginWithGoogle();

      if (!mounted) return;
      _goHome();
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        _message(e.message ?? 'Đăng nhập Google thất bại');
      }
    } catch (e) {
      if (mounted) _message('Không thể đăng nhập Google: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 36,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 390,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            _receipt(),
                            const Positioned(
                              top: -10,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: WashiTape(
                                  label: 'EXPENSESNAP',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const _TornPaper(),
                        const SizedBox(height: 22),
                        _registerLink(),
                        const SizedBox(height: 5),
                        const Text(
                          '• BẢN QUYỀN THUỘC TIẾT KIỆM •',
                          style: TextStyle(
                            fontFamily: AppFonts.mono,
                            fontSize: 9,
                            letterSpacing: 0.6,
                            color: grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _receipt() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 25, 22, 23),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(9),
        ),
        border: Border.all(
          color: const Color(0xFFEAE6DF),
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            
            _brand(),
            const SizedBox(height: 20),
            _stamp(),
            const SizedBox(height: 26),
            _emailField(),
            const SizedBox(height: 21),
            _passwordField(),
            const SizedBox(height: 16),
            _options(),
            const SizedBox(height: 23),
            _loginButton(),
            const SizedBox(height: 23),
            _orDivider(),
            const SizedBox(height: 22),
            _googleButton(),
            const SizedBox(height: 24),
            _footer(),
          ],
        ),
      ),
    );
  }

//  Widget _receiptHeader() {
//   return const SizedBox.shrink();
// }

  Widget _brand() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 31,
              height: 35,
              decoration: BoxDecoration(
                color: red,
                borderRadius: BorderRadius.circular(3),
              ),
              child: const Icon(
                Icons.receipt_long,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 7),
            const Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Expense',
                    style: TextStyle(color: dark),
                  ),
                  TextSpan(
                    text: 'Snap',
                    style: TextStyle(color: red),
                  ),
                ],
              ),
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontWeight: FontWeight.w800,
                fontSize: 22,
                letterSpacing: -0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 11),
        const Text(
          'Mở sổ chi tiêu của bạn',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: dark,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Nhập thông tin xác thực để mở nhật ký thu chi',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            color: grey,
          ),
        ),
      ],
    );
  }

  Widget _stamp() {
    return Center(
      child: Transform.rotate(
        angle: -0.045,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: red),
            borderRadius: BorderRadius.circular(2),
          ),
          child: const Text(
            'SỔ KẾ TOÁN · BẢO MẬT',
            style: TextStyle(
              fontFamily: AppFonts.mono,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: red,
              letterSpacing: 1.1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _fieldTitle(
    String number,
    String title,
    String description,
  ) {
    return Row(
      children: [
        Text(
          '$number.',
          style: const TextStyle(
            fontFamily: AppFonts.mono,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: red,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontFamily: AppFonts.mono,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: dark,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            description,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontFamily: AppFonts.mono,
              fontSize: 9,
              color: grey,
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(
    String hint,
    IconData? icon,
  ) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontFamily: AppFonts.mono,
        fontSize: 12,
        color: Color(0xFFB6B0A9),
      ),
      suffixIcon: icon == null
          ? null
          : Icon(
              icon,
              size: 18,
              color: grey,
            ),
      contentPadding: const EdgeInsets.symmetric(
        vertical: 11,
      ),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: line),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(
          color: red,
          width: 1.4,
        ),
      ),
      errorBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: red),
      ),
      focusedErrorBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: red),
      ),
    );
  }

  Widget _emailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _fieldTitle('01', 'Email', 'Tài khoản chính'),
        const SizedBox(height: 5),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          style: const TextStyle(
            fontFamily: AppFonts.mono,
            fontSize: 12,
          ),
          decoration: _inputDecoration(
            'tri.nguyen@email.com',
            Icons.mail_outline,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Vui lòng nhập Email';
            }
            if (!value.contains('@')) {
              return 'Email không hợp lệ';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _passwordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _fieldTitle('02', 'Mật khẩu', 'Tối thiểu 8 ký tự'),
        const SizedBox(height: 5),
        TextFormField(
          controller: _passwordController,
          obscureText: _hidePassword,
          style: const TextStyle(
            fontFamily: AppFonts.mono,
            fontSize: 12,
          ),
          decoration: _inputDecoration(
            '••••••••',
            null,
          ).copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                _hidePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 18,
                color: grey,
              ),
              onPressed: () {
                setState(() {
                  _hidePassword = !_hidePassword;
                });
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng nhập mật khẩu';
            }
            return null;
          },
          onFieldSubmitted: (_) {
            if (!_loading) _loginEmail();
          },
        ),
      ],
    );
  }

  Widget _options() {
    return Row(
      children: [
        SizedBox(
          width: 23,
          height: 23,
          child: Checkbox(
            value: _rememberMe,
            activeColor: red,
            side: const BorderSide(color: red),
            onChanged: (value) {
              setState(() {
                _rememberMe = value ?? false;
              });
            },
          ),
        ),
        const SizedBox(width: 6),
        const Text(
          'Ghi nhớ đăng nhập',
          style: TextStyle(
            fontSize: 10,
            color: grey,
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PasswordResetScreen()),
            );
          },
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 30),
          ),
          child: const Text(
            'Quên mật khẩu?',
            style: TextStyle(
              color: red,
              fontSize: 10,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _loginButton() {
    return SizedBox(
      height: 48,
      child: FilledButton(
        onPressed: _loading ? null : _loginEmail,
        style: FilledButton.styleFrom(
          backgroundColor: red,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        child: _loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Đăng nhập',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward, size: 17),
                ],
              ),
      ),
    );
  }

  Widget _orDivider() {
    return const Row(
      children: [
        Expanded(
          child: Divider(color: line),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 15),
          child: Text(
            'HOẶC',
            style: TextStyle(
              fontFamily: AppFonts.mono,
              fontSize: 10,
              color: grey,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: line),
        ),
      ],
    );
  }

  Widget _googleButton() {
    return SizedBox(
      height: 49,
      child: OutlinedButton(
        onPressed: _loading ? null : _loginGoogle,
        style: OutlinedButton.styleFrom(
          foregroundColor: dark,
          side: const BorderSide(color: line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(7),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'G',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 19,
                color: Color(0xFF4285F4),
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Tiếp tục với Google',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _footer() {
    return const Row(
      children: [
        Icon(
          Icons.lock_outline,
          size: 12,
          color: grey,
        ),
        SizedBox(width: 5),
        Expanded(
          child: Text(
            'Bảo mật ưu tiên chất lượng',
            style: TextStyle(
              fontFamily: AppFonts.mono,
              fontSize: 9,
              color: grey,
            ),
          ),
        ),
        Text(
          'VN',
          style: TextStyle(
            fontFamily: AppFonts.mono,
            fontSize: 10,
            color: grey,
          ),
        ),
      ],
    );
  }

  Widget _registerLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Chưa có tài khoản?',
          style: TextStyle(
            fontSize: 12,
            color: grey,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const RegisterScreen(),
              ),
            );
          },
          child: const Text(
            'Đăng ký',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: red,
            ),
          ),
        ),
      ],
    );
  }
}

class _TornPaper extends StatelessWidget {
  const _TornPaper();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 8,
      width: double.infinity,
      child: CustomPaint(
        painter: _TornPaperPainter(),
      ),
    );
  }
}

class _TornPaperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const tooth = 8.0;

    final path = Path()..moveTo(0, 0);

    for (double x = 0; x < size.width; x += tooth) {
      path
        ..lineTo(x + tooth / 2, size.height)
        ..lineTo((x + tooth).clamp(0.0, size.width), 0);
    }

    path.close();

    canvas.drawPath(
      path,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
