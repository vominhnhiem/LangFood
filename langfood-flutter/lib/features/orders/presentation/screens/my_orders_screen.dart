import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_motion.dart';
import '../../../../core/utils/display_format.dart';
import '../../../../core/widgets/action_helpers.dart';
import '../../../../core/widgets/langfood_campus_route.dart';
import '../../../../core/widgets/langfood_card.dart';
import '../../../../core/widgets/langfood_empty_state.dart';
import '../../../../data/models/order_model.dart';
import '../../../../data/services/order_service.dart';
import '../../../../providers/auth_provider.dart';
import '../../../tracking/presentation/screens/live_tracking_screen.dart';
import '../widgets/my_order_card.dart';

class MyOrdersScreen extends StatefulWidget {
  final OrderService? service;
  const MyOrdersScreen({super.key, this.service});
  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  late final _service = widget.service ?? OrderService();
  List<OrderModel> _orders = [];
  bool _loading = true;
  String? _error;
  int? _cancelling;
  bool _finished = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) {
      setState(() {
        _loading = false;
        _error = 'Vui lòng đăng nhập.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final orders = await _service.getBuyerOrders(userId);
      if (mounted) setState(() => _orders = orders);
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cancel(OrderModel order) async {
    if (!order.canCancel || order.id == null || _cancelling != null) return;
    final confirmed = await confirmAction(
      context,
      'Hủy đơn #${order.id}?',
      'Chỉ hủy được khi quán chưa xử lý. Đơn sẽ bị xóa khỏi lịch sử sau khi hủy.',
      label: 'Hủy đơn',
    );
    if (!confirmed || !mounted) return;
    setState(() => _cancelling = order.id);
    try {
      await _service.cancelOrder(order.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Đã hủy đơn hàng.')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorText(e))));
      await _load();
    } finally {
      if (mounted) setState(() => _cancelling = null);
    }
  }

  Future<void> _openOrder(int orderId) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => LiveTrackingScreen(orderId: orderId)),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _orders
        .where((order) => order.isFinished == _finished)
        .toList();
    final colors = context.langFoodTheme;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đơn hàng của tôi'),
        actions: [
          IconButton(
            tooltip: 'Làm mới đơn hàng',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: false,
                      label: Text('Đang xử lý', textAlign: TextAlign.center),
                    ),
                    ButtonSegment(
                      value: true,
                      label: Text('Đã kết thúc', textAlign: TextAlign.center),
                    ),
                  ],
                  showSelectedIcon: false,
                  selected: {_finished},
                  style: ButtonStyle(
                    minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
                    padding: const WidgetStatePropertyAll(
                      EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    animationDuration: AppMotion.durationOf(
                      context,
                      AppMotion.durationFast,
                    ),
                    side: WidgetStatePropertyAll(
                      BorderSide(color: colors.borderSubtle),
                    ),
                    backgroundColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.selected)
                          ? scheme.secondaryContainer
                          : colors.card,
                    ),
                    foregroundColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.selected)
                          ? scheme.onSecondaryContainer
                          : colors.textPrimary,
                    ),
                  ),
                  onSelectionChanged: (value) =>
                      setState(() => _finished = value.single),
                ),
              ),
            ),
            Expanded(child: _orderList(visible)),
          ],
        ),
      ),
    );
  }

  Widget _orderList(List<OrderModel> visible) {
    if (_loading && _orders.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(semanticsLabel: 'Đang tải đơn hàng'),
      );
    }
    if (_error case final String error) {
      return ListView(
        padding: const EdgeInsets.symmetric(vertical: 32),
        children: [
          LangFoodEmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Chưa tải được đơn hàng',
            message: error,
            buttonText: 'Thử lại',
            onButtonPressed: _load,
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        key: PageStorageKey(_finished),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: visible.isEmpty ? 2 : visible.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == 0) return _summary(visible.length);
          if (visible.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: LangFoodEmptyState(
                icon: Icons.receipt_long_outlined,
                title: _finished
                    ? 'Chưa có đơn đã kết thúc'
                    : 'Chưa có đơn đang xử lý',
                message: _finished
                    ? 'Các đơn đã giao hoặc đã hủy sẽ xuất hiện ở đây.'
                    : 'Đơn mới sẽ xuất hiện ở đây sau khi bạn đặt món.',
              ),
            );
          }
          final order = visible[index - 1];
          final id = order.id;
          return MyOrderCard(
            key: id == null ? ObjectKey(order) : ValueKey(id),
            order: order,
            onOpen: id == null ? null : () => _openOrder(id),
            onCancel: id == null || _loading || _cancelling != null
                ? null
                : () => _cancel(order),
          );
        },
      ),
    );
  }

  Widget _summary(int count) {
    return LangFoodCard(
      backgroundColor: AppColors.campusViolet,
      showBorder: false,
      showShadow: false,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TRẠM GIAO KHU B',
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.campusLime,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: AppTokens.spaceXs),
                Text(
                  _finished
                      ? '$count đơn đã kết thúc'
                      : '$count đơn đang xử lý',
                  style: AppTypography.titleMd.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const LangFoodCampusRoute(),
        ],
      ),
    );
  }
}
