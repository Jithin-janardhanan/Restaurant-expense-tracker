class Order {
  String id;
  String waiterId;
  String productId;
  String productName;
  int quantity;
  double totalPrice;

  Order({
    required this.id,
    required this.waiterId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.totalPrice,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'waiterId': waiterId,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'totalPrice': totalPrice,
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'],
      waiterId: map['waiterId'],
      productId: map['productId'],
      productName: map['productName'],
      quantity: map['quantity'],
      totalPrice: (map['totalPrice'] as num).toDouble(),
    );
  }
}
