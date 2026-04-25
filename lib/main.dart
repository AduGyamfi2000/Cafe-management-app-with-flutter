import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  if (!prefs.containsKey('menu_items')) {
    await prefs.setString('menu_items', jsonEncode(_defaultMenuItems.map((item) => item.toJson()).toList()));
  }
  runApp(const CafeApp());
}

const String adminUsername = 'admin';
const String adminPassword = 'cafepass';

class CafeApp extends StatelessWidget {
  const CafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cafe Ordering',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

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

  Future<void> _saveMenuItems() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('menu_items', jsonEncode(_menuItems.map((item) => item.toJson()).toList()));
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
      MaterialPageRoute(builder: (_) => AdminLoginPage(menuItems: _menuItems)),
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

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key, required this.menuItems});

  final List<MenuItem> menuItems;

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorText;

  void _authenticate() {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    if (username == adminUsername && password == adminPassword) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => AdminDashboard(menuItems: widget.menuItems),
        ),
      );
    } else {
      setState(() {
        _errorText = 'Invalid username or password.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Login')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Enter admin credentials to manage the menu.', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 24),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 12),
              Text(_errorText!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _authenticate, child: const Text('Login')),
          ],
        ),
      ),
    );
  }
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key, required this.menuItems});

  final List<MenuItem> menuItems;

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  late List<MenuItem> _menuItems;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _menuItems = List<MenuItem>.from(widget.menuItems);
  }

  Future<void> _persistMenuItems() async {
    setState(() {
      _saving = true;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('menu_items', jsonEncode(_menuItems.map((item) => item.toJson()).toList()));
    setState(() {
      _saving = false;
    });
  }

  Future<void> _showEditDialog({MenuItem? menuItem}) async {
    final nameController = TextEditingController(text: menuItem?.name ?? '');
    final priceController = TextEditingController(text: menuItem?.price.toStringAsFixed(2) ?? '');
    final formKey = GlobalKey<FormState>();

    final isNew = menuItem == null;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isNew ? 'Add Menu Item' : 'Edit Menu Item'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Enter a name' : null,
                ),
                TextFormField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Price'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Enter a price';
                    final parsed = double.tryParse(value);
                    if (parsed == null || parsed < 0) return 'Enter a valid price';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(context).pop(true);
                }
              },
              child: Text(isNew ? 'Add' : 'Save'),
            ),
          ],
        );
      },
    );

    if (result != true) return;

    final name = nameController.text.trim();
    final price = double.parse(priceController.text.trim());
    setState(() {
      if (isNew) {
        final id = _menuItems.isEmpty ? 1 : (_menuItems.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1);
        _menuItems.add(MenuItem(id: id, name: name, price: price));
      } else {
        final index = _menuItems.indexWhere((element) => element.id == menuItem!.id);
        if (index >= 0) {
          _menuItems[index] = MenuItem(id: menuItem!.id, name: name, price: price);
        }
      }
    });
    await _persistMenuItems();
  }

  Future<void> _deleteItem(MenuItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete menu item'),
          content: Text('Delete "${item.name}" from the menu?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
          ],
        );
      },
    );
    if (confirmed != true) return;
    setState(() {
      _menuItems.removeWhere((element) => element.id == item.id);
    });
    await _persistMenuItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditDialog(),
        child: const Icon(Icons.add),
        tooltip: 'Add item',
      ),
      body: _saving
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Menu Management', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _menuItems.isEmpty
                        ? const Center(child: Text('No menu items. Add one using the button below.'))
                        : ListView.builder(
                            itemCount: _menuItems.length,
                            itemBuilder: (context, index) {
                              final item = _menuItems[index];
                              return Card(
                                child: ListTile(
                                  title: Text(item.name),
                                  subtitle: Text('\$${item.price.toStringAsFixed(2)}'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () => _showEditDialog(menuItem: item),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () => _deleteItem(item),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}

enum OrderType { eatIn, takeOut }

class MenuItem {
  MenuItem({required this.id, required this.name, required this.price});

  final int id;
  final String name;
  final double price;

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] as int,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'price': price};
  }
}

final List<MenuItem> _defaultMenuItems = [
  MenuItem(id: 1, name: 'Espresso', price: 3.50),
  MenuItem(id: 2, name: 'Cappuccino', price: 4.25),
  MenuItem(id: 3, name: 'Ham Sandwich', price: 7.95),
  MenuItem(id: 4, name: 'Caesar Salad', price: 6.50),
  MenuItem(id: 5, name: 'Chocolate Cake', price: 4.75),
];
