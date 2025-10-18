import 'package:cloud_firestore/cloud_firestore.dart';

class OrderReport {
  final String id;
  final String waiterName;
  final double totalAmount;
  final DateTime date;
  final List<OrderItem> orders;

  OrderReport({
    required this.id,
    required this.waiterName,
    required this.totalAmount,
    required this.date,
    required this.orders,
  });

  factory OrderReport.fromMap(String id, Map<String, dynamic> map) {
    final ordersList = (map['orders'] as List<dynamic>? ?? [])
        .map((e) => OrderItem.fromMap(e as Map<String, dynamic>))
        .toList();

    return OrderReport(
      id: id,
      waiterName: map['waiterName'] ?? 'Unknown',
      totalAmount: (map['totalAmount'] ?? 0.0).toDouble(),
      date: (map['date'] as Timestamp).toDate(),
      orders: ordersList,
    );
  }
}

class OrderItem {
  final String productName;
  final int quantity;
  final double totalPrice;

  OrderItem({
    required this.productName,
    required this.quantity,
    required this.totalPrice,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productName: map['productName'] ?? 'Unknown',
      quantity: (map['quantity'] ?? 0),
      totalPrice: (map['totalPrice'] ?? 0.0).toDouble(),
    );
  }
}
