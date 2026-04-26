import 'package:cafe_management_app/models/menu_item.dart';
import 'package:cafe_management_app/models/order.dart';
import 'package:cafe_management_app/services/order_service.dart';
import 'package:cafe_management_app/services/receipt_generator.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class OrderConfirmationDialog extends StatefulWidget {
  const OrderConfirmationDialog({
    super.key,
    required this.cart,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.orderType,
    required this.menuItems,
  });

  final Map<int, int> cart;
  final double subtotal;
  final double tax;
  final double total;
  final String orderType;
  final List<MenuItem> menuItems;

  @override
  State<OrderConfirmationDialog> createState() =>
      _OrderConfirmationDialogState();
}

class _OrderConfirmationDialogState extends State<OrderConfirmationDialog> {
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _loadingOrder = false;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _confirmOrder() async {
    setState(() {
      _loadingOrder = true;
    });

    try {
      // Create order
      final order = Order(
        id: const Uuid().v4().substring(0, 8).toUpperCase(),
        items: widget.cart,
        subtotal: widget.subtotal,
        tax: widget.tax,
        total: widget.total,
        orderType: widget.orderType,
        timestamp: DateTime.now(),
        customerEmail: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        customerPhone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
      );

      // Save order
      await OrderService.saveOrder(order);

      // Generate receipt
      final receipt =
          ReceiptGenerator.generateReceipt(order, widget.menuItems);

      if (mounted) {
        // Show receipt dialog
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              title: const Text('Order Confirmed!'),
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
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );

        if (mounted) {
          Navigator.of(context).pop(true); // Close confirmation dialog
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingOrder = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirm Order'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Type: ${widget.orderType == 'eat_in' ? 'Eat-In' : 'Take-Out'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('Items:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            ...widget.cart.entries.map((entry) {
              final item = widget.menuItems
                  .firstWhere((m) => m.id == entry.key);
              return Text(
                '${item.name} x${entry.value} = \$${(item.price * entry.value).toStringAsFixed(2)}',
              );
            }),
            const SizedBox(height: 12),
            Text(
              'Subtotal: \$${widget.subtotal.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Tax (10%): \$${widget.tax.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Total: \$${widget.total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            const Text(
              'Optional: Share receipt via email or SMS',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email (optional)',
                hintText: 'user@example.com',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone (optional)',
                hintText: '+1234567890',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loadingOrder
              ? null
              : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _loadingOrder ? null : _confirmOrder,
          child: _loadingOrder
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Confirm Order'),
        ),
      ],
    );
  }
}
