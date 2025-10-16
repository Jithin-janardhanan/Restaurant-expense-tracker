class Product {
  String id;
  String name;
  int? count;
  double? price;
  Map<String, double>? portionPrice;

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
              (map['portionPrice'] as Map).map(
                (k, v) => MapEntry(k, (v as num).toDouble()),
              ),
            )
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
