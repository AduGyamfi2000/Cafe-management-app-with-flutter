import 'dart:convert';

import 'package:cafe_management_app/models/menu_item.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        final index = _menuItems.indexWhere((element) => element.id == menuItem.id);
        if (index >= 0) {
          _menuItems[index] = MenuItem(id: menuItem.id, name: name, price: price);
        }
      }
    });
    await _persistMenuItems();

    nameController.dispose();
    priceController.dispose();
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
        tooltip: 'Add item',
        child: const Icon(Icons.add),
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
