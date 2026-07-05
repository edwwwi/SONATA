class Product {
  final int? id;
  final String name;
  final String? barcode;
  final String category;
  final String company;
  final String type;
  final double price;
  final double mrp;
  final double discount;
  
  // UOM Properties
  final bool isBoxPiece;
  final int piecesPerBox;
  final String? boxBarcode;
  final double boxMrp;
  final double boxDiscount;
  final double boxPrice;

  final int stock;
  final int? color;
  final int minimumStock;
  final bool isActive;

  String get displayStock {
    if (!isBoxPiece || piecesPerBox <= 1) return stock.toString();
    final boxes = stock ~/ piecesPerBox;
    final pieces = stock % piecesPerBox;
    if (boxes == 0) return '$pieces Nos';
    if (pieces == 0) return '$boxes Unit';
    return '$boxes Unit, $pieces Nos';
  }

  Product({
    this.id,
    required this.name,
    this.barcode,
    required this.category,
    this.company = 'Other',
    this.type = 'Ice Cream',
    required this.price,
    this.mrp = 0.0,
    this.discount = 0.0,
    this.isBoxPiece = false,
    this.piecesPerBox = 1,
    this.boxBarcode,
    this.boxMrp = 0.0,
    this.boxDiscount = 0.0,
    this.boxPrice = 0.0,
    required this.stock,
    this.color,
    this.minimumStock = 10,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'barcode': barcode,
      'category': category,
      'company': company,
      'type': type,
      'price': price,
      'mrp': mrp,
      'discount': discount,
      'is_box_piece': isBoxPiece ? 1 : 0,
      'pieces_per_box': piecesPerBox,
      'box_barcode': boxBarcode,
      'box_mrp': boxMrp,
      'box_discount': boxDiscount,
      'box_price': boxPrice,
      'stock': stock,
      'color': color,
      'minimum_stock': minimumStock,
      'is_active': isActive ? 1 : 0,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      barcode: map['barcode'],
      category: map['category'],
      company: map['company'] ?? 'Other',
      type: map['type'] ?? 'Ice Cream',
      price: (map['price'] as num).toDouble(),
      mrp: map['mrp'] != null ? (map['mrp'] as num).toDouble() : (map['price'] as num).toDouble(),
      discount: map['discount'] != null ? (map['discount'] as num).toDouble() : 0.0,
      isBoxPiece: map['is_box_piece'] == 1,
      piecesPerBox: map['pieces_per_box'] ?? 1,
      boxBarcode: map['box_barcode'],
      boxMrp: map['box_mrp'] != null ? (map['box_mrp'] as num).toDouble() : 0.0,
      boxDiscount: map['box_discount'] != null ? (map['box_discount'] as num).toDouble() : 0.0,
      boxPrice: map['box_price'] != null ? (map['box_price'] as num).toDouble() : 0.0,
      stock: map['stock'],
      color: map['color'],
      minimumStock: map['minimum_stock'] ?? 10,
      isActive: (map['is_active'] ?? 1) == 1,
    );
  }

  Product copyWith({
    int? id,
    String? name,
    String? barcode,
    String? category,
    String? company,
    String? type,
    double? price,
    double? mrp,
    double? discount,
    bool? isBoxPiece,
    int? piecesPerBox,
    String? boxBarcode,
    double? boxMrp,
    double? boxDiscount,
    double? boxPrice,
    int? stock,
    int? color,
    int? minimumStock,
    bool? isActive,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      category: category ?? this.category,
      company: company ?? this.company,
      type: type ?? this.type,
      price: price ?? this.price,
      mrp: mrp ?? this.mrp,
      discount: discount ?? this.discount,
      isBoxPiece: isBoxPiece ?? this.isBoxPiece,
      piecesPerBox: piecesPerBox ?? this.piecesPerBox,
      boxBarcode: boxBarcode ?? this.boxBarcode,
      boxMrp: boxMrp ?? this.boxMrp,
      boxDiscount: boxDiscount ?? this.boxDiscount,
      boxPrice: boxPrice ?? this.boxPrice,
      stock: stock ?? this.stock,
      color: color ?? this.color,
      minimumStock: minimumStock ?? this.minimumStock,
      isActive: isActive ?? this.isActive,
    );
  }
}
