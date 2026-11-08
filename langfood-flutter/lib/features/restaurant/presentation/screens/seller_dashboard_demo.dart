import '../../../../data/models/order_model.dart';

enum SellerQueue {
  incoming('Đơn mới', 'Đơn mới sẽ xuất hiện tại đây.'),
  cooking('Đang nấu', 'Đơn đã nhận sẽ xuất hiện tại đây.'),
  pickup('Chờ shipper', 'Đơn đã xong món sẽ xuất hiện tại đây.'),
  history('Lịch sử', 'Chưa có đơn đã giao hoặc đã hủy.');

  const SellerQueue(this.label, this.emptyMessage);
  final String label;
  final String emptyMessage;
}

enum SellerStoreMode {
  open('Đang mở cửa'),
  paused('Tạm ngưng nhận đơn'),
  closed('Tạm đóng quán');

  const SellerStoreMode(this.label);
  final String label;
}

enum SellerOrderStatus {
  pending(SellerQueue.incoming, 'Cần xác nhận'),
  pendingPayment(SellerQueue.incoming, 'Chờ thanh toán'),
  preparing(SellerQueue.cooking, 'Đang nấu'),
  ready(SellerQueue.pickup, 'Chưa có shipper'),
  pickingUp(SellerQueue.pickup, 'Đang đến lấy món'),
  delivering(SellerQueue.pickup, 'Đang giao'),
  delivered(SellerQueue.history, 'Đã giao'),
  cancelled(SellerQueue.history, 'Đã hủy'),
  unknown(SellerQueue.history, 'Chưa rõ trạng thái');

  const SellerOrderStatus(this.queue, this.label);
  final SellerQueue queue;
  final String label;
}

class SellerOrder {
  const SellerOrder({
    required this.id,
    required this.customer,
    required this.destination,
    required this.createdAt,
    required this.status,
    required this.items,
    this.acceptBy,
    this.endedAt,
    this.netRevenue = 0,
    this.courier,
    this.shipperId,
    this.cancelReason,
  });

  final int id;
  final String customer;
  final String destination;
  final DateTime? createdAt;
  final SellerOrderStatus status;
  final List<OrderItemModel> items;
  final DateTime? acceptBy;
  final DateTime? endedAt;
  final num netRevenue;
  final int? shipperId;
  final ({String name, String phone, String plate})? courier;
  final String? cancelReason;

  String get code => '#LF-$id';
  int get portions => items.fold(0, (total, item) => total + item.quantity);

  SellerOrder transition(
    SellerOrderStatus next,
    DateTime now, {
    String? reason,
  }) => SellerOrder(
    id: id,
    customer: customer,
    destination: destination,
    createdAt: createdAt,
    status: next,
    items: items,
    endedAt: next.queue == SellerQueue.history ? now : null,
    netRevenue: netRevenue,
    courier: courier,
    shipperId: shipperId,
    cancelReason: reason,
  );

  factory SellerOrder.fromOrder(OrderModel order, int id) {
    final building = order.deliveryBuilding?.trim() ?? '';
    final room = order.deliveryRoom?.trim() ?? '';
    final destination = [
      if (building.isNotEmpty) building,
      if (room.isNotEmpty && room != building) room,
    ].join(' · ');
    final buyer = order.buyerName?.trim() ?? '';
    return SellerOrder(
      id: id,
      customer: buyer.isEmpty ? 'Khách hàng' : buyer,
      destination: destination.isEmpty ? 'Chưa có điểm giao' : destination,
      createdAt: _orderTime(order.createdAt),
      endedAt: _orderTime(order.deliveredAt),
      status: switch (order.status) {
        'Pending' => SellerOrderStatus.pending,
        'PendingPayment' => SellerOrderStatus.pendingPayment,
        'Preparing' => SellerOrderStatus.preparing,
        'Ready' || 'Confirmed' || 'Accepted' => SellerOrderStatus.ready,
        'PickingUp' => SellerOrderStatus.pickingUp,
        'Delivering' => SellerOrderStatus.delivering,
        'Completed' => SellerOrderStatus.delivered,
        'Cancelled' || 'Canceled' || 'Rejected' => SellerOrderStatus.cancelled,
        _ => SellerOrderStatus.unknown,
      },
      items: order.orderItems,
      shipperId: order.shipperId,
      netRevenue: order.totalAmount,
    );
  }
}

DateTime? _orderTime(String? value) {
  final date = DateTime.tryParse(value ?? '');
  if (date == null || date.isUtc) return date;
  // Dates without an offset are wall-clock times in the KTX time zone.
  return DateTime.utc(
    date.year,
    date.month,
    date.day,
    date.hour,
    date.minute,
    date.second,
  ).subtract(const Duration(hours: 7));
}

class SellerStockItem {
  const SellerStockItem({
    required this.id,
    required this.name,
    this.isTopping = false,
    this.available = true,
  });

  final int id;
  final String name;
  final bool isTopping;
  final bool available;

  SellerStockItem withAvailability(bool value) => SellerStockItem(
    id: id,
    name: name,
    isTopping: isTopping,
    available: value,
  );
}

const sellerDemoStock = [
  SellerStockItem(id: 1, name: 'Cơm sườn'),
  SellerStockItem(id: 2, name: 'Cơm gà xối mỡ'),
  SellerStockItem(id: 3, name: 'Bún thịt nướng'),
  SellerStockItem(id: 4, name: 'Trà tắc'),
  SellerStockItem(id: 5, name: 'Trứng ốp la', isTopping: true),
  SellerStockItem(id: 6, name: 'Chả trứng', isTopping: true, available: false),
];

