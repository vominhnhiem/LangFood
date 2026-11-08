import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/app_motion.dart';
import '../../../../core/utils/display_format.dart';
import 'seller_dashboard_demo.dart';

abstract final class SellerColors {
  static const canvas = Color(0xFFF8F9FA);
  static const ink = Color(0xFF17261F);
  static const muted = Color(0xFF52615A);
  static const line = Color(0xFFE3EAE5);
  static const brand = Color(0xFFFF5722);
  static const brandInk = Color(0xFF9B351A);
  static const green = Color(0xFF2ECC71);
  static const greenInk = Color(0xFF155638);
  static const greenWash = Color(0xFFE6F7ED);
  static const amber = Color(0xFFFF9800);
  static const amberInk = Color(0xFF874402);
  static const amberWash = Color(0xFFFFF1D9);
  static const blue = Color(0xFF4298E8);
  static const blueInk = Color(0xFF194C84);
  static const blueWash = Color(0xFFE9F3FF);
  static const red = Color(0xFFE74C3C);
  static const redInk = Color(0xFF9F2820);
  static const redWash = Color(0xFFFCECE9);
  static const grayWash = Color(0xFFEFF2F0);
}

const sellerDigits = [FontFeature.tabularFigures()];
const sellerShape = RoundedSuperellipseBorder(
  borderRadius: AppTokens.borderRadiusLg,
);
const sellerButtonSize = Size(48, 56);

({Color accent, Color ink, Color wash, IconData icon}) sellerQueueTone(
  SellerQueue queue,
) => switch (queue) {
  SellerQueue.incoming => (
    accent: SellerColors.green,
    ink: SellerColors.greenInk,
    wash: SellerColors.greenWash,
    icon: Icons.receipt_long_outlined,
  ),
  SellerQueue.cooking => (
    accent: SellerColors.amber,
    ink: SellerColors.amberInk,
    wash: SellerColors.amberWash,
    icon: Icons.soup_kitchen_outlined,
  ),
  SellerQueue.pickup => (
    accent: SellerColors.blue,
    ink: SellerColors.blueInk,
    wash: SellerColors.blueWash,
    icon: Icons.delivery_dining_outlined,
  ),
  SellerQueue.history => (
    accent: SellerColors.muted,
    ink: SellerColors.muted,
    wash: SellerColors.grayWash,
    icon: Icons.history_rounded,
  ),
};

String sellerTimeLeft(DateTime deadline, DateTime now) {
  final milliseconds = deadline.difference(now).inMilliseconds;
  final seconds = milliseconds <= 0 ? 0 : (milliseconds + 999) ~/ 1000;
  return '${(seconds ~/ 60).toString().padLeft(2, '0')}:'
      '${(seconds % 60).toString().padLeft(2, '0')}';
}

class SellerPanel extends StatelessWidget {
  const SellerPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppTokens.spaceMd),
    this.accent,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? accent;

  @override
  Widget build(BuildContext context) => Material(
    color: context.langFoodTheme.card,
    elevation: 0,
    shape: sellerShape.copyWith(
      side: BorderSide(color: accent ?? context.langFoodTheme.borderSubtle),
    ),
    child: Padding(padding: padding, child: child),
  );
}

class LiveStatsHeader extends StatelessWidget {
  const LiveStatsHeader({
    super.key,
    required this.revenue,
    required this.completed,
    required this.cancelled,
    this.revenueLabel = 'Thực nhận',
  });

  final num revenue;
  final int completed;
  final int cancelled;
  final String revenueLabel;

