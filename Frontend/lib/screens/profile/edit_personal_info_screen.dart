import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_theme.dart';
import '../../services/personal_profile_service.dart';

class EditPersonalInfoScreen extends StatefulWidget {
  const EditPersonalInfoScreen({super.key});

  @override
  State<EditPersonalInfoScreen> createState() => _EditPersonalInfoScreenState();
}

class _EditPersonalInfoScreenState extends State<EditPersonalInfoScreen> {
  static const _red = Color(0xFFBD3324);
  static const _ink = Color(0xFF302B27);
  static const _grey = Color(0xFF817970);
  static const _cream = Color(0xFFFFF8F2);
  static const _line = Color(0xFFECE5DF);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _profileService = PersonalProfileService();
  final _imagePicker = ImagePicker();
  Uint8List? _avatarBytes;
  String? _photoUrl;
  String? _birthDate;
  String? _avatarContentType;
  bool _loading = true;
  bool _saving = false;
  bool _removeAvatar = false;

  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    _nameController.text = _user?.displayName?.trim() ?? '';
    _photoUrl = _user?.photoURL;
    try {
      final profile = await _profileService.load();
      if (!mounted) return;
      _nameController.text = profile.fullName;
      _phoneController.text = profile.phoneNumber;
      _birthDate = profile.dateOfBirth;
      _birthDateController.text = _formatDate(profile.dateOfBirth);
      _photoUrl = profile.photoUrl;
    } catch (_) {
      if (mounted) {
        _showMessage('Không tải được hồ sơ. Kiểm tra kết nối và quyền Firebase.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '';
    final date = DateTime.tryParse(isoDate);
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _selectAvatar(ImageSource source) async {
    try {
      final image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() {
        _avatarBytes = bytes;
        _avatarContentType = image.mimeType;
        _removeAvatar = false;
      });
    } catch (_) {
      if (mounted) _showMessage('Không thể mở ảnh. Hãy thử chọn ảnh khác.');
    }
  }

  Future<void> _chooseAvatar() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: _red),
              title: const Text('Chọn ảnh từ thư viện'),
              onTap: () {
                Navigator.pop(sheetContext);
                _selectAvatar(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: _red),
              title: const Text('Chụp ảnh mới'),
              onTap: () {
                Navigator.pop(sheetContext);
                _selectAvatar(ImageSource.camera);
              },
            ),
            if (_photoUrl != null || _avatarBytes != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: _red),
                title: const Text('Xóa ảnh đại diện'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  setState(() {
                    _avatarBytes = null;
                    _photoUrl = null;
                    _removeAvatar = true;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectBirthDate() async {
    final now = DateTime.now();
    final initialDate = _birthDate == null
        ? DateTime(now.year - 18, now.month, now.day)
        : DateTime.tryParse(_birthDate!) ?? DateTime(now.year - 18);
    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year, now.month, now.day),
      helpText: 'Chọn ngày sinh',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );
    if (selected == null || !mounted) return;
    final date = DateTime(selected.year, selected.month, selected.day);
    setState(() {
      _birthDate = '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';
      _birthDateController.text = _formatDate(_birthDate);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = _user;
    if (user == null) {
      _showMessage('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
      return;
    }

    setState(() => _saving = true);
    try {
      var photoUrl = _photoUrl;
      if (_avatarBytes != null) {
        photoUrl = await _profileService.uploadAvatar(
          _avatarBytes!,
          contentType: _avatarContentType,
        );
      } else if (_removeAvatar) {
        photoUrl = null;
      }
      await _profileService.save(
        fullName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        dateOfBirth: _birthDate,
        photoUrl: photoUrl,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      final message = switch (error.code) {
        'network-request-failed' => 'Không có kết nối mạng. Hãy thử lại.',
        'requires-recent-login' => 'Vui lòng đăng nhập lại rồi cập nhật thông tin.',
        _ => error.message ?? 'Không thể cập nhật thông tin lúc này.',
      };
      _showMessage(message);
    } catch (error) {
      if (mounted) {
        final message = error is FirebaseException && error.code == 'permission-denied'
            ? 'Firebase chưa cấp quyền lưu hồ sơ. Cần cấu hình Firestore và Storage Rules.'
            : 'Không thể cập nhật thông tin lúc này. Hãy thử lại.';
        _showMessage(message);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final email = _user?.email ?? 'Chưa có email';

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFAF6),
        foregroundColor: _ink,
        elevation: 0,
        title: const Text(
          'Chỉnh sửa thông tin',
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_loading) ...[
                  const LinearProgressIndicator(color: _red),
                  const SizedBox(height: 16),
                ],
                const Text(
                  'THÔNG TIN CÁ NHÂN',
                  style: TextStyle(
                    fontFamily: AppFonts.mono,
                    fontSize: 10,
                    letterSpacing: 1,
                    color: _grey,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Cập nhật hồ sơ của bạn',
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tên, ảnh, số điện thoại và ngày sinh trong hồ sơ của bạn.',
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 13,
                    color: _grey,
                  ),
                ),
                const SizedBox(height: 24),
                Center(child: _avatarEditor()),
                const SizedBox(height: 22),
                _fieldLabel('HỌ VÀ TÊN'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  maxLength: 150,
                  style: const TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 14,
                    color: _ink,
                  ),
                  decoration: _decoration('Nhập họ và tên', Icons.person_outline),
                  validator: (value) {
                    final name = value?.trim() ?? '';
                    if (name.isEmpty) return 'Vui lòng nhập họ và tên.';
                    if (name.length > 150) return 'Tên tối đa 150 ký tự.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _fieldLabel('SỐ ĐIỆN THOẠI'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 20,
                  style: const TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 14,
                    color: _ink,
                  ),
                  decoration: _decoration('Ví dụ: 0912 345 678', Icons.phone_outlined),
                  validator: (value) {
                    final phone = value?.trim() ?? '';
                    if (phone.isEmpty) return null;
                    final digits = phone.replaceAll(RegExp(r'\D'), '');
                    if (!RegExp(r'^\+?[0-9\s().-]{7,20}$').hasMatch(phone) ||
                        digits.length < 7 ||
                        digits.length > 15) {
                      return 'Số điện thoại chưa đúng định dạng.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 4),
                _fieldLabel('NGÀY SINH · KHÔNG BẮT BUỘC'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _birthDateController,
                  readOnly: true,
                  onTap: _selectBirthDate,
                  style: const TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 14,
                    color: _ink,
                  ),
                  decoration: _decoration(
                    'Chọn ngày sinh',
                    Icons.calendar_month_outlined,
                  ).copyWith(
                    suffixIcon: _birthDate == null
                        ? const Icon(Icons.expand_more, color: _grey)
                        : IconButton(
                            onPressed: () => setState(() {
                              _birthDate = null;
                              _birthDateController.clear();
                            }),
                            icon: const Icon(Icons.close, color: _grey),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                _fieldLabel('EMAIL ĐĂNG NHẬP'),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: email,
                  readOnly: true,
                  style: const TextStyle(
                    fontFamily: AppFonts.mono,
                    fontSize: 12,
                    color: _grey,
                  ),
                  decoration: _decoration('Email đăng nhập', Icons.mail_outline)
                      .copyWith(
                    filled: true,
                    fillColor: const Color(0xFFF3EFEB),
                    helperText: 'Email hiện chưa thể thay đổi tại đây.',
                    helperStyle: const TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 11,
                      color: _grey,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _saving || _loading ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 17,
                            height: 17,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined, size: 18),
                    label: Text(_saving ? 'Đang lưu...' : 'Lưu thông tin'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _red,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _red.withOpacity(0.65),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      textStyle: const TextStyle(
                        fontFamily: AppFonts.body,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: _line),
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: const Text(
                    'Tên được lưu vào hồ sơ tài khoản của bạn. Email được giữ làm thông tin đăng nhập.',
                    style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 12,
                      height: 1.5,
                      color: _grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _avatarEditor() {
    ImageProvider<Object>? imageProvider;
    if (_avatarBytes != null) {
      imageProvider = MemoryImage(_avatarBytes!);
    } else if (_photoUrl != null && _photoUrl!.isNotEmpty) {
      imageProvider = NetworkImage(_photoUrl!);
    }

    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: const Color(0xFFF1EAE4),
              backgroundImage: imageProvider,
              child: imageProvider == null
                  ? const Icon(Icons.person_outline, color: _grey, size: 48)
                  : null,
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Material(
                color: _red,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _chooseAvatar,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.edit, color: Colors.white, size: 17),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'ẢNH ĐẠI DIỆN',
          style: TextStyle(
            fontFamily: AppFonts.mono,
            fontSize: 9,
            letterSpacing: 0.8,
            color: _grey,
          ),
        ),
      ],
    );
  }

  Widget _fieldLabel(String label) => Text(
        label,
        style: const TextStyle(
          fontFamily: AppFonts.mono,
          fontSize: 9,
          letterSpacing: 0.8,
          color: _grey,
        ),
      );

  InputDecoration _decoration(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 19, color: _grey),
        counterText: '',
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
        hintStyle: const TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 13,
          color: _grey,
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
      );
}
