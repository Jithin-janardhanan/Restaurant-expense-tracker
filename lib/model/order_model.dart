import 'package:cloud_firestore/cloud_firestore.dart';

class Order {
  String id;
  String waiterId;
  String productId;
  String productName;
  int quantity;
  double totalPrice;
  DateTime date;

  Order({
    required this.id,
    required this.waiterId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.totalPrice,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'waiterId': waiterId,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'totalPrice': totalPrice,
      // 🔥 Convert to Firestore Timestamp here
      'date': Timestamp.fromDate(date),
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'],
      waiterId: map['waiterId'],
      productId: map['productId'],
      productName: map['productName'],
      quantity: map['quantity'],
      totalPrice: (map['totalPrice'] ?? 0).toDouble(),
      // 🔥 Convert Timestamp back to DateTime
      date: (map['date'] as Timestamp).toDate(),
    );
  }
}
