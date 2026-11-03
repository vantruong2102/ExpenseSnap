import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_theme.dart';
import '../../models/receipt.dart';
import '../../services/api_exception.dart';
import '../../services/receipt_service.dart';
import '../../widgets/dashed_line.dart';
import '../../widgets/stamp_tag.dart';
import '../../widgets/washi_tape.dart';
import '../receipt_preview/receipt_preview_screen.dart';
import 'widgets/scan_frame_overlay.dart';

/// Figma node 1:2 – in-app camera to scan a receipt.
class ReceiptCaptureScreen extends StatefulWidget {
  const ReceiptCaptureScreen({super.key, this.receiptService});

  final ReceiptService? receiptService;

  @override
  State<ReceiptCaptureScreen> createState() => _ReceiptCaptureScreenState();
}

class _ReceiptCaptureScreenState extends State<ReceiptCaptureScreen> with WidgetsBindingObserver {
  final ImagePicker _picker = ImagePicker();
  late final ReceiptService _receiptService = widget.receiptService ?? ReceiptService();

  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  int _cameraIndex = 0;
  bool _isInitializing = true;
  bool _isTakingPicture = false;
  bool _flashOn = false;
  double _zoom = 1;
  String? _cameraError;

  List<Receipt> _receipts = [];

  int get _todayCount {
    final now = DateTime.now();
    return _receipts.where((receipt) {
      final created = receipt.createdAt.toLocal();
      return created.year == now.year && created.month == now.month && created.day == now.day;
    }).length;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
    _loadReceipts();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The camera must be released when the app goes to background and re-opened on resume
    final controller = _controller;
    if (state == AppLifecycleState.inactive && controller != null && controller.value.isInitialized) {
      _controller = null;
      controller.dispose();
      setState(() {});
    } else if (state == AppLifecycleState.resumed && _controller == null && _cameras.isNotEmpty) {
      _startController(_cameras[_cameraIndex]);
    }
  }

