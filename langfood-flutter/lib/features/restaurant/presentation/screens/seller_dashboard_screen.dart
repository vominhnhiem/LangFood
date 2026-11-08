import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/app_motion.dart';
import '../../../../core/widgets/account_menu.dart';
import '../../../../data/services/order_service.dart';
import 'merchant_products_screen.dart';
import 'seller_dashboard_demo.dart';
import 'seller_dashboard_widgets.dart';

class SellerDashboardScreen extends StatelessWidget {
  const SellerDashboardScreen({super.key, this.now})
    : isDemo = true,
      shopId = null,
      shopName = null;

  const SellerDashboardScreen.live({
    super.key,
    required this.shopId,
    required this.shopName,
  }) : isDemo = false,
       now = null;

  final bool isDemo;
  final int? shopId;
  final String? shopName;
  final DateTime Function()? now;

  @override
  Widget build(BuildContext context) => _SellerDashboardBody(config: this);
}

class _SellerDashboardBody extends StatefulWidget {
  const _SellerDashboardBody({required this.config});

  final SellerDashboardScreen config;

  @override
  State<_SellerDashboardBody> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<_SellerDashboardBody>
    with TickerProviderStateMixin {
  static const _alertChannel = MethodChannel('langfood/seller_order_alert');

  late TabController _tabs;
  Duration? _tabDuration;
  late final AppLifecycleListener _lifecycle;
  late final ValueNotifier<DateTime> _clock;
  Timer? _timer;
  final _service = OrderService();
  final _stock = ValueNotifier(sellerDemoStock);
  final _historySearch = TextEditingController();
  final _headerScroll = ScrollController();
  late List<SellerOrder> _orders;
  var _mode = SellerStoreMode.open;
  DateTime? _pausedUntil;
  var _alertsOn = true;
  var _nextId = 110;
  final _seenPending = <int>{};
  Future<void>? _refreshTask;
  int? _busyOrder;
  bool _hasSnapshot = false;
  String? _loadError;

  bool get _demo => widget.config.isDemo;
  DateTime _now() => widget.config.now?.call() ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    _clock = ValueNotifier(_now());
    _orders = _demo ? sellerDemoOrders(_clock.value) : [];
    _lifecycle = AppLifecycleListener(
      onStateChange: (state) {
        if (state == AppLifecycleState.resumed) {
          _syncClock();
          if (!_demo && _busyOrder == null) unawaited(_refresh());
        } else {
          unawaited(_signal('stop'));
        }
      },
    );
    if (_demo) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _syncClock());
    } else if (widget.config.shopId == null) {
      _loadError = 'Tài khoản chưa được gán quán ăn.';
    } else {
      unawaited(_refresh());
      _timer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (_busyOrder == null &&
            WidgetsBinding.instance.lifecycleState ==
                AppLifecycleState.resumed) {
          unawaited(_refresh());
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final duration = AppMotion.durationOf(context, AppMotion.durationNormal);
    if (_tabDuration == duration) return;
    final index = _tabDuration == null ? 0 : _tabs.index;
    if (_tabDuration != null) _tabs.dispose();
    _tabDuration = duration;
    _tabs = TabController(
      length: SellerQueue.values.length,
      animationDuration: duration,
      initialIndex: index,
      vsync: this,
    );
  }

  @override
  void dispose() {
    unawaited(_signal('stop'));
    _timer?.cancel();
    _lifecycle.dispose();
    _clock.dispose();
    _tabs.dispose();
    _stock.dispose();
    _historySearch.dispose();
    _headerScroll.dispose();
    super.dispose();
  }

  Future<void> _refresh() =>
      _refreshTask ??= _loadOrders().whenComplete(() => _refreshTask = null);

  Future<void> _loadOrders() async {
    final shopId = widget.config.shopId;
    if (shopId == null) return;
    try {
      final orders = await _service.getOrdersByShop(shopId);
      if (!mounted) return;
      final mapped = [
        for (final order in orders)
          if (order.id case final int id) SellerOrder.fromOrder(order, id),
      ];
      var arrivals = 0;
      for (final order in mapped) {
        if (order.status == SellerOrderStatus.pending &&
            _seenPending.add(order.id) &&
            _hasSnapshot) {
          arrivals++;
        }
      }
      _clock.value = _now();
      setState(() {
        _orders = mapped;
        _hasSnapshot = true;
        _loadError = null;
      });
      if (arrivals > 0 &&
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed &&
          ModalRoute.of(context)?.isCurrent == true) {
        if (_alertsOn) unawaited(_signal('play'));
        _showMessage(
          'Có $arrivals đơn mới cần xác nhận',
          action: SnackBarAction(
            label: 'Mở danh sách',
            onPressed: () => _openQueue(SellerQueue.incoming),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _loadError = 'Không tải được đơn của quán. Hãy thử lại.',
        );
      }
    }
  }

  Future<void> _advanceLive(SellerOrder order, SellerOrderStatus next) async {
    if (_busyOrder != null) return;
    setState(() => _busyOrder = order.id);
    try {
      await _refreshTask;
      if (!mounted) return;
      final current = _orders
          .where((candidate) => candidate.id == order.id)
          .firstOrNull;
      if (current == null || current.status != order.status) {
        _showMessage('${order.code} đã đổi trạng thái. Vui lòng kiểm tra lại.');
        return;
      }
      final ok = next == SellerOrderStatus.preparing
          ? await _service.shopAcceptOrder(order.id)
          : await _service.shopReadyOrder(order.id);
      if (!mounted) return;
      if (ok) _transition(current, next);
      await _refresh();
      if (mounted && !ok) {
        _showMessage('Chưa xác nhận được cập nhật cho ${order.code}.');
      }
    } finally {
      if (mounted) setState(() => _busyOrder = null);
    }
  }

  void _advance(SellerOrder order, SellerOrderStatus next) {
    if (_demo) {
      _transition(order, next);
    } else {
      unawaited(_advanceLive(order, next));
    }
  }

  void _syncClock() {
    final now = _now();
    final isNewDay = !DateUtils.isSameDay(
      sellerCampusTime(_clock.value),
      sellerCampusTime(now),
    );
    _clock.value = now;
    final expired = _orders
        .where((order) => order.acceptBy?.isAfter(now) == false)
        .map((order) => order.id)
        .toSet();
    final resumeOrders = _pausedUntil?.isAfter(now) == false;
    if (expired.isEmpty && !resumeOrders && !isNewDay) return;
    setState(() {
      if (resumeOrders) {
        _pausedUntil = null;
        _mode = SellerStoreMode.open;
      }
      if (expired.isNotEmpty) {
        _orders = [
          for (final order in _orders)
            if (expired.contains(order.id))
              order.transition(
                SellerOrderStatus.cancelled,
                order.acceptBy!,
                reason: 'Hết giờ xác nhận.',
              )
            else
              order,
        ];
      }
    });
  }

  void _setMode(SellerStoreMode mode) {
    AppHaptics.selection();
    setState(() {
      _mode = mode;
      _pausedUntil = mode == SellerStoreMode.paused
          ? _now().add(const Duration(minutes: 15))
          : null;
    });
  }

  Future<void> _signal(String method) async {
    try {
      await _alertChannel.invokeMethod<void>(method);
    } on MissingPluginException {
      // Desktop and web still show the visual alert.
    } on PlatformException catch (error) {
      debugPrint('Seller order alert: ${error.code}');
    }
  }

  void _showMessage(String message, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), action: action));
  }

  void _openQueue(SellerQueue queue) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppMotion.durationNormal;
    _tabs.animateTo(queue.index, duration: duration);
    if (!_headerScroll.hasClients) return;
    final offset = _headerScroll.position.maxScrollExtent;
    if (duration == Duration.zero) {
      _headerScroll.jumpTo(offset);
    } else {
      unawaited(
        _headerScroll.animateTo(
          offset,
          duration: duration,
          curve: AppMotion.curveDefault,
        ),
      );
    }
  }

  void _simulateArrival() {
    _syncClock();
    if (_mode != SellerStoreMode.open) {
      _showMessage('Mở lại quán để nhận đơn thử mới.');
      return;
    }
    final order = sellerDemoArrival(_nextId, _now(), _stock.value);
    if (order == null) {
      _showMessage('Bật bán ít nhất một món để nhận đơn thử.');
      return;
    }
    setState(() {
      _nextId++;
      _orders = [order, ..._orders];
    });
    if (_alertsOn) unawaited(_signal('play'));
    _showMessage(
      'Có đơn thử mới ${order.code}',
      action: SnackBarAction(
        label: 'Mở danh sách',
        onPressed: () => _openQueue(SellerQueue.incoming),
      ),
    );
  }

  void _transition(
    SellerOrder order,
    SellerOrderStatus next, {
    String? reason,
  }) {
    _syncClock();
    final index = _orders.indexOf(order);
    if (index == -1) {
      _showMessage('${order.code} đã đổi trạng thái. Vui lòng kiểm tra lại.');
      return;
    }
    setState(() {
      _orders[index] = order.transition(next, _now(), reason: reason);
    });
    AppHaptics.medium();
    final message = switch (next) {
      SellerOrderStatus.preparing => 'Đã nhận ${order.code}',
      SellerOrderStatus.ready => '${order.code} đang chờ shipper',
      _ => 'Đã từ chối ${order.code}',
    };
    _showMessage(
      message,
      action: SnackBarAction(
        label: 'Mở danh sách',
        onPressed: () => _openQueue(next.queue),
      ),
    );
  }

  Future<void> _reject(SellerOrder order) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Từ chối ${order.code}?'),
        children: [
          for (final reason in ['Hết món', 'Bếp quá tải', 'Quán sắp đóng cửa'])
            SimpleDialogOption(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              onPressed: () => Navigator.pop(context, reason),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 40),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Từ chối vì $reason'),
                ),
              ),
            ),
          SimpleDialogOption(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            onPressed: () => Navigator.pop(context),
            child: const SizedBox(
              height: 40,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Quay lại'),
              ),
            ),
          ),
        ],
      ),
    );
    if (mounted && reason != null) {
      _transition(
        order,
        SellerOrderStatus.cancelled,
        reason: 'Quán từ chối · $reason',
      );
    }
  }

  void _openStock() {
    showModalBottomSheet<void>(
      context: context,
      sheetAnimationStyle: AppMotion.sheetStyle(context),
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: context.langFoodTheme.card,
      constraints: BoxConstraints(
        maxWidth: 600,
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      builder: (_) => QuickStockSheet(
        stock: _stock,
        onChanged: (id, value) {
          _stock.value = [
            for (final item in _stock.value)
              item.id == id ? item.withAvailability(value) : item,
          ];
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final queues = {
      for (final queue in SellerQueue.values) queue: <SellerOrder>[],
    };
    for (final order in _orders) {
      queues[order.status.queue]!.add(order);
    }
    final oldest = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    queues[SellerQueue.incoming]!.sort((a, b) {
      final priority = a.status.index.compareTo(b.status.index);
      if (priority != 0) return priority;
      return (a.acceptBy ?? a.createdAt ?? oldest).compareTo(
        b.acceptBy ?? b.createdAt ?? oldest,
      );
    });
    queues[SellerQueue.cooking]!.sort(
      (a, b) => (a.createdAt ?? oldest).compareTo(b.createdAt ?? oldest),
    );
    final history = queues[SellerQueue.history]!
      ..sort(
        (a, b) => (b.endedAt ?? b.createdAt ?? oldest).compareTo(
          a.endedAt ?? a.createdAt ?? oldest,
        ),
      );
    final today = sellerCampusTime(_clock.value);
    var completed = 0;
    var cancelled = 0;
    num revenue = 0;
    for (final order in history) {
      final date = _demo ? order.endedAt : order.createdAt;
      if (date == null || !DateUtils.isSameDay(sellerCampusTime(date), today)) {
        continue;
      }
      if (order.status == SellerOrderStatus.delivered) {
        completed++;
        revenue += order.netRevenue;
      } else if (order.status == SellerOrderStatus.cancelled) {
        cancelled++;
      }
    }
    final incoming = queues[SellerQueue.incoming]!
        .where((order) => order.status == SellerOrderStatus.pending)
        .length;
    final stats = LiveStatsHeader(
      revenue: revenue,
      completed: completed,
      cancelled: cancelled,
      revenueLabel: _demo ? 'Thực nhận' : 'Tiền món',
    );
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              children: [
                _topBar(),
                Expanded(
                  child: !_demo && !_hasSnapshot
                      ? _initialLiveContent()
                      : NestedScrollView(
                          controller: _headerScroll,
                          headerSliverBuilder: (context, _) => [
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                              sliver: SliverToBoxAdapter(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    if (_demo)
                                      _storeControl()
                                    else
                                      _liveStore(),
                                    const SizedBox(height: 10),
                                    if (incoming > 0) ...[
                                      _newOrderBanner(incoming),
                                      const SizedBox(height: 10),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            SliverOverlapAbsorber(
                              handle:
                                  NestedScrollView.sliverOverlapAbsorberHandleFor(
                                    context,
                                  ),
                              sliver: SliverPersistentHeader(
                                pinned: true,
                                delegate: _SellerTabHeader(
                                  height: _tabHeight(context),
                                  child: _tabBar(queues),
                                ),
                              ),
                            ),
                          ],
                          body: TabBarView(
                            controller: _tabs,
                            children: [
                              for (final queue in SellerQueue.values)
                                _orderList(queue, queues[queue]!, stats),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _demo ? _stockBar() : null,
    );
  }

  TextStyle get _eyebrow => TextStyle(
    color: context.langFoodTheme.textSecondary,
    fontSize: 11,
    letterSpacing: 1.15,
    fontWeight: FontWeight.w800,
  );

  Widget _topBar() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 12, 4),
    child: Row(
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              shape: sellerShape,
            ),
            child: Icon(
              Icons.storefront_rounded,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
              size: 23,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _demo ? 'LÀNG FOOD · BẢN DEMO' : 'LÀNG FOOD · CHỦ QUÁN',
                style: _eyebrow,
              ),
              const Text(
                'Bảng điều hành',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
        if (!_demo)
          IconButton(
            tooltip: 'Tải lại đơn',
            onPressed: widget.config.shopId == null || _busyOrder != null
                ? null
                : () => unawaited(_refresh()),
            icon: const Icon(Icons.refresh_rounded),
          ),
        IconButton(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          tooltip: _alertsOn ? 'Tắt chuông và rung' : 'Bật chuông và rung',
          onPressed: () {
            setState(() => _alertsOn = !_alertsOn);
            if (!_alertsOn) unawaited(_signal('stop'));
          },
          icon: Icon(
            _alertsOn
                ? Icons.notifications_active_outlined
                : Icons.notifications_off_outlined,
          ),
        ),
        if (!_demo) const AccountMenu(),
      ],
    ),
  );

  Widget _initialLiveContent() => Center(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: _loadError == null
          ? const CircularProgressIndicator()
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_loadError!, textAlign: TextAlign.center),
                if (widget.config.shopId != null)
                  TextButton(
                    onPressed: () => unawaited(_refresh()),
                    child: const Text('Thử lại'),
                  ),
              ],
            ),
    ),
  );

  Widget _liveStore() => SellerPanel(
    padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.config.shopName ?? 'Quán của bạn',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            IconButton(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              tooltip: 'Quản lý menu',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MerchantProductsScreen(),
                ),
              ),
              icon: const Icon(Icons.restaurant_menu_rounded),
            ),
          ],
        ),
        if (_loadError case final String error)
          Text(
            error,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
      ],
    ),
  );

  Widget _storeControl() {
    final (ink, wash) = switch (_mode) {
      SellerStoreMode.open => (SellerColors.greenInk, SellerColors.greenWash),
      SellerStoreMode.paused => (SellerColors.amberInk, SellerColors.amberWash),
      SellerStoreMode.closed => (SellerColors.muted, SellerColors.grayWash),
    };
    final deadline = _pausedUntil;
    return SellerPanel(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Căn tin C1–C2',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            subtitle: Align(
              alignment: Alignment.centerLeft,
              child: SellerBadge(
                _mode.label,
                ink: ink,
                wash: wash,
                icon: Icons.circle,
              ),
            ),
            activeThumbColor: Colors.white,
            activeTrackColor: SellerColors.greenInk,
            value: _mode != SellerStoreMode.closed,
            onChanged: (open) =>
                _setMode(open ? SellerStoreMode.open : SellerStoreMode.closed),
          ),
          if (deadline != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 3, vertical: 4),
              child: Text(
                'Tiếp tục xử lý các đơn đã nhận.',
                style: TextStyle(
                  color: context.langFoodTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (_mode != SellerStoreMode.closed)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  onPressed: () => _setMode(
                    deadline == null
                        ? SellerStoreMode.paused
                        : SellerStoreMode.open,
                  ),
                  icon: Icon(
                    deadline == null
                        ? Icons.pause_circle_outline
                        : Icons.play_circle_outline,
                    size: 19,
                  ),
                  label: deadline == null
                      ? const Text('Tạm ngưng 15 phút')
                      : ValueListenableBuilder<DateTime>(
                          valueListenable: _clock,
                          builder: (context, now, _) => Text(
                            'Nhận lại · ${sellerTimeLeft(deadline, now)}',
                            style: const TextStyle(fontFeatures: sellerDigits),
                          ),
                        ),
                ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
                onPressed: _simulateArrival,
                icon: const Icon(Icons.add_circle_outline, size: 19),
                label: const Text('Tạo đơn thử'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _newOrderBanner(int incoming) => Semantics(
    liveRegion: true,
    child: Material(
      color: SellerColors.greenWash,
      shape: sellerShape,
      child: InkWell(
        customBorder: sellerShape,
        onTap: () => _openQueue(SellerQueue.incoming),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Icon(
                  Icons.notifications_active_rounded,
                  size: 19,
                  color: SellerColors.greenInk,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$incoming đơn mới cần xác nhận',
                    style: const TextStyle(
                      color: SellerColors.greenInk,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: SellerColors.greenInk,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  double _tabHeight(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(12) * 3 + 36;

  Widget _tabBar(Map<SellerQueue, List<SellerOrder>> queues) {
    final colors = context.langFoodTheme;
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: colors.canvas,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: AppTokens.borderRadiusLg,
          ),
          child: TabBar(
            controller: _tabs,
            padding: const EdgeInsets.all(3),
            labelPadding: const EdgeInsets.symmetric(horizontal: 2),
            labelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
            labelColor: scheme.onSecondaryContainer,
            unselectedLabelColor: colors.textSecondary,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: scheme.secondaryContainer,
              borderRadius: AppTokens.borderRadiusMd,
            ),
            dividerColor: Colors.transparent,
            tabs: [
              for (final queue in SellerQueue.values)
                Tab(
                  height: _tabHeight(context) - 14,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (queue == SellerQueue.history)
                        const Icon(Icons.history_rounded, size: 16)
                      else
                        AnimatedSwitcher(
                          duration: AppMotion.durationOf(
                            context,
                            AppMotion.durationNormal,
                          ),
                          child: Text(
                            '${queues[queue]!.length}',
                            key: ValueKey(queues[queue]!.length),
                            style: const TextStyle(fontFeatures: sellerDigits),
                          ),
                        ),
                      Flexible(
                        child: Text(
                          queue == SellerQueue.pickup ? 'Chờ lấy' : queue.label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _orderList(SellerQueue queue, List<SellerOrder> orders, Widget stats) {
    final query = _historySearch.text.trim().toLowerCase();
    final isHistory = queue == SellerQueue.history;
    final visibleOrders = !isHistory || query.isEmpty
        ? orders
        : orders
              .where(
                (order) => [
                  order.code,
                  order.customer,
                  order.destination,
                  order.status.label,
                ].any((text) => text.toLowerCase().contains(query)),
              )
              .toList();
    return Builder(
      builder: (context) => CustomScrollView(
        key: PageStorageKey(queue),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverOverlapInjector(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
          ),
          if (isHistory)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              sliver: SliverToBoxAdapter(
                child: TextField(
                  controller: _historySearch,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search_rounded),
                    labelText: 'Tìm mã đơn, khách hoặc tòa nhà',
                    border: const OutlineInputBorder(
                      borderRadius: AppTokens.borderRadiusLg,
                    ),
                    filled: true,
                    fillColor: context.langFoodTheme.card,
                    suffixIcon: query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Xóa tìm kiếm',
                            onPressed: () => setState(_historySearch.clear),
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            sliver: visibleOrders.isEmpty
                ? SliverToBoxAdapter(
                    child: SellerPanel(
                      child: Row(
                        children: [
                          Icon(
                            sellerQueueTone(queue).icon,
                            color: context.langFoodTheme.textSecondary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              isHistory && query.isNotEmpty
                                  ? 'Không tìm thấy đơn phù hợp.'
                                  : queue.emptyMessage,
                              style: TextStyle(
                                color: context.langFoodTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverList.builder(
                    itemCount: visibleOrders.length,
                    itemBuilder: (context, index) {
                      final order = visibleOrders[index];
                      return Padding(
                        key: ValueKey(order.id),
                        padding: const EdgeInsets.only(bottom: 10),
                        child: OrderCardItem(
                          order: order,
                          clock: _clock,
                          busy: _busyOrder != null,
                          onAccept: order.status == SellerOrderStatus.pending
                              ? () =>
                                    _advance(order, SellerOrderStatus.preparing)
                              : null,
                          onReject:
                              _demo && order.status == SellerOrderStatus.pending
                              ? () => _reject(order)
                              : null,
                          onReady: order.status == SellerOrderStatus.preparing
                              ? () => _advance(order, SellerOrderStatus.ready)
                              : null,
                        ),
                      );
                    },
                  ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _demo ? 'KẾT QUẢ HÔM NAY' : 'ĐƠN TẠO HÔM NAY',
                    style: _eyebrow,
                  ),
                  const SizedBox(height: 6),
                  stats,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stockBar() => Material(
    color: context.langFoodTheme.card,
    elevation: 2,
    child: SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 648),
          child: ValueListenableBuilder<List<SellerStockItem>>(
            valueListenable: _stock,
            builder: (context, stock, _) {
              final unavailable = stock.where((item) => !item.available).length;
              return SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _openStock,
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: Text(
                    'Hết món nhanh · $unavailable đã tắt',
                    textAlign: TextAlign.center,
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: sellerButtonSize,
                    shape: sellerShape,
                    foregroundColor: SellerColors.brandInk,
                    backgroundColor: const Color(0xFFFFF1EA),
                    side: const BorderSide(color: Color(0xFFFFC9B5)),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
}

class _SellerTabHeader extends SliverPersistentHeaderDelegate {
  const _SellerTabHeader({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => child;

  @override
  bool shouldRebuild(_SellerTabHeader oldDelegate) =>
      oldDelegate.height != height || oldDelegate.child != child;
}
