class StockMovement {
  final int? id;
  final int productId;
  final String productName;
  final int quantity;
  final int previousStock;
  final int currentStock;
  final String movementType; // 'STOCK_IN', 'SALE', 'MANUAL_EDIT'
  final String? remarks;
  final DateTime createdAt;

  StockMovement({
    this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.previousStock,
    required this.currentStock,
    required this.movementType,
    this.remarks,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'previous_stock': previousStock,
      'current_stock': currentStock,
      'movement_type': movementType,
      'remarks': remarks,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory StockMovement.fromMap(Map<String, dynamic> map) {
    return StockMovement(
      id: map['id'],
      productId: map['product_id'],
      productName: map['product_name'],
      quantity: map['quantity'],
      previousStock: map['previous_stock'],
      currentStock: map['current_stock'],
      movementType: map['movement_type'],
      remarks: map['remarks'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  StockMovement copyWith({
    int? id,
    int? productId,
    String? productName,
    int? quantity,
    int? previousStock,
    int? currentStock,
    String? movementType,
    String? remarks,
    DateTime? createdAt,
  }) {
    return StockMovement(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      previousStock: previousStock ?? this.previousStock,
      currentStock: currentStock ?? this.currentStock,
      movementType: movementType ?? this.movementType,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