  @override
  Widget build(BuildContext context) {
    final total = completed + cancelled;
    final rate = total == 0
        ? '—'
        : NumberFormat.percentPattern('vi_VN').format(cancelled / total);
    final values = [
      (revenueLabel, money(revenue), context.langFoodTheme.textPrimary),
      (
        'Thành công',
        '$completed',
        context.isDarkMode ? const Color(0xFF7FE6A7) : SellerColors.greenInk,
      ),
      (
        'Tỷ lệ hủy',
        rate,
        context.isDarkMode ? const Color(0xFFFFA69B) : SellerColors.redInk,
      ),
    ];
    return SellerPanel(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked =
              constraints.maxWidth < 270 ||
              MediaQuery.textScalerOf(context).scale(16) > 20;
          final tiles = [
            for (final (label, value, color) in values)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: context.langFoodTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      style: TextStyle(
                        color: color,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        fontFeatures: sellerDigits,
                      ),
                    ),
                  ],
                ),
              ),
          ];
          return stacked
              ? Wrap(spacing: 12, runSpacing: 4, children: tiles)
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 4, child: tiles[0]),
                    Expanded(flex: 3, child: tiles[1]),
                    Expanded(flex: 3, child: tiles[2]),
                  ],
                );
        },
      ),
    );
  }
}

class SellerBadge extends StatelessWidget {
  const SellerBadge(
    this.label, {
    super.key,
    required this.ink,
    required this.wash,
    this.icon,
    this.tabular = false,
  });

  final String label;
  final Color ink;
  final Color wash;
  final IconData? icon;
  final bool tabular;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: wash,
      borderRadius: AppTokens.borderRadiusFull,
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: ink, size: 15),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: ink,
                fontSize: tabular ? 19 : 12,
                fontWeight: FontWeight.w800,
                fontFeatures: tabular ? sellerDigits : null,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class OrderCardItem extends StatelessWidget {
  const OrderCardItem({
    super.key,
    required this.order,
    required this.clock,
    this.onAccept,
    this.onReject,
    this.onReady,
    this.busy = false,
  });

  final SellerOrder order;
  final ValueListenable<DateTime> clock;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onReady;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final status = order.status;
    final tone = sellerQueueTone(status.queue);
    final cancelled = status == SellerOrderStatus.cancelled;
    final deadline = order.acceptBy;
    final date = order.endedAt ?? order.createdAt;
    final timestamp = date == null
        ? null
        : DateFormat(
            status.queue == SellerQueue.history ? 'dd/MM · HH:mm' : 'HH:mm',
          ).format(sellerCampusTime(date));

    return SellerPanel(
      accent: status.queue == SellerQueue.history
          ? null
          : tone.accent.withValues(alpha: 0.52),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.code,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        fontFeatures: sellerDigits,
                      ),
                    ),
                    Text(
                      '${timestamp == null ? '' : '$timestamp · '}${order.portions} phần',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.langFoodTheme.textSecondary,
                        fontFeatures: sellerDigits,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: deadline == null
                    ? SellerBadge(
                        status.label,
                        ink: cancelled ? SellerColors.redInk : tone.ink,
                        wash: cancelled ? SellerColors.redWash : tone.wash,
                        icon: cancelled ? Icons.cancel_outlined : tone.icon,
                      )
                    : ValueListenableBuilder<DateTime>(
                        valueListenable: clock,
                        builder: (context, now, _) {
                          final urgent =
                              deadline.difference(now) <=
                              const Duration(seconds: 30);
                          final time = sellerTimeLeft(deadline, now);
                          return Semantics(
                            label: urgent
                                ? 'Sắp hết giờ xác nhận, còn $time'
                                : 'Còn $time để xác nhận',
                            excludeSemantics: true,
                            child: SellerBadge(
                              time,
                              ink: urgent ? SellerColors.redInk : tone.ink,
                              wash: urgent ? SellerColors.redWash : tone.wash,
                              icon: Icons.timer_outlined,
                              tabular: true,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.location_on_outlined,
                  size: 19,
                  color: context.langFoodTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.customer,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      order.destination,
                      style: TextStyle(
                        color: context.langFoodTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 9),
            child: Divider(height: 1),
          ),
          for (final (index, item) in order.items.indexed) ...[
            if (index != 0) const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SellerBadge(
                  '${item.quantity}×',
                  ink: SellerColors.ink,
                  wash: SellerColors.grayWash,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName ?? 'Món #${item.productId}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (item.optionsSummary case final String options
                          when options.isNotEmpty)
                        Text(
                          'Kèm theo · $options',
                          style: TextStyle(
                            color: context.langFoodTheme.textSecondary,
                          ),
                        ),
                      if (item.note case final String note when note.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 5),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: const BoxDecoration(
                            color: SellerColors.amberWash,
                            borderRadius: AppTokens.borderRadiusSm,
                          ),
                          child: Text(
                            'Lưu ý · $note',
                            style: const TextStyle(
                              color: SellerColors.amberInk,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          if (status.queue == SellerQueue.pickup) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: SellerColors.blueWash,
                borderRadius: AppTokens.borderRadiusMd,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.courier?.name ??
                        (order.shipperId == null
                            ? 'Đang tìm shipper'
                            : 'Shipper #${order.shipperId}'),
                    style: const TextStyle(
                      color: SellerColors.blueInk,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (order.courier case final courier?)
                    Text(
                      '${courier.phone} · ${courier.plate}',
                      style: const TextStyle(
                        color: SellerColors.blueInk,
                        fontFeatures: sellerDigits,
                      ),
                    ),
                ],
              ),
            ),
          ],
          if (order.cancelReason case final reason?) ...[
            const SizedBox(height: 12),
            Text(
              reason,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (onAccept != null || onReady != null) const SizedBox(height: 16),
          if (onAccept != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (onReject != null) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: busy ? null : onReject,
                      style: OutlinedButton.styleFrom(
                        minimumSize: sellerButtonSize,
                        shape: sellerShape,
                        foregroundColor: Theme.of(context).colorScheme.error,
                        side: BorderSide(
                          color: context.langFoodTheme.borderSubtle,
                        ),
                      ),
                      child: const Text('Từ chối', textAlign: TextAlign.center),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: busy ? null : onAccept,
                    style: FilledButton.styleFrom(
                      minimumSize: sellerButtonSize,
                      shape: sellerShape,
                      backgroundColor: SellerColors.greenInk,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Nhận đơn', textAlign: TextAlign.center),
                  ),
                ),
              ],
            ),
          if (onReady != null)
            FilledButton.icon(
              onPressed: busy ? null : onReady,
              style: FilledButton.styleFrom(
                minimumSize: sellerButtonSize,
                shape: sellerShape,
                backgroundColor: SellerColors.amberWash,
                foregroundColor: SellerColors.amberInk,
              ),
              icon: const Icon(Icons.check_rounded),
              label: const Text('Báo xong món', textAlign: TextAlign.center),
            ),
        ],
      ),
    );
  }
}

