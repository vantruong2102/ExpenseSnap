class Validators {
  Validators._();

  static final RegExp _emailPattern = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');

  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Vui lòng nhập họ tên';
    if (value.trim().length > 150) return 'Họ tên tối đa 150 ký tự';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Vui lòng nhập email';
    if (!_emailPattern.hasMatch(value.trim())) return 'Email không hợp lệ';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Vui lòng nhập mật khẩu';
    if (value.length < 8) return 'Mật khẩu phải có ít nhất 8 ký tự';
    if (RegExp(r'^\d+$').hasMatch(value)) return 'Mật khẩu không được chỉ gồm số';
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Vui lòng nhập lại mật khẩu';
    if (value != password) return 'Mật khẩu xác nhận không khớp';
    return null;
  }
}
