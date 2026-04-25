import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../models/menu_item.dart';
import '../models/order_type.dart';

const List<MenuItem> _defaultMenuItems = [
  MenuItem(id: 1, name: 'Espresso', price: 3.50),
  MenuItem(id: 2, name: 'Cappuccino', price: 4.25),
  MenuItem(id: 3, name: 'Ham Sandwich', price: 7.95),
  MenuItem(id: 4, name: 'Caesar Salad', price: 6.50),
  MenuItem(id: 5, name: 'Chocolate Cake', price: 4.75),
];

Future<void> ensureDefaultMenuItems() async {
  final prefs = await SharedPreferences.getInstance();
  if (!prefs.containsKey(menuItemsKey)) {
    await prefs.setString(
      menuItemsKey,
      jsonEncode(_defaultMenuItems.map((item) => item.toJson()).toList()),
    );
  }
}

Future<List<MenuItem>> loadMenuItems() async {
  final prefs = await SharedPreferences.getInstance();
  final menuJson = prefs.getString(menuItemsKey);
  if (menuJson == null) {
    return [];
  }

  final items = jsonDecode(menuJson) as List<dynamic>;
  return items
      .map((item) => MenuItem.fromJson(item as Map<String, dynamic>))
      .toList();
}

Future<void> saveMenuItems(List<MenuItem> items) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    menuItemsKey,
    jsonEncode(items.map((item) => item.toJson()).toList()),
  );
}

Future<OrderType?> loadSelectedOrderType() async {
  final prefs = await SharedPreferences.getInstance();
  final orderTypeString = prefs.getString(selectedOrderTypeKey);
  if (orderTypeString == 'eat_in') {
    return OrderType.eatIn;
  }
  if (orderTypeString == 'take_out') {
    return OrderType.takeOut;
  }
  return null;
}

Future<void> saveSelectedOrderType(OrderType type) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    selectedOrderTypeKey,
    type == OrderType.eatIn ? 'eat_in' : 'take_out',
  );
}
