class LobbyRoom {
  final int id;
  final int shopId;
  final String shopName;
  final DateTime closesAt;
  final String address;
  final int participants;
  final bool isOpen;
  final bool joined;
  final bool canFinalize;
  final num? hostShippingQuote;
  final bool canCancel;
  final int? orderId;
  final num? foodTotal;
  final num? shippingShare;
  final int? portionNumber;

  LobbyRoom.fromJson(Map<String, dynamic> json)
    : id = json['id'] as int,
      shopId = json['shopId'] as int,
      shopName = json['shopName'] as String,
      closesAt = DateTime.parse(json['closesAt'] as String),
      address = json['address'] as String,
      participants = json['participants'] as int,
      isOpen = json['open'] == true,
      joined = json['joined'] == true,
      canFinalize = json['canFinalize'] == true,
      hostShippingQuote = json['hostShippingQuote'] as num?,
      canCancel = json['canCancel'] == true,
      orderId = json['orderId'] as int?,
      foodTotal = json['foodTotal'] as num?,
      shippingShare = json['shippingShare'] as num?,
      portionNumber = json['portionNumber'] as int?;
}
