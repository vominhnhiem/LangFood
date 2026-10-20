import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';

/// Khung đáy chuẩn Apple iOS Sheet Presentation (Level 3 Elevation)
/// - Bo góc trên 24px
/// - Thanh kéo (drag indicator) 36px x 4px căn giữa
/// - Header tiêu đề và nút đóng (X)
/// - Vùng hành động dính đáy (Sticky CTA) an toàn với SafeArea
class LangFoodBottomSheetShell extends StatelessWidget {
  final String? title;
  final Widget child;
  final Widget? bottomAction;
  final VoidCallback? onClose;
  final bool showCloseButton;
  final double? maxHeightFactor;

  const LangFoodBottomSheetShell({
    super.key,
    this.title,
    required this.child,
    this.bottomAction,
    this.onClose,
    this.showCloseButton = true,
    this.maxHeightFactor = 0.90,
  });

  /// Phương thức tĩnh mở Modal Bottom Sheet chuẩn
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    Widget? bottomAction,
    bool isScrollControlled = true,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (ctx) => LangFoodBottomSheetShell(
        title: title,
        bottomAction: bottomAction,
        onClose: () => Navigator.pop(ctx),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.langFoodTheme;
    final isDark = context.isDarkMode;

    return Container(
      constraints: BoxConstraints(
        maxHeight:
            MediaQuery.of(context).size.height * (maxHeightFactor ?? 0.9),
      ),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: AppTokens.borderRadiusSheet,
        boxShadow: AppTokens.shadowLevel3,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Indicator Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header (Title & Close Button)
            if (title != null || showCloseButton)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.marginMobile,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    if (title != null)
                      Expanded(
                        child: Text(
                          title!,
                          style: AppTypography.titleMd.copyWith(
                            color: theme.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      const Spacer(),
                    if (showCloseButton)
                      GestureDetector(
                        onTap: onClose ?? () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: theme.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            // Body Content
            Flexible(child: child),

            // Sticky Bottom Action Area
            if (bottomAction != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.marginMobile,
                  vertical: AppTokens.spaceSm,
                ),
                decoration: BoxDecoration(
                  color: theme.card,
                  border: Border(
                    top: BorderSide(color: theme.borderSubtle, width: 0.5),
                  ),
                ),
                child: bottomAction!,
              ),
          ],
        ),
      ),
    );
  }
}
