import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/display_format.dart';
import '../../../../core/widgets/langfood_card.dart';
import '../../../../core/widgets/langfood_status_badge.dart';
import '../../../../data/models/order_model.dart';

class MyOrderCard extends StatelessWidget {
  const MyOrderCard({
    super.key,
    required this.order,
    this.onOpen,
    this.onCancel,
  });

  final OrderModel order;
  final VoidCallback? onOpen;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final colors = context.langFoodTheme;
    final scheme = Theme.of(context).colorScheme;
    final (variant, icon) = switch (order.status) {
      'Completed' => (StatusBadgeVariant.success, Icons.check_circle_outline),
      'Cancelled' ||
      'Canceled' => (StatusBadgeVariant.error, Icons.cancel_outlined),
      'Preparing' => (StatusBadgeVariant.warning, Icons.restaurant_rounded),
      'Delivering' ||
      'PickingUp' => (StatusBadgeVariant.info, Icons.delivery_dining),
      'Ready' => (StatusBadgeVariant.info, Icons.shopping_bag_outlined),
      'Pending' ||
      'PendingPayment' => (StatusBadgeVariant.warning, Icons.schedule),
      _ => (StatusBadgeVariant.neutral, Icons.info_outline),
    };
    final fee = order.shippingFee;
    final building = order.deliveryBuilding?.trim();
    final room = order.deliveryRoom?.trim();
    final destination = [
      if (building != null && building.isNotEmpty) building,
      if (room != null && room.isNotEmpty && room != building) room,
    ].join(' · ');
    final openLabel = order.isFinished ? 'Xem chi tiết' : 'Theo dõi đơn';

    return LangFoodCard(
      showShadow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Text(
                  order.id == null ? 'Đơn hàng' : 'Đơn #${order.id}',
                  style: AppTypography.currencyDisplay.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                LangFoodStatusBadge(
                  label: order.statusLabel,
                  variant: variant,
                  icon: icon,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dateText(order.createdAt),
            style: AppTypography.bodySm.copyWith(color: colors.textSecondary),
          ),
          const Divider(height: 24),
          if (order.orderItems.isEmpty)
            Text(
              'Chưa có thông tin món',
              style: AppTypography.bodySm.copyWith(color: colors.textSecondary),
            ),
          for (final item in order.orderItems)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item.quantity}×',
                    style: AppTypography.counterDisplay.copyWith(
                      color: scheme.secondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.productName ?? 'Món #${item.productId}',
                      style: AppTypography.bodyMd,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: AppTokens.borderRadiusMd,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: scheme.secondary,
                  size: 19,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    destination.isEmpty ? 'Chưa có địa chỉ giao' : destination,
                    style: AppTypography.bodySm.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _AmountLine(label: 'Tiền món', value: money(order.totalAmount)),
          const SizedBox(height: 3),
          _AmountLine(label: 'Phí giao', value: money(fee)),
          if (fee != null) ...[
            const SizedBox(height: 6),
            _AmountLine(
              label: 'Tổng thanh toán',
              value: money(order.totalAmount + fee),
              emphasize: true,
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (order.isFinished)
                OutlinedButton.icon(
                  onPressed: onOpen,
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: Text(openLabel),
                )
              else
                FilledButton.icon(
                  onPressed: onOpen,
                  icon: const Icon(Icons.route_outlined),
                  label: Text(openLabel),
                ),
              if (order.canCancel)
                TextButton(onPressed: onCancel, child: const Text('Hủy đơn')),
            ],
          ),
        ],
      ),
    );
  }
}

class _AmountLine extends StatelessWidget {
  const _AmountLine({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final colors = context.langFoodTheme;
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        spacing: 8,
        runSpacing: 2,
        children: [
          Text(
            label,
            style: emphasize
                ? AppTypography.titleMd.copyWith(color: colors.textPrimary)
                : AppTypography.bodySm.copyWith(color: colors.textSecondary),
          ),
          Text(
            value,
            style: emphasize
                ? AppTypography.currencyDisplay.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  )
                : AppTypography.bodySm.copyWith(color: colors.textPrimary),
          ),
        ],
      ),
    );
  }
}
