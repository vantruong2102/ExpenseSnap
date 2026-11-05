import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../services/api_exception.dart';
import '../../services/auth_service.dart';
import '../../widgets/dashed_line.dart';
import '../../widgets/labeled_field.dart';
import '../../widgets/stamp_tag.dart';
import '../../widgets/washi_tape.dart';
import '../receipt_capture/receipt_capture_screen.dart';

/// Figma node 9:475 – "Đăng ký".
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.authService});

  final AuthService? authService;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  late final AuthService _authService = widget.authService ?? AuthService();

  bool _isSubmitting = false;
  bool _obscurePassword = true;
  Map<String, String> _serverErrors = {};

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    setState(() => _serverErrors = {});
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    UserCredential? firebaseCredential;
    try {
      firebaseCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      await firebaseCredential.user?.updateDisplayName(_fullNameController.text.trim());
      await _authService.register(
        fullName: _fullNameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        passwordConfirm: _confirmController.text,
      );
      if (!mounted) return;
      _showMessage('Đăng ký thành công!');
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const ReceiptCaptureScreen()));
    } on ApiException catch (error) {
      if (firebaseCredential?.user != null) {
        try {
          await firebaseCredential!.user!.delete();
          await FirebaseAuth.instance.signOut();
        } on FirebaseAuthException {
          // Keep the original API error visible if compensating cleanup fails.
        }
      }
      if (!mounted) return;
      setState(() => _serverErrors = error.fieldErrors);
      _showMessage(error.message);
    } on FirebaseAuthException catch (error) {
      if (firebaseCredential?.user != null) {
        try {
          await firebaseCredential!.user!.delete();
          await FirebaseAuth.instance.signOut();
        } on FirebaseAuthException {
          // Preserve the original Firebase error shown below.
        }
      }
      if (!mounted) return;
      final message = switch (error.code) {
        'email-already-in-use' => 'Email này đã có tài khoản.',
        'invalid-email' => 'Email không hợp lệ.',
        'weak-password' => 'Mật khẩu quá yếu.',
        'network-request-failed' => 'Không có kết nối mạng.',
        _ => error.message ?? 'Không thể tạo tài khoản Firebase.',
      };
      _showMessage(message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 56,
        automaticallyImplyLeading: false,
        leading: canPop
            ? IconButton(
                tooltip: 'Quay lại',
                color: AppColors.ink,
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: const Text('Đăng ký'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.avatar,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.softBorder),
              ),
              child: const Icon(Icons.person_outline, size: 20, color: AppColors.textBrown),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 448),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _buildDocketCard(),
                      const Positioned(
                        top: -12,
                        left: 0,
                        right: 0,
                        child: Center(child: WashiTape(label: 'EXPENSE•SNAP')),
                      ),
                    ],
                  ),
                  const _TornEdge(),
                  const SizedBox(height: 16),
                  _buildLoginLink(),
                  const SizedBox(height: 24),
                  _buildMicroFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDocketCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(17, 25, 17, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.cardBorder),
          left: BorderSide(color: AppColors.cardBorder),
          right: BorderSide(color: AppColors.cardBorder),
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            LabeledField(
              label: 'Họ và tên',
              stepLabel: '01/NHẬP TÊN',
              controller: _fullNameController,
              icon: Icons.badge_outlined,
              hintText: 'Nguyễn Văn Trí',
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              errorText: _serverErrors['full_name'],
              validator: Validators.fullName,
            ),
            const SizedBox(height: 16),
            LabeledField(
              label: 'Email',
              stepLabel: '02/LIÊN LẠC',
              controller: _emailController,
              icon: Icons.mail_outline,
              hintText: 'tri.nguyen@email.com',
              monoValue: true,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              errorText: _serverErrors['email'],
              validator: Validators.email,
            ),
            const SizedBox(height: 16),
            LabeledField(
              label: 'Mật khẩu',
              stepLabel: '03/BẢO MẬT',
              controller: _passwordController,
              obscureText: _obscurePassword,
              onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
              textInputAction: TextInputAction.next,
              errorText: _serverErrors['password'],
              validator: Validators.password,
            ),
            const SizedBox(height: 16),
            LabeledField(
              label: 'Xác nhận mật khẩu',
              stepLabel: '04/KIỂM TRA',
              controller: _confirmController,
              icon: Icons.lock_open_outlined,
              obscureText: true,
              textInputAction: TextInputAction.done,
              errorText: _serverErrors['password_confirm'],
              validator: (value) => Validators.confirmPassword(value, _passwordController.text),
              onFieldSubmitted: (_) {
                if (!_isSubmitting) _submit();
              },
            ),
            const SizedBox(height: 16),
            const DashedLine(),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('XÁC THỰC LẬP TỨC', style: AppTheme.monoLabel.copyWith(color: const Color(0xB3635E56))),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.content_cut, size: 12, color: Color(0xB3635E56)),
                    Text(
                      ' - - - - - -',
                      style: AppTheme.monoLabel.copyWith(color: const Color(0xB3635E56), letterSpacing: 1.1),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Tạo tài khoản'),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_circle_right_outlined, size: 20),
                      ],
                    ),
            ),
            const SizedBox(height: 16),
            _buildTermsHint(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(bottom: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x33E1BFB8))),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tạo Tài Khoản Mới',
                  style: TextStyle(
                    fontSize: 24,
                    height: 32 / 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.24,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Bắt đầu thói quen chụp & quản lý hóa đơn',
                  style: TextStyle(fontSize: 12, height: 18 / 12, color: AppColors.textBrown),
                ),
              ],
            ),
          ),
          StampTag('MỚI'),
        ],
      ),
    );
  }

  Widget _buildTermsHint() {
    const base = TextStyle(
      fontFamily: AppFonts.mono,
      fontSize: 11,
      height: 17.88 / 11,
      letterSpacing: 0.22,
      color: AppColors.textSecondary,
    );
    const link = TextStyle(
      color: AppColors.textPrimary,
      decoration: TextDecoration.underline,
      decorationStyle: TextDecorationStyle.dotted,
    );
    return const Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: 'Bằng việc tạo sổ, bạn đồng ý với '),
          TextSpan(text: 'Quy chế sổ hóa đơn', style: link),
          TextSpan(text: ' & '),
          TextSpan(text: 'Bảo mật giấy tờ', style: link),
          TextSpan(text: '.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildLoginLink() {
    return InkWell(
      onTap: () {
       Navigator.of(context).pop();
    },
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Đã có tài khoản? ', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            Text(
              'Đăng nhập',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
            ),
            SizedBox(width: 4),
            Icon(Icons.arrow_forward, size: 16, color: AppColors.ink),
          ],
        ),
      ),
    );
  }

  Widget _buildMicroFooter() {
    final style = AppTheme.monoLabel.copyWith(color: const Color(0x99635E56), letterSpacing: 0.22);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.receipt_long, size: 14, color: Color(0x99635E56)),
        const SizedBox(width: 8),
        Flexible(
          child: Text('HỆ THỐNG GHI CHÉP CHI TIÊU THỦ CÔNG & SCAN', textAlign: TextAlign.center, style: style),
        ),
      ],
    );
  }
}

/// Jagged bottom edge so the white card looks like a torn receipt.
class _TornEdge extends StatelessWidget {
  const _TornEdge();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 8,
      width: double.infinity,
      child: CustomPaint(painter: _TornEdgePainter()),
    );
  }
}

class _TornEdgePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const tooth = 8.0;
    final path = Path()..moveTo(0, 0);
    for (var x = 0.0; x < size.width; x += tooth) {
      path
        ..lineTo(x + tooth / 2, size.height)
        ..lineTo((x + tooth).clamp(0, size.width), 0);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = Colors.white);
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.cardBorder
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
