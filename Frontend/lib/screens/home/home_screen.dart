
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/theme/app_theme.dart';
import '../receipt_capture/receipt_capture_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const Color red = Color(0xFFBA3020);
  static const Color ink = Color(0xFF302923);
  static const Color muted = Color(0xFF93877E);
  static const Color paper = Color(0xFFFFFDF9);
  static const Color canvas = Color(0xFFF8F5EF);
  static const Color border = Color(0xFFEDE6DD);

  final List<String> _titles = const [
    'Trang chủ',
    'Giao dịch',
    'Chụp hóa đơn',
    'Thống kê',
    'Cá nhân',
  ];

  // Mở chức năng chụp hóa đơn của thành viên nhóm
  void _openReceiptCapture() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ReceiptCaptureScreen(),
      ),
    );
  }

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ProfileScreen(),
      ),
    );
  }

  void _onTabSelected(int index) {
    if (index == 2) {
      _openReceiptCapture();
      return;
    }
    if (index == 4) {
      _openProfile();
      return;
    }
    if (index == 0) {
      setState(() => _selectedIndex = 0);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Chức năng ${_titles[index]} sẽ được phát triển ở Sprint sau.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: canvas,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  16, 14, 16, 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSummaryCard(),
                    const SizedBox(height: 18),
                    _buildSuggestionCard(),
                    const SizedBox(height: 20),
                    _buildRecentHeader(),
                    const SizedBox(height: 10),
                    _buildRecentTransactions(),
                    const SizedBox(height: 17),
                    _buildManualButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // ================= HEADER =================

  Widget _buildHeader() {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName?.trim();
    final greeting = name != null && name.isNotEmpty
        ? name
        : (user?.email?.split('@').first ?? 'Bạn');

    return Container(
      padding: const EdgeInsets.fromLTRB(17, 12, 17, 12),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFAF5),
        border: Border(
          bottom: BorderSide(color: border),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.receipt_long,
            color: red,
            size: 20,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Sổ Hóa Đơn',
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: ink,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Chào $greeting',
                style: const TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 10,
                  color: muted,
                ),
              ),
              Text(
                'Tháng ${DateTime.now().month}',
                style: const TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: ink,
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: _openProfile,
            borderRadius: BorderRadius.circular(30),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const CircleAvatar(
                  radius: 17,
                  backgroundColor: Color(0xFFF0E8DF),
                  child: Icon(
                    Icons.account_circle_outlined,
                    size: 23,
                    color: ink,
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= SUMMARY =================

  Widget _buildSummaryCard() {
    final now = DateTime.now();

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: paper,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'HÓA ĐƠN TỔNG HỢP · KỲ '
                  '${now.month}/${now.year}',
                  style: const TextStyle(
                    fontFamily: AppFonts.mono,
                    fontSize: 9,
                    color: muted,
                  ),
                ),
              ),
              const Text(
                'NO. ----VN',
                style: TextStyle(
                  fontFamily: AppFonts.mono,
                  fontSize: 9,
                  color: muted,
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),
          const Divider(color: border, height: 1),
          const SizedBox(height: 17),

          const Text(
            'Đã chi tháng này',
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 12,
              color: muted,
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            '— đ',
            style: TextStyle(
              fontFamily: AppFonts.mono,
              fontSize: 35,
              fontWeight: FontWeight.bold,
              color: red,
            ),
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              const Icon(
                Icons.trending_down,
                size: 15,
                color: ink,
              ),
              const SizedBox(width: 5),
              const Expanded(
                child: Text(
                  'Chưa có dữ liệu tháng trước',
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 10,
                    color: ink,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Mục tiêu: chưa đặt',
                style: TextStyle(
                  fontFamily: AppFonts.mono,
                  fontSize: 9,
                  color: muted,
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),
          const Divider(color: border, height: 1),
          const SizedBox(height: 16),

          const Row(
            children: [
              Expanded(
                child: Text(
                  'Nhịp chi 7 ngày qua',
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ink,
                  ),
                ),
              ),
              Text(
                'Chưa có dữ liệu',
                style: TextStyle(
                  fontFamily: AppFonts.mono,
                  fontSize: 9,
                  color: muted,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),
          _buildWeekChart(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildWeekChart() {
    final today = DateTime.now();

    const days = [
      'T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'
    ];

    return SizedBox(
      height: 100,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (index) {
          final date = today.subtract(
            Duration(days: 6 - index),
          );

          final isToday = index == 6;

          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 9,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isToday
                        ? red
                        : const Color(0xFFD3D0CC),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  days[date.weekday - 1],
                  style: TextStyle(
                    fontFamily: AppFonts.mono,
                    fontSize: 10,
                    color: isToday ? red : muted,
                    fontWeight: isToday
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ================= GỢI Ý =================

  Widget _buildSuggestionCard() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(15, 20, 15, 16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFEBD3),
            border: Border.all(
              color: const Color(0xFFF4CEA4),
            ),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Transform.rotate(
                    angle: -0.1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFFB87A2A),
                        ),
                      ),
                      child: const Text(
                        'GỢI Ý',
                        style: TextStyle(
                          fontFamily: AppFonts.mono,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB87A2A),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Ghi lại các khoản chi mỗi ngày '
                      'để theo dõi ngân sách hiệu quả hơn.',
                      style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 12,
                        height: 1.5,
                        color: ink,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 11),
              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '#NhậtKýChiTiêu · ExpenseSnap',
                  style: TextStyle(
                    fontFamily: AppFonts.mono,
                    fontSize: 9,
                    color: Color(0xFFB87A2A),
                  ),
                ),
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
              angle: -0.03,
              child: Container(
                width: 65,
                height: 15,
                color: const Color(0x99E7DFD1),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ================= GIAO DỊCH GẦN ĐÂY =================

  Widget _buildRecentHeader() {
    return Row(
      children: [
        const Text(
          'Gần đây',
          style: TextStyle(
            fontFamily: AppFonts.body,
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: ink,
          ),
        ),
        const SizedBox(width: 7),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 3,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFECE7DF),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            '0 mục',
            style: TextStyle(
              fontFamily: AppFonts.mono,
              fontSize: 9,
              color: muted,
            ),
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: () => _onTabSelected(1),
          child: const Text(
            'Xem tất cả ›',
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 11,
              color: muted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 28,
      ),
      decoration: BoxDecoration(
        color: paper,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: const Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 34,
            color: muted,
          ),
          SizedBox(height: 12),
          Text(
            'Chưa có giao dịch nào',
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: ink,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Các khoản thu chi gần đây sẽ xuất hiện ở đây.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 11,
              color: muted,
            ),
          ),
        ],
      ),
    );
  }

  // ================= NHẬP TAY =================

  Widget _buildManualButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Chức năng nhập tay sẽ được kết nối sau.',
              ),
            ),
          );
        },
        icon: const Icon(
          Icons.add_circle_outline,
          size: 16,
        ),
        label: const Text(
          'NHẬP TAY HÓA ĐƠN KHÔNG CÓ BILL',
          style: TextStyle(
            fontFamily: AppFonts.mono,
            fontSize: 10,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: muted,
          backgroundColor: Colors.white,
          side: const BorderSide(color: border),
          padding: const EdgeInsets.symmetric(
            vertical: 15,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(7),
          ),
        ),
      ),
    );
  }

  // ================= BOTTOM NAVIGATION =================

  Widget _buildBottomNavigation() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFFAF5),
        border: Border(
          top: BorderSide(color: border),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _navItem(0, Icons.receipt_long_outlined),
              _navItem(1, Icons.account_balance_wallet_outlined),
              _cameraNavItem(),
              _navItem(3, Icons.bar_chart_outlined),
              _navItem(4, Icons.person_outline),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon) {
    final selected = _selectedIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => _onTabSelected(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 21,
              color: selected ? red : muted,
            ),
            const SizedBox(height: 5),
            Text(
              _titles[index],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 9,
                fontWeight: selected
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: selected ? red : muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cameraNavItem() {
    return Expanded(
      child: InkWell(
        onTap: _openReceiptCapture,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                color: red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                color: Colors.white,
                size: 23,
              ),
            ),
            const SizedBox(height: 3),
            const Text(
              'Chụp hóa đơn',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 9,
                color: muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
