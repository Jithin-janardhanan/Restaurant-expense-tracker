class Product {
  String id;
  String name;
  int? count; // quantity for countable products
  double? price; // price per item for countable products
  Map<String, double>? portionPrice; // price for each portion: qtr, half, full

  Product({
    required this.id,
    required this.name,
    this.count,
    this.price,
    this.portionPrice,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      if (count != null) 'count': count,
      if (price != null) 'price': price,
      if (portionPrice != null) 'portionPrice': portionPrice,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      count: map['count'],
      price: map['price'] != null ? (map['price'] as num).toDouble() : null,
      portionPrice: map['portionPrice'] != null
          ? Map<String, double>.from(
              (map['portionPrice'] as Map).map((k, v) => MapEntry(k, (v as num).toDouble())),
            )
          : null,
    );
  }
}
