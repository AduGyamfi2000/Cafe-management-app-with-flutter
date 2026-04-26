import 'package:cafe_management_app/models/menu_item.dart';
import 'package:cafe_management_app/models/order.dart';

class ReceiptGenerator {
  static String generateReceipt(
    Order order,
    List<MenuItem> menuItems,
  ) {
    final buffer = StringBuffer();
    
    buffer.writeln('════════════════════════════════');
    buffer.writeln('         CAFE RECEIPT');
    buffer.writeln('════════════════════════════════');
    buffer.writeln('');
    
    buffer.writeln('Order Type: ${order.orderType == 'eat_in' ? 'Eat-In' : 'Take-Out'}');
    buffer.writeln('Order ID: ${order.id}');
    buffer.writeln('Date: ${order.timestamp.toString().split('.')[0]}');
    buffer.writeln('');
    
    buffer.writeln('────────────────────────────────');
    buffer.writeln('Items:');
    buffer.writeln('────────────────────────────────');
    
    for (final entry in order.items.entries) {
      final itemId = entry.key;
      final quantity = entry.value;
      final menuItem = menuItems.firstWhere(
        (item) => item.id == itemId,
        orElse: () => const MenuItem(id: 0, name: 'Unknown', price: 0),
      );
      
      final lineTotal = menuItem.price * quantity;
      
      buffer.writeln(
        '${menuItem.name} x$quantity @ \$${menuItem.price.toStringAsFixed(2)} = \$${lineTotal.toStringAsFixed(2)}',
      );
    }
    
    buffer.writeln('');
    buffer.writeln('────────────────────────────────');
    buffer.writeln('Subtotal:           \$${order.subtotal.toStringAsFixed(2)}');
    buffer.writeln('Tax (10%):          \$${order.tax.toStringAsFixed(2)}');
    buffer.writeln('────────────────────────────────');
    buffer.writeln('TOTAL:              \$${order.total.toStringAsFixed(2)}');
    buffer.writeln('════════════════════════════════');
    buffer.writeln('');
    buffer.writeln('Thank you for your order!');
    buffer.writeln('');
    
    return buffer.toString();
  }
}
