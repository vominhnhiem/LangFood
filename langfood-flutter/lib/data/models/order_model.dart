class OrderItemModel {
  final int? id;
  final int productId;
  final String? productName;
  final int quantity;
  final double unitPrice;
  final String? note;
  final String? optionsSummary;
  final double optionsPrice;

  OrderItemModel({
    this.id,
    required this.productId,
    this.productName,
    required this.quantity,
    required this.unitPrice,
    this.note,
    this.optionsSummary,
    this.optionsPrice = 0.0,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] as int?,
      productId: json['productId'] as int? ?? 0,
      productName: json['product'] != null
          ? json['product']['name'] as String?
          : json['productName'] as String?,
      quantity: json['quantity'] as int? ?? 1,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      note: json['note'] as String?,
      optionsSummary: json['optionsSummary'] as String?,
      optionsPrice: (json['optionsPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'productId': productId,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'note': note ?? '',
      if (optionsSummary != null && optionsSummary!.isNotEmpty)
        'optionsSummary': optionsSummary,
      if (optionsPrice > 0) 'optionsPrice': optionsPrice,
    };
  }
}

class OrderModel {
  final int? id;
  final String buyerId;
  final String? buyerName;
  final int shopId;
  final int? shipperId;
  final String status;
  final double totalAmount;
  final double? shippingFee;
  final String? deliveryBuilding;
  final String? deliveryRoom;
  final String? deliveryPhone;
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  final int paymentMethod;
  final String? createdAt;
  final String? deliveredAt;
  final List<OrderItemModel> orderItems;
  bool get canCancel => status == 'Pending' || status == 'PendingPayment';
  bool get isFinished =>
      status == 'Completed' || status == 'Cancelled' || status == 'Canceled';

  String get statusLabel => switch (status) {
    'PendingPayment' => 'Chờ thanh toán',
    'Pending' => 'Chờ quán xác nhận',
    'Preparing' => 'Quán đang chuẩn bị',
    'Ready' => 'Chờ shipper nhận đơn',
    'PickingUp' => 'Shipper đang đến quán lấy món',
    'Delivering' => 'Đang giao hàng',
    'Completed' => 'Đã giao hàng',
    'Cancelled' || 'Canceled' => 'Đã hủy',
    'Unknown' => 'Chưa xác định trạng thái',
    _ => status,
  };

  OrderModel({
    this.id,
    required this.buyerId,
    this.buyerName,
    required this.shopId,
    this.shipperId,
    this.status = 'Pending',
    required this.totalAmount,
    this.shippingFee,
    this.deliveryBuilding,
    this.deliveryRoom,
    this.deliveryPhone,
    this.deliveryLatitude,
    this.deliveryLongitude,
    this.paymentMethod = 0,
    this.createdAt,
    this.deliveredAt,
    this.orderItems = const [],
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    List<OrderItemModel> items = [];
    if (json['orderItems'] != null) {
      items = (json['orderItems'] as List)
          .map((item) => OrderItemModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return OrderModel(
      id: json['id'] as int?,
      buyerId: json['buyerId'] as String? ?? '',
      buyerName:
          json['buyerName'] as String? ??
          (json['buyer'] != null ? json['buyer']['fullName'] as String? : null),
      shopId: json['shopId'] as int? ?? 0,
      shipperId: json['shipperId'] as int?,
      status: json['status'] as String? ?? 'Unknown',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      shippingFee: (json['shippingFee'] as num?)?.toDouble(),
      deliveryBuilding: json['deliveryBuilding'] as String?,
      deliveryRoom: json['deliveryRoom'] as String?,
      deliveryPhone: json['deliveryPhone'] as String?,
      deliveryLatitude: (json['deliveryLatitude'] as num?)?.toDouble(),
      deliveryLongitude: (json['deliveryLongitude'] as num?)?.toDouble(),
      paymentMethod: json['paymentMethod'] as int? ?? 0,
      createdAt: json['createdAt'] as String?,
      deliveredAt: json['deliveredAt'] as String?,
      orderItems: items,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'buyerId': buyerId,
      'buyerName': buyerName ?? 'Khách hàng',
      'shopId': shopId,
      if (shipperId != null) 'shipperId': shipperId,
      'status': status,
      'totalAmount': totalAmount,
      if (shippingFee != null) 'shippingFee': shippingFee,
      'paymentMethod': paymentMethod,
      'deliveryBuilding': deliveryBuilding,
      if (deliveryRoom != null) 'deliveryRoom': deliveryRoom,
      'deliveryPhone': deliveryPhone,
      if (deliveryLatitude != null) 'deliveryLatitude': deliveryLatitude,
      if (deliveryLongitude != null) 'deliveryLongitude': deliveryLongitude,
      'orderItems': orderItems.map((e) => e.toJson()).toList(),
    };
  }
}
