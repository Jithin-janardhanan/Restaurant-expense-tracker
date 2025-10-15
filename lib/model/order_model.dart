import 'package:cloud_firestore/cloud_firestore.dart';

class Order {
  String id;
  String waiterId;
  DateTime date;
  List<Map<String, dynamic>> items;
  double totalAmount;

  Order({
    required this.id,
    required this.waiterId,
    required this.date,
    required this.items,
    required this.totalAmount,
  });

  Map<String, dynamic> toMap() {
    return {
      'waiterId': waiterId,
      'date': date,
      'items': items,
      'totalAmount': totalAmount,
    };
  }

  factory Order.fromMap(String id, Map<String, dynamic> map) {
    return Order(
      id: id,
      waiterId: map['waiterId'],
      date: (map['date'] as Timestamp).toDate(),
      items: List<Map<String, dynamic>>.from(map['items']),
      totalAmount: map['totalAmount'],
    );
  }
}
