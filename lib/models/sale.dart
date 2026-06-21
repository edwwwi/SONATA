class Sale {
  final int? id;
  final String billNumber;
  final double totalAmount;
  final DateTime createdAt;

  Sale({
    this.id,
    required this.billNumber,
    required this.totalAmount,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bill_number': billNumber,
      'total_amount': totalAmount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'],
      billNumber: map['bill_number'],
      totalAmount: map['total_amount'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Sale copyWith({
    int? id,
    String? billNumber,
    double? totalAmount,
    DateTime? createdAt,
  }) {
    return Sale(
      id: id ?? this.id,
      billNumber: billNumber ?? this.billNumber,
      totalAmount: totalAmount ?? this.totalAmount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
