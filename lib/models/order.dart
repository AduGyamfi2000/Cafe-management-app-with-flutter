class Order {
  const Order({
    required this.id,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.orderType,
    required this.timestamp,
    this.customerEmail,
    this.customerPhone,
  });

  final String id;
  final Map<int, int> items; // itemId -> quantity
  final double subtotal;
  final double tax;
  final double total;
  final String orderType; // 'eat_in' or 'take_out'
  final DateTime timestamp;
  final String? customerEmail;
  final String? customerPhone;

  factory Order.fromJson(Map<String, dynamic> json) {
    final itemsMap = <int, int>{};
    final items = json['items'] as Map<String, dynamic>;
    items.forEach((key, value) {
      itemsMap[int.parse(key)] = value as int;
    });

    return Order(
      id: json['id'] as String,
      items: itemsMap,
      subtotal: (json['subtotal'] as num).toDouble(),
      tax: (json['tax'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      orderType: json['orderType'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      customerEmail: json['customerEmail'] as String?,
      customerPhone: json['customerPhone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final itemsMap = <String, dynamic>{};
    items.forEach((key, value) {
      itemsMap[key.toString()] = value;
    });

    return {
      'id': id,
      'items': itemsMap,
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
      'orderType': orderType,
      'timestamp': timestamp.toIso8601String(),
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
    };
  }

  bool isExpired() {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    return difference.inHours >= 24;
  }
}
