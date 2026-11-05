import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../services/api_exception.dart';
import '../../services/password_reset_service.dart';
import '../../widgets/dashed_line.dart';
import '../../widgets/stamp_tag.dart';
import '../../widgets/washi_tape.dart';

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _service = PasswordResetService();

  int _step = 0;
  bool _busy = false;
  bool _hidePassword = true;
  String? _resetToken;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _sendCode() async {
    if (_step == 0 && !_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await _service.requestCode(_emailController.text);
      if (!mounted) return;
      setState(() {
        _step = 1;
        _otpController.clear();
      });
    } on ApiException catch (error) {
      if (mounted) _message(error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verifyCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final token = await _service.verifyCode(
        email: _emailController.text,
        code: _otpController.text,
      );
      if (!mounted) return;
      setState(() {
        _resetToken = token;
        _step = 2;
      });
    } on ApiException catch (error) {
      if (mounted) _message(error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate() || _resetToken == null) return;
    setState(() => _busy = true);
    try {
      await _service.setNewPassword(
        resetToken: _resetToken!,
        password: _passwordController.text,
      );
      if (!mounted) return;
      _message('Đổi mật khẩu thành công. Hãy đăng nhập bằng mật khẩu mới.');
      Navigator.of(context).pop();
    } on ApiException catch (error) {
      if (mounted) _message(error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String get _title => switch (_step) {
        0 => 'Quên mật khẩu?',
        1 => 'Nhập mã OTP',
        _ => 'Tạo mật khẩu mới',
      };

  String get _subtitle => switch (_step) {
        0 => 'Nhập email đã đăng ký để nhận mã xác minh đặt lại mật khẩu.',
        1 => 'Nhập mã 6 số đã gửi tới email của bạn.',
        _ => 'Tạo mật khẩu mới để tiếp tục sử dụng sổ hóa đơn.',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 390),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _topBar(),
                  _receipt(),
                  const SizedBox(height: 14),
                  _supportFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(color: Color(0xFFFFF8F3)),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Quay lại',
            onPressed: () => Navigator.of(context).pop(),
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.arrow_back, size: 19, color: AppColors.textPrimary),
          ),
          const Expanded(
            child: Text(
              'Sổ Hóa Đơn',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
          const Text(
            'ES·04',
            style: TextStyle(
              fontFamily: AppFonts.mono,
              fontSize: 8,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _receipt() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(15, 28, 15, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFEFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEAE4DC)),
        boxShadow: const [
          BoxShadow(color: Color(0x10000000), blurRadius: 14, offset: Offset(0, 5)),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -38,
            left: 0,
            right: 0,
            child: Center(child: WashiTape(label: 'EXPENSE·SNAP', width: 96, height: 19)),
          ),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _receiptMeta(),
                const SizedBox(height: 14),
                const DashedLine(color: Color(0x1F292522)),
                const SizedBox(height: 15),
                const Center(child: _EnvelopeSeal()),
                const SizedBox(height: 14),
                Text(
                  _title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.55),
                ),
                const SizedBox(height: 18),
                if (_step == 0) _emailField(),
                if (_step == 1) ...[
                  _emailSummary(),
                  const SizedBox(height: 13),
                  _otpField(),
                  const SizedBox(height: 12),
                  _sentNotice(),
                ],
                if (_step == 2) ...[
                  _passwordField(),
                  const SizedBox(height: 13),
                  _confirmField(),
                ],
                const SizedBox(height: 15),
                SizedBox(
                  height: 44,
                  child: FilledButton.icon(
                    onPressed: _busy
                        ? null
                        : switch (_step) {
                            0 => _sendCode,
                            1 => _verifyCode,
                            _ => _changePassword,
                          },
                    icon: _busy
                        ? const SizedBox.square(
                            dimension: 17,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Icon(_buttonIcon, size: 16),
                    label: Text(_buttonLabel),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ),
                if (_step == 1) ...[
                  const SizedBox(height: 3),
                  TextButton(
                    onPressed: _busy ? null : _sendCode,
                    child: const Text('Gửi lại mã OTP', style: TextStyle(fontSize: 11)),
                  ),
                ],
                const SizedBox(height: 13),
                const DashedLine(color: Color(0x30292522)),
                const SizedBox(height: 13),
                _receiptFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData get _buttonIcon => switch (_step) {
        0 => Icons.mark_email_read_outlined,
        1 => Icons.verified_outlined,
        _ => Icons.lock_reset_outlined,
      };

  String get _buttonLabel => switch (_step) {
        0 => 'Gửi mã OTP',
        1 => 'Xác nhận mã OTP',
        _ => 'Đặt mật khẩu mới',
      };

  Widget _receiptMeta() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MÃ TIẾP NHẬN', style: AppTheme.monoLabel.copyWith(fontSize: 8, letterSpacing: 0.35)),
              SizedBox(height: 3),
              Text(
                'REC-AUTH-2024',
                style: TextStyle(fontFamily: AppFonts.mono, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const StampTag('BẢO MẬT', fontSize: 9),
      ],
    );
  }

  Widget _emailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _fieldLabel('ĐỊA CHỈ THƯ ĐIỆN TỬ', required: true),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          style: const TextStyle(fontFamily: AppFonts.mono, fontSize: 11),
          decoration: _fieldDecoration(
            'ten@email.com',
            prefix: const Text('mail  ', style: TextStyle(fontFamily: AppFonts.mono, fontSize: 11)),
            suffix: IconButton(
              tooltip: 'Xóa email',
              onPressed: () => _emailController.clear(),
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.cancel_outlined, size: 14),
            ),
          ),
          validator: Validators.email,
        ),
        const SizedBox(height: 5),
        const Text(
          'Định dạng: username@vn. Hệ thống sẽ giữ kín thông tin.',
          style: TextStyle(fontFamily: AppFonts.mono, fontSize: 7, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _emailSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _fieldLabel('MÃ ĐƯỢC GỬI ĐẾN'),
        TextFormField(
          initialValue: _emailController.text.trim(),
          readOnly: true,
          style: const TextStyle(fontFamily: AppFonts.mono, fontSize: 10),
          decoration: _fieldDecoration('', prefix: const Text('mail  ', style: TextStyle(fontFamily: AppFonts.mono, fontSize: 11))),
        ),
      ],
    );
  }

  Widget _otpField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _fieldLabel('MÃ XÁC MINH 6 SỐ', required: true),
        TextFormField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: AppFonts.mono, fontSize: 20, letterSpacing: 9),
          decoration: _fieldDecoration('000000').copyWith(counterText: ''),
          validator: (value) => value == null || !RegExp(r'^\d{6}$').hasMatch(value.trim())
              ? 'Nhập đúng mã gồm 6 chữ số'
              : null,
        ),
      ],
    );
  }

  Widget _passwordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _fieldLabel('MẬT KHẨU MỚI', required: true),
        TextFormField(
          controller: _passwordController,
          obscureText: _hidePassword,
          style: const TextStyle(fontFamily: AppFonts.mono, fontSize: 11),
          decoration: _fieldDecoration(
            'Tối thiểu 8 ký tự',
            suffix: IconButton(
              onPressed: () => setState(() => _hidePassword = !_hidePassword),
              visualDensity: VisualDensity.compact,
              icon: Icon(_hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 16),
            ),
          ),
          validator: Validators.password,
        ),
      ],
    );
  }

  Widget _confirmField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _fieldLabel('XÁC NHẬN MẬT KHẨU', required: true),
        TextFormField(
          controller: _confirmController,
          obscureText: _hidePassword,
          style: const TextStyle(fontFamily: AppFonts.mono, fontSize: 11),
          decoration: _fieldDecoration('Nhập lại mật khẩu mới'),
          validator: (value) => Validators.confirmPassword(value, _passwordController.text),
        ),
      ],
    );
  }

  Widget _fieldLabel(String text, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Expanded(child: Text(text, style: AppTheme.monoLabel.copyWith(fontSize: 8, letterSpacing: 0.35))),
          if (required)
            const Text(
              '• BẮT BUỘC',
              style: TextStyle(fontFamily: AppFonts.mono, fontSize: 7, color: AppColors.primary),
            ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint, {Widget? prefix, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontFamily: AppFonts.mono, fontSize: 10, color: Color(0xFFAAA39B)),
      prefixIcon: prefix == null ? null : Padding(padding: const EdgeInsets.only(left: 2), child: prefix),
      prefixIconConstraints: const BoxConstraints(minWidth: 34, minHeight: 36),
      suffixIcon: suffix,
      suffixIconConstraints: const BoxConstraints(minWidth: 30, minHeight: 34),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
      enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD8D2CA))),
      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary, width: 1.3)),
      errorBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.ink)),
      focusedErrorBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.ink)),
    );
  }

  Widget _sentNotice() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6ED),
        border: Border.all(color: const Color(0x55D64933)),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(color: Color(0xFFFFE2BD), shape: BoxShape.circle),
            child: const Icon(Icons.mark_email_read_outlined, color: AppColors.ink, size: 14),
          ),
          const SizedBox(width: 9),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('THÔNG BÁO XÁC THỰC', style: TextStyle(fontFamily: AppFonts.mono, fontSize: 8, fontWeight: FontWeight.w700, color: AppColors.ink)),
                SizedBox(height: 3),
                Text('Đã gửi mã OTP. Hãy kiểm tra hộp thư của bạn.', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, height: 1.4)),
                SizedBox(height: 3),
                Text('Mã có hiệu lực trong 5 phút. Kiểm tra cả thư mục Spam nếu chưa thấy.', style: TextStyle(fontSize: 8, color: AppColors.textSecondary, height: 1.45)),
              ],
            ),
          ),
          const SizedBox(width: 5),
          const Text('Vừa xong', style: TextStyle(fontFamily: AppFonts.mono, fontSize: 7, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _receiptFooter() {
    return const Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text('THUYẾT MINH XỬ LÝ\nPHƯƠNG THỨC', style: TextStyle(fontFamily: AppFonts.mono, fontSize: 7, height: 1.6, color: AppColors.textSecondary))),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'MÃ OTP · HẾT HẠN SAU 05 PHÚT\nEMAIL LIÊN KẾT BẢO MẬT',
                textAlign: TextAlign.right,
                style: TextStyle(fontFamily: AppFonts.mono, fontSize: 7, height: 1.6, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Text('EXPENSESNAP · SỔ CHI TIÊU CÁ NHÂN VIỆT NAM', style: TextStyle(fontFamily: AppFonts.mono, fontSize: 6, letterSpacing: 0.45, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _supportFooter() {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text('Cần trợ giúp khẩn cấp? ', style: TextStyle(fontSize: 9, color: AppColors.textSecondary)),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
          child: const Text('Liên hệ thu hồi hỗ trợ', style: TextStyle(fontSize: 9, decoration: TextDecoration.underline)),
        ),
      ],
    );
  }
}

class _EnvelopeSeal extends StatelessWidget {
  const _EnvelopeSeal();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 122,
      height: 102,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 116,
            height: 96,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F2ED),
              border: Border.all(color: const Color(0xFFE9E0D8)),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const CustomPaint(size: Size(76, 58), painter: _EnvelopePainter()),
          Positioned(
            right: 3,
            bottom: 5,
            child: Transform.rotate(
              angle: 0.14,
              child: Container(
                width: 47,
                height: 47,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBF7),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 1.1),
                ),
                child: Center(
                  child: Container(
                    width: 39,
                    height: 39,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0x88D64933), width: 0.7)),
                    child: const Center(
                      child: Text('EXP\nSNAP', textAlign: TextAlign.center, style: TextStyle(fontFamily: AppFonts.mono, fontSize: 6, height: 1.2, color: AppColors.ink)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EnvelopePainter extends CustomPainter {
  const _EnvelopePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paper = Paint()..color = const Color(0xFFFFFCF8);
    final ink = Paint()
      ..color = const Color(0xFF292522)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final rect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(3));
    canvas.drawRRect(rect, paper);
    canvas.drawRRect(rect, ink);
    final fold = Path()
      ..moveTo(1, 2)
      ..lineTo(size.width / 2, size.height * 0.55)
      ..lineTo(size.width - 1, 2)
      ..moveTo(1, size.height - 2)
      ..lineTo(size.width * 0.37, size.height * 0.47)
      ..moveTo(size.width - 1, size.height - 2)
      ..lineTo(size.width * 0.63, size.height * 0.47);
    canvas.drawPath(fold, ink);
    canvas.drawCircle(Offset(size.width / 2, size.height * 0.55), 2.1, Paint()..color = AppColors.primary);
  }

  @override
  bool shouldRepaint(covariant _EnvelopePainter oldDelegate) => false;
}
