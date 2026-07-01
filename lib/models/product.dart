class Product {
  final int? id;
  final String name;
  final String? barcode;
  final String category;
  final double price;
  final int stock;
  final int? color;
  final int minimumStock;

  Product({
    this.id,
    required this.name,
    this.barcode,
    required this.category,
    required this.price,
    required this.stock,
    this.color,
    this.minimumStock = 10,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'barcode': barcode,
      'category': category,
      'price': price,
      'stock': stock,
      'color': color,
      'minimum_stock': minimumStock,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      barcode: map['barcode'],
      category: map['category'],
      price: map['price'],
      stock: map['stock'],
      color: map['color'],
      minimumStock: map['minimum_stock'] ?? 10,
    );
  }

  Product copyWith({
    int? id,
    String? name,
    String? barcode,
    String? category,
    double? price,
    int? stock,
    int? color,
    int? minimumStock,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      category: category ?? this.category,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      color: color ?? this.color,
      minimumStock: minimumStock ?? this.minimumStock,
    );
  }
}
