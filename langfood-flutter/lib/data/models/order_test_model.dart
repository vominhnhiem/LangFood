class OrderTestModel {
  final int? id;
  final String customerName;
  final String deliveryAddress;
  final String phone;
  final double latitude;
  final double longitude;
  final double totalAmount;
  final String status;
  final int? shipperId;
  final String? createdAt;

  OrderTestModel({
    this.id,
    required this.customerName,
    required this.deliveryAddress,
    required this.phone,
    required this.latitude,
    required this.longitude,
    required this.totalAmount,
    this.status = 'Ready',
    this.shipperId,
    this.createdAt,
  });

  factory OrderTestModel.fromJson(Map<String, dynamic> json) {
    return OrderTestModel(
      id: json['id'] as int?,
      customerName: json['customerName'] as String? ?? 'Khách hàng Demo',
      deliveryAddress: json['deliveryAddress'] as String? ?? 'Sảnh KTX Khu B, Thủ Đức',
      phone: json['phone'] as String? ?? '0987654321',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 10.8800,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 106.8050,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 35000.0,
      status: json['status'] as String? ?? 'Ready',
      shipperId: json['shipperId'] as int?,
      createdAt: json['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'customerName': customerName,
      'deliveryAddress': deliveryAddress,
      'phone': phone,
      'latitude': latitude,
      'longitude': longitude,
      'totalAmount': totalAmount,
      'status': status,
      if (shipperId != null) 'shipperId': shipperId,
    };
  }
}
