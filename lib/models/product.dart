class Product {
  final int? id;
  final String name;
  final String? barcode;
  final String category;
  final double price;
  final int stock;
  final String? imagePath;

  Product({
    this.id,
    required this.name,
    this.barcode,
    required this.category,
    required this.price,
    required this.stock,
    this.imagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'barcode': barcode,
      'category': category,
      'price': price,
      'stock': stock,
      'image_path': imagePath,
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
      imagePath: map['image_path'],
    );
  }

  Product copyWith({
    int? id,
    String? name,
    String? barcode,
    String? category,
    double? price,
    int? stock,
    String? imagePath,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      category: category ?? this.category,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}
