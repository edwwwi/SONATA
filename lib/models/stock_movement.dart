class StockMovement {
  final int? id;
  final int productId;
  final int quantity;
  final String movementType; // 'IN' or 'OUT'
  final DateTime createdAt;

  StockMovement({
    this.id,
    required this.productId,
    required this.quantity,
    required this.movementType,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'quantity': quantity,
      'movement_type': movementType,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory StockMovement.fromMap(Map<String, dynamic> map) {
    return StockMovement(
      id: map['id'],
      productId: map['product_id'],
      quantity: map['quantity'],
      movementType: map['movement_type'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  StockMovement copyWith({
    int? id,
    int? productId,
    int? quantity,
    String? movementType,
    DateTime? createdAt,
  }) {
    return StockMovement(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      movementType: movementType ?? this.movementType,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
