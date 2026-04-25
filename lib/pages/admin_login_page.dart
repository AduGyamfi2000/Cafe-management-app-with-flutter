import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../models/menu_item.dart';
import 'admin_dashboard.dart';

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
      Navigator.of(context)
          .push<bool>(
            MaterialPageRoute(
              builder: (_) => AdminDashboard(menuItems: widget.menuItems),
            ),
          )
          .then((changed) {
            if (changed == true) {
              Navigator.of(context).pop(true);
            }
          });
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
