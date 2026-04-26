import 'dart:convert';
import 'package:cafe_management_app/constants/menu_constants.dart';
import 'package:cafe_management_app/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  if (!prefs.containsKey('menu_items')) {
    await prefs.setString(
      'menu_items',
      jsonEncode(
        defaultMenuItems.map((item) => item.toJson()).toList(),
      ),
    );
  }

  runApp(const CafeApp());
}

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