class QuickStockSheet extends StatelessWidget {
  const QuickStockSheet({
    super.key,
    required this.stock,
    required this.onChanged,
  });

  final ValueListenable<List<SellerStockItem>> stock;
  final void Function(int id, bool available) onChanged;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Hết món nhanh',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            IconButton(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              tooltip: 'Đóng',
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
        Text(
          'Gạt tắt để ẩn món hoặc topping khỏi các đơn thử mới.',
          style: TextStyle(color: context.langFoodTheme.textSecondary),
        ),
        const SizedBox(height: 12),
        Flexible(
          child: ValueListenableBuilder<List<SellerStockItem>>(
            valueListenable: stock,
            builder: (context, items, _) => ListView.separated(
              shrinkWrap: true,
              itemCount: items.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = items[index];
                return SwitchListTile(
                  key: ValueKey(item.id),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  title: Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    '${item.isTopping ? 'Topping' : 'Món'} · ${item.available ? 'Đang bán' : 'Đã hết'}',
                    style: TextStyle(
                      color: item.available
                          ? (context.isDarkMode
                                ? const Color(0xFF7FE6A7)
                                : SellerColors.greenInk)
                          : Theme.of(context).colorScheme.error,
                    ),
                  ),
                  activeThumbColor: Colors.white,
                  activeTrackColor: SellerColors.greenInk,
                  value: item.available,
                  onChanged: (value) {
                    AppHaptics.selection();
                    onChanged(item.id, value);
                  },
                );
              },
            ),
          ),
        ),
      ],
    ),
  );
}