  Future<void> _loadReceipts() async {
    try {
      final receipts = await _receiptService.listReceipts();
      if (mounted) setState(() => _receipts = receipts);
    } on ApiException {
      // The header simply shows 0 when the list cannot be loaded
    }
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) throw CameraException('NoCamera', 'Không tìm thấy camera');
      final backIndex = _cameras.indexWhere((camera) => camera.lensDirection == CameraLensDirection.back);
      _cameraIndex = backIndex >= 0 ? backIndex : 0;
      await _startController(_cameras[_cameraIndex]);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _cameraError = 'Không mở được camera. Hãy cấp quyền camera hoặc chọn ảnh từ thư viện.';
      });
    }
  }

  Future<void> _startController(CameraDescription camera) async {
    final controller = CameraController(camera, ResolutionPreset.high, enableAudio: false);
    setState(() => _isInitializing = true);
    try {
      await controller.initialize();
      await controller.setFlashMode(_flashOn ? FlashMode.torch : FlashMode.off).catchError((_) {});
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _zoom = 1;
        _cameraError = null;
      });
    } on CameraException catch (error) {
      await controller.dispose();
      if (!mounted) return;
      setState(() {
        _cameraError = error.code == 'CameraAccessDenied'
            ? 'Bạn chưa cấp quyền camera. Vào Cài đặt để cho phép ExpenseSnap dùng camera.'
            : 'Không mở được camera. Bạn có thể chọn ảnh từ thư viện.';
      });
    } finally {
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  Future<void> _toggleFlash() async {
    final controller = _controller;
    if (controller == null) return;
    final flashOn = !_flashOn;
    try {
      await controller.setFlashMode(flashOn ? FlashMode.torch : FlashMode.off);
      setState(() => _flashOn = flashOn);
    } on CameraException {
      _showMessage('Thiết bị không hỗ trợ đèn flash.');
    }
  }

  Future<void> _toggleZoom() async {
    final controller = _controller;
    if (controller == null) return;
    try {
      final maxZoom = await controller.getMaxZoomLevel();
      final zoom = _zoom == 1 && maxZoom >= 2 ? 2.0 : 1.0;
      await controller.setZoomLevel(zoom);
      setState(() => _zoom = zoom);
    } on CameraException {
      _showMessage('Thiết bị không hỗ trợ phóng to.');
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    final oldController = _controller;
    setState(() => _controller = null);
    await oldController?.dispose();
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    await _startController(_cameras[_cameraIndex]);
  }

  Future<void> _takePicture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isTakingPicture) return;

    setState(() => _isTakingPicture = true);
    try {
      final file = await controller.takePicture();
      await _openPreview(file);
    } on CameraException {
      _showMessage('Chụp ảnh thất bại, vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _isTakingPicture = false);
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 2000);
      if (file != null) await _openPreview(file);
    } catch (_) {
      _showMessage('Không mở được thư viện ảnh.');
    }
  }

  Future<void> _openPreview(XFile image) async {
    final receipt = await Navigator.of(context).push<Receipt>(
      MaterialPageRoute(
        builder: (_) =>
            ReceiptPreviewScreen(image: image, receiptService: _receiptService, ticketNumber: _receipts.length + 1),
      ),
    );
    if (receipt == null || !mounted) return;
    setState(() => _receipts = [receipt, ..._receipts]);
    _showMessage('Đã lưu hóa đơn vào sổ.');
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildGuideRow(),
                    const SizedBox(height: 24),
                    _buildViewfinder(),
                    const SizedBox(height: 24),
                    _buildControlDock(),
                    const SizedBox(height: 12),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final canPop = Navigator.of(context).canPop();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 13),
      decoration: const BoxDecoration(
        color: Color(0xCCFBFAF6),
        border: Border(bottom: BorderSide(color: AppColors.headerBorder)),
      ),
      child: Row(
        children: [
          _CircleButton(
            tooltip: 'Đóng máy ảnh',
            icon: Icons.close,
            onPressed: canPop ? () => Navigator.of(context).pop() : null,
          ),
          Expanded(
            child: Column(
              children: [
                Text('BIÊN BẢN THU CHI', style: AppTheme.monoLabel.copyWith(letterSpacing: 1.1)),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Hôm nay: $_todayCount hóa đơn',
                      style: const TextStyle(
                        fontFamily: AppFonts.mono,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        height: 20 / 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const _CircleButton(tooltip: 'Tài khoản cá nhân', icon: Icons.account_circle_outlined, filled: true),
        ],
      ),
    );
  }

  Widget _buildGuideRow() {
    return Row(
      children: [
        const Icon(Icons.document_scanner_outlined, size: 15, color: AppColors.ink),
        const SizedBox(width: 4),
        Expanded(child: Text('QUÉT TỰ ĐỘNG BIÊN LAI', style: AppTheme.monoLabel.copyWith(letterSpacing: 0.275))),
        StampTag('SỔ HÓA ĐƠN #${(_receipts.length + 1).toString().padLeft(2, '0')}'),
      ],
    );
  }

  Widget _buildViewfinder() {
    final controller = _controller;
    final isReady = controller != null && controller.value.isInitialized;

    Widget preview;
    if (_isInitializing) {
      preview = const Center(child: CircularProgressIndicator(color: Colors.white));
    } else if (!isReady) {
      preview = Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.no_photography_outlined, color: Colors.white54, size: 48),
              const SizedBox(height: 12),
              Text(
                _cameraError ?? 'Camera chưa sẵn sàng.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    } else {
      preview = FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          // previewSize is reported in landscape orientation
          width: controller.value.previewSize?.height ?? 1,
          height: controller.value.previewSize?.width ?? 1,
          child: CameraPreview(controller),
        ),
      );
    }

    return Container(
      height: 460,
      decoration: BoxDecoration(
        color: AppColors.viewfinder,
        border: Border.all(color: const Color(0x331D1B18)),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Color(0x1A000000), offset: Offset(0, 4), blurRadius: 6, spreadRadius: -1),
          BoxShadow(color: Color(0x1A000000), offset: Offset(0, 2), blurRadius: 4, spreadRadius: -2),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          preview,
          Padding(
            padding: const EdgeInsets.all(13),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _HudCircleButton(
                      tooltip: _flashOn ? 'Tắt đèn' : 'Bật đèn',
                      icon: _flashOn ? Icons.flash_on : Icons.flash_off,
                      highlighted: _flashOn,
                      onPressed: isReady ? _toggleFlash : null,
                    ),
                    _HudPill(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(color: AppColors.statusDot, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isReady ? 'ĐANG ĐO KHỔ GIẤY' : 'CHỜ CAMERA',
                            style: AppTheme.monoLabel.copyWith(color: AppColors.canvas, letterSpacing: 1.1),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: isReady ? _toggleZoom : null,
                      child: _HudPill(
                        child: Text(
                          '${_zoom.toStringAsFixed(0)}x',
                          style: AppTheme.monoLabel.copyWith(
                            color: const Color(0xE6FFFFFF),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Expanded(child: ScanFrameOverlay()),
                _HudPill(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  background: const Color(0x80000000),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wb_sunny_outlined, size: 13, color: Color(0xB3FFFFFF)),
                      const SizedBox(width: 6),
                      Text(
                        'Giữ máy phẳng và đủ ánh sáng',
                        style: AppTheme.monoLabel.copyWith(color: const Color(0xB3FFFFFF), letterSpacing: 0.22),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlDock() {
    final canShoot = _controller != null && !_isTakingPicture;
    final latestImage = _receipts.isEmpty ? null : _receipts.first.imageUrl;

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.dock,
        border: Border.all(color: AppColors.softBorder),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), offset: Offset(0, 1), blurRadius: 1)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _DockAction(
                label: 'Thư viện',
                onTap: _pickFromGallery,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: AppColors.canvas,
                        border: Border.all(color: const Color(0x4D8D706B)),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: const [BoxShadow(color: Color(0x0D000000), offset: Offset(0, 1), blurRadius: 2)],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: latestImage == null
                            ? const Icon(Icons.photo_library_outlined, color: AppColors.textSecondary)
                            : Image.network(
                                latestImage,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    const Icon(Icons.photo_library_outlined, color: AppColors.textSecondary),
                              ),
                      ),
                    ),
                    const Positioned(top: -8, child: WashiTape(width: 32, height: 14, angleDegrees: -3)),
                  ],
                ),
              ),
              Semantics(
                button: true,
                label: 'Bấm chụp hóa đơn',
                child: GestureDetector(
                  onTap: canShoot ? _takePicture : null,
                  child: _ShutterButton(enabled: canShoot, busy: _isTakingPicture),
                ),
              ),
              _DockAction(
                label: 'Đổi góc',
                onTap: _cameras.length > 1 && _controller != null ? _switchCamera : null,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.chip,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.softBorder),
                  ),
                  child: const Icon(Icons.flip_camera_android_outlined, size: 22, color: AppColors.textBrown),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const DashedLine(color: Color(0x99E1BFB8)),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => _showMessage('Lịch hóa đơn sẽ có trong Sprint 2.'),
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Lịch hóa đơn', style: AppTheme.monoLabel),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final small = AppTheme.monoLabel.copyWith(fontSize: 9, height: 1.5, letterSpacing: 0);
    return Column(
      children: [
        Opacity(
          opacity: 0.3,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('--- CẮT TẠI ĐÂY ---', style: small),
                Text('EXPENSESNAP v1.0', style: small),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Sổ tay kiểm soát chi tiêu • Chụp rõ ngày & tổng tiền',
          textAlign: TextAlign.center,
          style: AppTheme.monoLabel.copyWith(letterSpacing: 0.22),
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.tooltip, required this.icon, this.onPressed, this.filled = false});

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onPressed,
        radius: 20,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: filled ? AppColors.chip : null,
            shape: BoxShape.circle,
            border: Border.all(color: filled ? const Color(0x80E1BFB8) : AppColors.softBorder),
          ),
          child: Icon(icon, size: filled ? 20 : 18, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

class _HudPill extends StatelessWidget {
  const _HudPill({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
    this.background = const Color(0x80000000),
  });

  final Widget child;
  final EdgeInsets padding;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      child: child,
    );
  }
}

class _HudCircleButton extends StatelessWidget {
  const _HudCircleButton({required this.tooltip, required this.icon, this.onPressed, this.highlighted = false});

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onPressed,
        radius: 20,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0x66000000),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0x1AFFFFFF)),
          ),
          child: Icon(icon, size: 18, color: highlighted ? const Color(0xFFFFD54F) : Colors.white),
        ),
      ),
    );
  }
}

class _DockAction extends StatelessWidget {
  const _DockAction({required this.label, required this.child, this.onTap});

  final String label;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            child,
            const SizedBox(height: 6),
            Text(label, style: AppTheme.monoLabel.copyWith(letterSpacing: 0.275)),
          ],
        ),
      ),
    );
  }
}

/// 72px ink ring → cream disc → 44px red disc with a camera icon.
class _ShutterButton extends StatelessWidget {
  const _ShutterButton({required this.enabled, required this.busy});

  final bool enabled;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.ink, width: 2),
        boxShadow: const [BoxShadow(color: Color(0x1A000000), offset: Offset(0, 4), blurRadius: 6, spreadRadius: -1)],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.dock,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0x99E1BFB8)),
        ),
        alignment: Alignment.center,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: enabled ? AppColors.ink : AppColors.ink.withValues(alpha: 0.4),
            shape: BoxShape.circle,
          ),
          child: busy
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                )
              : const Icon(Icons.photo_camera, size: 20, color: Colors.white),
        ),
      ),
    );
  }
}
