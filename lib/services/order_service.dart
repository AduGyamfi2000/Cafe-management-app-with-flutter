import 'dart:convert';
import 'package:cafe_management_app/models/order.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrderService {
  static const String _ordersKey = 'cafe_orders';

  static Future<void> saveOrder(Order order) async {
    final prefs = await SharedPreferences.getInstance();
    final ordersList = await getOrders();
    ordersList.add(order);
    
    await prefs.setString(
      _ordersKey,
      jsonEncode(ordersList.map((o) => o.toJson()).toList()),
    );
  }

  static Future<List<Order>> getOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final ordersJson = prefs.getString(_ordersKey);
    
    if (ordersJson == null) return [];
    
    final decodedOrders = jsonDecode(ordersJson) as List<dynamic>;
    final orders = <Order>[];
    
    for (final item in decodedOrders) {
      final order = Order.fromJson(item as Map<String, dynamic>);
      // Only include non-expired orders
      if (!order.isExpired()) {
        orders.add(order);
      }
    }
    
    // Save cleaned list back
    await prefs.setString(
      _ordersKey,
      jsonEncode(orders.map((o) => o.toJson()).toList()),
    );
    
    return orders;
  }

  static Future<void> clearExpiredOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final orders = await getOrders();
    
    await prefs.setString(
      _ordersKey,
      jsonEncode(orders.map((o) => o.toJson()).toList()),
    );
  }
}