DateTime sellerCampusTime(DateTime time) =>
    time.toUtc().add(const Duration(hours: 7));

List<SellerOrder> sellerDemoOrders(DateTime now) {
  SellerOrder order(
    int id,
    String customer,
    String destination,
    SellerOrderStatus status,
    List<OrderItemModel> items, {
    int age = 0,
    int? secondsLeft,
    int? endedMinutesAgo,
    int revenue = 0,
    ({String name, String phone, String plate})? courier,
    String? cancelReason,
  }) => SellerOrder(
    id: id,
    customer: customer,
    destination: destination,
    createdAt: now.subtract(Duration(minutes: age)),
    status: status,
    items: items,
    acceptBy: secondsLeft == null
        ? null
        : now.add(Duration(seconds: secondsLeft)),
    endedAt: endedMinutesAgo == null
        ? null
        : now.subtract(Duration(minutes: endedMinutesAgo)),
    netRevenue: revenue,
    courier: courier,
    cancelReason: cancelReason,
  );

  return [
    order(
      108,
      'Nguyễn Minh An',
      'Tòa BA2 · Sảnh tầng G',
      SellerOrderStatus.pending,
      [
        _item(
          1,
          'Cơm sườn',
          2,
          35000,
          options: '2 × Trứng ốp la',
          note: 'Một phần không hành, nước mắm để riêng.',
        ),
        _item(4, 'Trà tắc', 1, 12000, options: '50% đường · Đá riêng'),
      ],
      age: 1,
      secondsLeft: 105,
    ),
    order(
      109,
      'Trần Khánh Linh',
      'Tòa D4 · Cổng bảo vệ',
      SellerOrderStatus.pending,
      [_item(2, 'Cơm gà xối mỡ', 1, 39000, note: 'Không dưa leo.')],
      secondsLeft: 135,
    ),
    order(
      107,
      'Phạm Gia Hân',
      'Tòa BC1 · Sảnh tầng G',
      SellerOrderStatus.preparing,
      [
        _item(
          3,
          'Bún thịt nướng',
          3,
          36000,
          note: 'Hai phần không đậu phộng, đóng hộp riêng.',
        ),
        _item(4, 'Trà tắc', 2, 12000, options: 'Không đá'),
      ],
      age: 8,
    ),
    order(
      106,
      'Lê Nhật Minh',
      'Tòa C6 · Sảnh tầng G',
      SellerOrderStatus.preparing,
      [_item(1, 'Cơm sườn', 2, 35000, options: '2 × Trứng ốp la')],
      age: 10,
    ),
    order(
      105,
      'Võ Thanh Tú',
      'Tòa C3 · Sảnh tầng G',
      SellerOrderStatus.pickingUp,
      [_item(2, 'Cơm gà xối mỡ', 2, 39000)],
      age: 14,
      courier: (
        name: 'Đặng Minh Khoa',
        phone: '0900 000 000',
        plate: '59-X1 000.00',
      ),
    ),
    order(
      104,
      'Bùi Bảo Ngọc',
      'Tòa BD2 · Cổng bảo vệ',
      SellerOrderStatus.ready,
      [_item(3, 'Bún thịt nướng', 2, 36000)],
      age: 16,
    ),
    order(
      103,
      'Đỗ Hoàng Nam',
      'Tòa D1 · Sảnh tầng G',
      SellerOrderStatus.delivered,
      [_item(2, 'Cơm gà xối mỡ', 4, 39000)],
      age: 24,
      endedMinutesAgo: 5,
      revenue: 156000,
    ),
    order(
      102,
      'Mai Thảo Vy',
      'Tòa BA4 · Sảnh tầng G',
      SellerOrderStatus.cancelled,
      [_item(3, 'Bún thịt nướng', 1, 36000)],
      age: 29,
      endedMinutesAgo: 27,
      cancelReason: 'Khách đã hủy đơn.',
    ),
    order(
      101,
      'Hồ Hải Đăng',
      'Tòa BB1 · Cổng bảo vệ',
      SellerOrderStatus.delivered,
      [_item(1, 'Cơm sườn', 6, 35000)],
      age: 45,
      endedMinutesAgo: 30,
      revenue: 210000,
    ),
    order(
      100,
      'Vũ Tuệ Nhi',
      'Tòa C2 · Sảnh tầng G',
      SellerOrderStatus.delivered,
      [_item(3, 'Bún thịt nướng', 3, 36000)],
      age: 60,
      endedMinutesAgo: 40,
      revenue: 108000,
    ),
  ];
}

SellerOrder? sellerDemoArrival(
  int id,
  DateTime now,
  List<SellerStockItem> stock,
) {
  final food = stock
      .where((item) => !item.isTopping && item.available)
      .firstOrNull;
  if (food == null) return null;
  final topping = stock
      .where((item) => item.isTopping && item.available)
      .firstOrNull;
  return SellerOrder(
    id: id,
    customer: 'Trần Hoài Thư',
    destination: 'Tòa D3 · Sảnh tầng G',
    createdAt: now,
    status: SellerOrderStatus.pending,
    acceptBy: now.add(const Duration(minutes: 2)),
    items: [
      _item(
        food.id,
        food.name,
        1,
        0,
        options: food.id == 1 || food.id == 2 ? topping?.name : null,
        note: 'Vui lòng để nước chấm riêng.',
      ),
    ],
  );
}

OrderItemModel _item(
  int id,
  String name,
  int quantity,
  double price, {
  String? options,
  String? note,
}) => OrderItemModel(
  productId: id,
  productName: name,
  quantity: quantity,
  unitPrice: price,
  optionsSummary: options,
  note: note,
);
