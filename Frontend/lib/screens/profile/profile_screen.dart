
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/theme/app_theme.dart';
import '../../services/login_service.dart';
import '../login/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const red = Color(0xFFBD3324);
  static const ink = Color(0xFF302B27);
  static const grey = Color(0xFF817970);
  static const cream = Color(0xFFFFF8F2);
  static const line = Color(0xFFECE5DF);

  bool _loggingOut = false;

  void _comingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chức năng sẽ được phát triển ở Sprint sau.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi ExpenseSnap?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Đăng xuất',
              style: TextStyle(color: red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _loggingOut = true);

    try {
      await LoginService().logout();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đăng xuất thất bại: $e')),
      );
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final displayName = user?.displayName?.trim();
    final name = displayName != null && displayName.isNotEmpty
        ? displayName
        : (user?.email?.split('@').first ?? 'Người dùng');

    final email = user?.email ?? 'Chưa có email';

    final photo = user?.photoURL;

    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 22, 16, 25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle(),
                    const SizedBox(height: 14),
                    _profileCard(name, email, photo),
                    const SizedBox(height: 18),
                    _settingsCard(),
                    const SizedBox(height: 24),
                    _footer(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  Widget _header() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFAF6),
        border: Border(
          bottom: BorderSide(color: line),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: ink),
          ),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Sổ Hóa Đơn',
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: ink,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'HỒ SƠ CÁ NHÂN',
                  style: TextStyle(
                    fontFamily: AppFonts.mono,
                    fontSize: 10,
                    letterSpacing: 1,
                    color: grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            width: 48,
            child: Icon(
              Icons.account_circle,
              color: red,
              size: 23,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MỤC THIẾT LẬP',
          style: TextStyle(
            fontFamily: AppFonts.mono,
            fontSize: 10,
            color: grey,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Cá nhân',
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: ink,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE9E3),
                border: Border.all(
                  color: const Color(0xFFF1B9AC),
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'THẺ THÀNH VIÊN',
                style: TextStyle(
                  fontFamily: AppFonts.mono,
                  fontSize: 9,
                  letterSpacing: 0.6,
                  color: red,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Divider(color: line, height: 1),
      ],
    );
  }

  Widget _profileCard(
    String name,
    String email,
    String? photo,
  ) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(15, 24, 15, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: line),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      border: Border.all(color: line, width: 3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: photo != null && photo.isNotEmpty
                          ? Image.network(
                              photo,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  const Icon(
                                Icons.person,
                                color: grey,
                                size: 35,
                              ),
                            )
                          : const Icon(
                              Icons.person,
                              color: grey,
                              size: 35,
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: AppFonts.mono,
                            fontSize: 10,
                            color: grey,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          '● Sổ cái: Thành viên',
                          style: TextStyle(
                            fontFamily: AppFonts.mono,
                            fontSize: 10,
                            color: Color(0xFF806044),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(color: line, height: 1),
              const SizedBox(height: 17),
              Row(
                children: [
                  _stat('—', 'Hóa đơn đã lưu'),
                  _statDivider(),
                  _stat('—', 'Chuỗi ghi chép'),
                  _statDivider(),
                  _stat('—', 'Chi tiêu tháng'),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          top: -7,
          left: 0,
          right: 0,
          child: Center(
            child: Transform.rotate(
              angle: -0.025,
              child: Container(
                width: 93,
                height: 18,
                color: const Color(0xB2E9E3D5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _stat(String value, String title) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: AppFonts.mono,
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: ink,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 10,
              color: grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statDivider() {
    return Container(
      width: 1,
      height: 46,
      color: line,
    );
  }

  Widget _settingsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            color: const Color(0xFFF2ECE6),
            child: const Row(
              children: [
                Expanded(
                  child: Text(
                    'DANH MỤC CÀI ĐẶT',
                    style: TextStyle(
                      fontFamily: AppFonts.mono,
                      fontSize: 10,
                      color: grey,
                    ),
                  ),
                ),
                Text(
                  'TẬP 01',
                  style: TextStyle(
                    fontFamily: AppFonts.mono,
                    fontSize: 10,
                    color: grey,
                  ),
                ),
              ],
            ),
          ),
          _settingItem(
            Icons.person_outline,
            'Chỉnh sửa thông tin',
          ),
          _settingItem(
            Icons.notifications_none,
            'Nhắc nhở ghi chép',
            trailing: '21:00 Hằng ngày',
          ),
          _settingItem(
            Icons.cloud_download_outlined,
            'Xuất dữ liệu hóa đơn',
            subtitle: 'Định dạng bảng tính Excel / CSV',
          ),
          _settingItem(
            Icons.category_outlined,
            'Đổi hạn mức chi tiêu',
          ),
          _settingItem(
            Icons.lock_outline,
            'Bảo mật & Mã PIN sổ cái',
            trailing: 'BẬT',
          ),
          _settingItem(
            Icons.help_outline,
            'Trợ giúp & Phản hồi',
          ),
          _settingItem(
            Icons.logout,
            'Đăng xuất',
            isLogout: true,
          ),
        ],
      ),
    );
  }

  Widget _settingItem(
    IconData icon,
    String title, {
    String? subtitle,
    String? trailing,
    bool isLogout = false,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: _loggingOut
              ? null
              : isLogout
                  ? _logout
                  : _comingSoon,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 21,
                  color: isLogout ? red : grey,
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 13,
                          fontWeight: isLogout
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isLogout ? red : ink,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontFamily: AppFonts.mono,
                            fontSize: 9,
                            color: grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null)
                  Flexible(
                    child: Text(
                      trailing,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontFamily: AppFonts.mono,
                        fontSize: 9,
                        color: isLogout ? red : grey,
                      ),
                    ),
                  ),
                const SizedBox(width: 5),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: isLogout ? red : grey,
                ),
              ],
            ),
          ),
        ),
        if (!isLogout)
          const Divider(
            height: 1,
            color: line,
            indent: 14,
            endIndent: 14,
          ),
      ],
    );
  }

  Widget _footer() {
    return const Center(
      child: Text(
        'ExpenseSnap · Hồ sơ cá nhân\n'
        'Lưu trữ cục bộ mã hóa an toàn tại thiết bị',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: AppFonts.mono,
          fontSize: 10,
          height: 1.8,
          color: grey,
        ),
      ),
    );
  }

  Widget _bottomNav() {
    return Container(
      padding: const EdgeInsets.fromLTRB(5, 8, 5, 5),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: line)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _navItem(Icons.receipt_long_outlined, 'Trang chủ', () {
              Navigator.of(context).pop();
            }),
            _navItem(Icons.account_balance_wallet_outlined,
                'Giao dịch', _comingSoon),
            _cameraNav(),
            _navItem(Icons.bar_chart_outlined,
                'Thống kê', _comingSoon),
            _navItem(Icons.person, 'Cá nhân', () {}, selected: true),
          ],
        ),
      ),
    );
  }

  Widget _navItem(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool selected = false,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: selected ? red : grey,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 9,
                color: selected ? red : grey,
                fontWeight: selected
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cameraNav() {
    return Expanded(
      child: InkWell(
        onTap: _comingSoon,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: const BoxDecoration(
                color: red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 3),
            const Text(
              'Chụp hóa đơn',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 9,
                color: red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
