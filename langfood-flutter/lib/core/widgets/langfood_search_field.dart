import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';

/// Ô tìm kiếm (Search Field) chuẩn phong cách Apple iOS Search Bar
/// - Chiều cao 46px
/// - Bo góc 12px
/// - Hỗ trợ cả chế độ nhập liệu trực tiếp hoặc chế độ nút giả (readOnly để điều hướng)
class LangFoodSearchField extends StatefulWidget {
  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final bool readOnly;
  final bool autoFocus;

  const LangFoodSearchField({
    super.key,
    this.controller,
    this.hintText = 'Tìm món ăn, trà sữa, quán ăn KTX...',
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.readOnly = false,
    this.autoFocus = false,
  });

  @override
  State<LangFoodSearchField> createState() => _LangFoodSearchFieldState();
}

class _LangFoodSearchFieldState extends State<LangFoodSearchField> {
  late TextEditingController _effectiveController;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _effectiveController = widget.controller ?? TextEditingController();
    _hasText = _effectiveController.text.isNotEmpty;
    _effectiveController.addListener(_handleTextChange);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _effectiveController.dispose();
    } else {
      _effectiveController.removeListener(_handleTextChange);
    }
    super.dispose();
  }

  void _handleTextChange() {
    final hasNow = _effectiveController.text.isNotEmpty;
    if (hasNow != _hasText) {
      setState(() => _hasText = hasNow);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.langFoodTheme;
    final isDark = context.isDarkMode;

    final bg = isDark ? theme.surfaceContainerLow : theme.surfaceContainerLow;

    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: theme.borderSubtle, width: 0.5),
      ),
      child: TextField(
        controller: _effectiveController,
        readOnly: widget.readOnly,
        autofocus: widget.autoFocus,
        onTap: widget.onTap,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        textAlignVertical: TextAlignVertical.center,
        style: AppTypography.bodyMd.copyWith(color: theme.textPrimary),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          hintText: widget.hintText,
          hintStyle: AppTypography.bodyMd.copyWith(color: theme.textSecondary),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          prefixIcon: Icon(
            Icons.search_rounded,
            color: theme.textSecondary,
            size: 22,
          ),
          suffixIcon: _hasText && !widget.readOnly
              ? GestureDetector(
                  onTap: () {
                    _effectiveController.clear();
                    widget.onChanged?.call('');
                  },
                  child: Icon(
                    Icons.cancel_rounded,
                    color: theme.textSecondary,
                    size: 18,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
