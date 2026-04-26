import 'dart:convert';
import 'package:cafe_management_app/models/menu_item.dart';
import 'package:cafe_management_app/models/order_type.dart';
import 'package:cafe_management_app/screens/admin/admin_login_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Map<int, int> _cart = {};
  List<MenuItem> _menuItems = [];
  OrderType? _selectedOrderType;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final menuJson = prefs.getString('menu_items');
    final orderTypeString = prefs.getString('selected_order_type');

    final menuItems = <MenuItem>[];
    if (menuJson != null) {
      final items = jsonDecode(menuJson) as List<dynamic>;
      for (final item in items) {
        menuItems.add(MenuItem.fromJson(item as Map<String, dynamic>));
      }
    }

    setState(() {
      _menuItems = menuItems;
      _selectedOrderType = orderTypeString == 'eat_in'
          ? OrderType.eatIn
          : orderTypeString == 'take_out'
              ? OrderType.takeOut
              : null;
      _loading = false;
    });
  }

  Future<void> _saveOrderType(OrderType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_order_type', type == OrderType.eatIn ? 'eat_in' : 'take_out');
  }

  void _updateCart(MenuItem item, int delta) {
    setState(() {
      final current = _cart[item.id] ?? 0;
      final updated = current + delta;
      if (updated <= 0) {
        _cart.remove(item.id);
      } else {
        _cart[item.id] = updated;
      }
    });
  }

  double get _subtotal {
    return _cart.entries.fold(0.0, (value, entry) {
      final item = _menuItems.firstWhere((element) => element.id == entry.key);
      return value + item.price * entry.value;
    });
  }

  double get _tax => _subtotal * 0.10;
  double get _total => _subtotal + _tax;

  void _goToAdminLogin() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AdminLoginScreen(menuItems: _menuItems),
      ),
    );
    if (changed == true) {
      await _loadState();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cafe Ordering'),
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            tooltip: 'Admin Login',
            onPressed: _goToAdminLogin,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _selectedOrderType == null
              ? _buildOrderTypeSelection()
              : _buildMenuView(),
    );
  }

  Widget _buildOrderTypeSelection() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Choose Dining Option',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              _selectedOrderType = OrderType.eatIn;
              _saveOrderType(_selectedOrderType!);
              setState(() {});
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Text('Eat-In', style: TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              _selectedOrderType = OrderType.takeOut;
              _saveOrderType(_selectedOrderType!);
              setState(() {});
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Text('Take-Out', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Menu - ${_selectedOrderType == OrderType.eatIn ? 'Eat-In' : 'Take-Out'}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedOrderType = null;
                    _cart.clear();
                  });
                },
                child: const Text('Change Order Type'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _menuItems.length,
            itemBuilder: (context, index) {
              final item = _menuItems[index];
              final qty = _cart[item.id] ?? 0;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(item.name),
                  subtitle: Text('\$${item.price.toStringAsFixed(2)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: qty > 0 ? () => _updateCart(item, -1) : null,
                      ),
                      Text(qty.toString()),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => _updateCart(item, 1),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            border: Border(top: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSummaryRow('Subtotal', _subtotal),
              _buildSummaryRow('Tax (10%)', _tax),
              const Divider(),
              _buildSummaryRow('Total', _total, isTotal: true),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _cart.isNotEmpty ? () {} : null,
                child: Text(_cart.isNotEmpty ? 'Confirm Order' : 'Add items to cart'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          Text('\$${amount.toStringAsFixed(2)}', style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
