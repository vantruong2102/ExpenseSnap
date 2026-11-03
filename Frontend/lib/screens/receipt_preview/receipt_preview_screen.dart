import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_theme.dart';
import '../../services/api_exception.dart';
import '../../services/receipt_service.dart';
import '../../widgets/dashed_line.dart';
import '../../widgets/stamp_tag.dart';
import '../../widgets/washi_tape.dart';

/// Figma node 9:589 – "Sổ Hóa Đơn" right after taking the photo.
/// Sprint 1 keeps the photo card and the "Chụp lại / Lưu" bar; amount, category and note
/// sections of that frame belong to the "Thêm khoản chi" story (Sprint 2).
/// Pops with the saved [Receipt].
class ReceiptPreviewScreen extends StatefulWidget {
  const ReceiptPreviewScreen({super.key, required this.image, this.receiptService, this.ticketNumber = 1});

  final XFile image;
  final ReceiptService? receiptService;
  final int ticketNumber;

  @override
  State<ReceiptPreviewScreen> createState() => _ReceiptPreviewScreenState();
}

class _ReceiptPreviewScreenState extends State<ReceiptPreviewScreen> {
  late final ReceiptService _receiptService = widget.receiptService ?? ReceiptService();
  late final Future<Uint8List> _imageBytes = widget.image.readAsBytes();
  final DateTime _capturedAt = DateTime.now();
  bool _isUploading = false;

  String get _capturedTime =>
      '${_capturedAt.hour.toString().padLeft(2, '0')}:${_capturedAt.minute.toString().padLeft(2, '0')}';

  String get _capturedDate =>
      '${_capturedAt.day.toString().padLeft(2, '0')}/${_capturedAt.month.toString().padLeft(2, '0')}/${_capturedAt.year}';

  Future<void> _save() async {
    setState(() => _isUploading = true);
    try {
      final receipt = await _receiptService.uploadReceipt(widget.image);
      if (!mounted) return;
      Navigator.of(context).pop(receipt);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        toolbarHeight: 56,
        leading: IconButton(
          tooltip: 'Quay lại',
          icon: const Icon(Icons.arrow_back),
          onPressed: _isUploading ? null : () => Navigator.of(context).pop(),
        ),
        title: Column(
          children: [
            const Text(
              'Sổ Hóa Đơn',
              style: TextStyle(fontSize: 16, height: 24 / 16, fontWeight: FontWeight.w700, letterSpacing: -0.4),
            ),
            Text(
              'TICKET #${widget.ticketNumber.toString().padLeft(4, '0')}-VN',
              style: AppTheme.monoLabel.copyWith(letterSpacing: 0.22),
            ),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.content_cut, size: 22, color: AppColors.textPrimary),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    _buildPhotoCard(),
                    const SizedBox(height: 24),
                    Expanded(child: _buildLargePreview()),
                    const SizedBox(height: 16),
                    _buildSummaryRow(),
                  ],
                ),
              ),
            ),
            _buildActionBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoCard() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: AppColors.paper,
            border: Border.all(color: AppColors.cardBorder),
            borderRadius: BorderRadius.circular(8),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.chip,
                  border: Border.all(color: const Color(0x1A1D1B18)),
                  borderRadius: BorderRadius.circular(4),
                ),
                clipBehavior: Clip.antiAlias,
                child: _ImageBytes(future: _imageBytes, fit: BoxFit.cover),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Flexible(child: Text('VỪA CHỤP • HÔM NAY $_capturedTime', style: AppTheme.monoLabel)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Hóa đơn mới',
                      style: TextStyle(
                        fontSize: 16,
                        height: 24 / 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Kiểm tra ảnh rõ nét trước khi lưu',
                      style: TextStyle(fontSize: 12, height: 18 / 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    StampTag(_isUploading ? 'ĐANG LƯU' : 'CHỜ LƯU', fontSize: 10, filled: true),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Positioned(
          top: -12,
          left: 0,
          right: 0,
          child: Center(child: WashiTape(width: 112, height: 24, angleDegrees: -2.5)),
        ),
      ],
    );
  }

  Widget _buildLargePreview() {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(8),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('ẢNH HÓA ĐƠN', style: AppTheme.monoLabel.copyWith(letterSpacing: 1.1))),
              Text(
                'MÃ: ${widget.ticketNumber.toString().padLeft(4, '0')}',
                style: AppTheme.monoLabel.copyWith(
                  color: const Color(0xFF8D706B),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          const DashedLine(color: AppColors.line),
          const SizedBox(height: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: ColoredBox(
                color: AppColors.chip,
                child: _ImageBytes(future: _imageBytes, fit: BoxFit.contain),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('LƯU VÀO: SỔ HÓA ĐƠN', style: AppTheme.monoLabel.copyWith(letterSpacing: 0.22)),
          Text('NGÀY: $_capturedDate', style: AppTheme.monoLabel.copyWith(letterSpacing: 0.22)),
        ],
      ),
    );
  }

  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(top: BorderSide(color: Color(0x1A1D1B18))),
        boxShadow: [BoxShadow(color: Color(0x08000000), offset: Offset(0, -4), blurRadius: 6)],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isUploading ? null : () => Navigator.of(context).pop(),
              icon: const Icon(Icons.photo_camera_outlined, size: 18),
              label: const Text('Chụp lại'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFCF442F),
                textStyle: const TextStyle(fontFamily: AppFonts.body, fontSize: 16, fontWeight: FontWeight.w700),
              ),
              onPressed: _isUploading ? null : _save,
              icon: _isUploading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Icon(Icons.check, size: 18),
              label: Text(_isUploading ? 'Đang lưu...' : 'Lưu'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageBytes extends StatelessWidget {
  const _ImageBytes({required this.future, required this.fit});

  final Future<Uint8List> future;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: future,
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        return Image.memory(bytes, fit: fit);
      },
    );
  }
}
