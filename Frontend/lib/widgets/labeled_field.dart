import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Underlined form field from the Figma "Đăng ký" screen: mono label on the left,
/// step code ("01/NHẬP TÊN") on the right, icon at the end of the line and an inline
/// error row with an "!" icon. The label turns stamp-red while the field has an error.
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.stepLabel,
    required this.controller,
    this.icon,
    this.hintText,
    this.errorText,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.monoValue = false,
    this.onToggleObscure,
    this.onFieldSubmitted,
  });

  final String label;
  final String stepLabel;
  final TextEditingController controller;
  final IconData? icon;
  final String? hintText;

  /// Error coming from the server; shown in addition to [validator] errors.
  final String? errorText;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final bool obscureText;

  /// Render the value in Space Mono (email, passwords) instead of Be Vietnam Pro.
  final bool monoValue;

  /// When set, the trailing icon becomes a show/hide password button.
  final VoidCallback? onToggleObscure;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: controller.text,
      validator: (_) => validator?.call(controller.text),
      builder: (field) {
        final error = field.errorText ?? errorText;
        final hasError = error != null;
        final labelColor = hasError ? AppColors.ink : AppColors.textSecondary;
        final valueStyle = obscureText
            ? TextStyle(
                fontFamily: AppFonts.mono,
                fontWeight: FontWeight.w700,
                fontSize: 18,
                height: 20 / 18,
                letterSpacing: 1.8,
                color: hasError ? AppColors.ink : AppColors.textPrimary,
              )
            : TextStyle(
                fontFamily: monoValue ? AppFonts.mono : AppFonts.body,
                fontSize: 14,
                height: 20 / 14,
                color: AppColors.textPrimary,
              );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    label.toUpperCase(),
                    style: AppTheme.monoLabel.copyWith(
                      color: labelColor,
                      fontWeight: hasError ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
                Opacity(
                  opacity: hasError ? 1 : 0.6,
                  child: Text(
                    stepLabel,
                    style: AppTheme.monoLabel.copyWith(
                      letterSpacing: 0.22,
                      color: hasError ? AppColors.ink : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            TextField(
              controller: controller,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              textCapitalization: textCapitalization,
              obscureText: obscureText,
              obscuringCharacter: '•',
              autocorrect: !obscureText && !monoValue,
              onSubmitted: onFieldSubmitted,
              onChanged: field.didChange,
              style: valueStyle,
              cursorColor: AppColors.textPrimary,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: valueStyle.copyWith(color: const Color(0x591D1B18), letterSpacing: 0),
                enabledBorder: hasError
                    ? const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.ink))
                    : null,
                suffixIconConstraints: const BoxConstraints(minWidth: 28, minHeight: 24),
                suffixIcon: _buildTrailingIcon(hasError),
              ),
            ),
            if (hasError) ...[
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Icon(Icons.error, size: 14, color: AppColors.ink),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(error, style: AppTheme.monoLabel.copyWith(color: AppColors.ink, letterSpacing: -0.275)),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  Widget? _buildTrailingIcon(bool hasError) {
    final color = hasError && onToggleObscure != null ? AppColors.ink : const Color(0x801D1B18);
    if (onToggleObscure != null) {
      return IconButton(
        tooltip: obscureText ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 28, minHeight: 24),
        style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
        iconSize: 20,
        color: color,
        icon: Icon(obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined),
        onPressed: onToggleObscure,
      );
    }
    if (icon == null) return null;
    return Icon(icon, size: 20, color: color);
  }
}
