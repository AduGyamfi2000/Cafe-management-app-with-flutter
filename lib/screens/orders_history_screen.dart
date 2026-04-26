import 'package:cafe_management_app/models/menu_item.dart';
import 'package:cafe_management_app/models/order.dart';
import 'package:cafe_management_app/services/order_service.dart';
import 'package:cafe_management_app/services/receipt_generator.dart';
import 'package:flutter/material.dart';

class OrdersHistoryScreen extends StatefulWidget {
  const OrdersHistoryScreen({
    super.key,
    required this.menuItems,
  });

  final List<MenuItem> menuItems;

  @override
  State<OrdersHistoryScreen> createState() => _OrdersHistoryScreenState();
}

class _OrdersHistoryScreenState extends State<OrdersHistoryScreen> {
  late Future<List<Order>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = OrderService.getOrders();
  }

  void _refreshOrders() {
    setState(() {
      _ordersFuture = OrderService.getOrders();
    });
  }

  Future<void> _showReceiptDialog(Order order) async {
    final receipt = ReceiptGenerator.generateReceipt(order, widget.menuItems);
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Order Receipt'),
          content: SingleChildScrollView(
            child: Text(
              receipt,
              style: const TextStyle(
                fontFamily: 'Courier',
                fontSize: 12,
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshOrders,
          ),
        ],
      ),
      body: FutureBuilder<List<Order>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return const Center(
              child: Text('No orders yet'),
            );
          }

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final orderType = order.orderType == 'eat_in' ? 'Eat-In' : 'Take-Out';
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ListTile(
                  title: Text('Order #${order.id}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Type: $orderType'),
                      Text('Total: \$${order.total.toStringAsFixed(2)}'),
                      Text(
                        'Time: ${order.timestamp.hour}:${order.timestamp.minute.toString().padLeft(2, '0')}',
                      ),
                      if (order.customerEmail != null)
                        Text('Email: ${order.customerEmail}'),
                      if (order.customerPhone != null)
                        Text('Phone: ${order.customerPhone}'),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.receipt),
                    onPressed: () => _showReceiptDialog(order),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
