class Sale {
  final int? id;
  final String billNumber;
  final double totalAmount;
  final bool isDue;
  final String? dueName;
  final DateTime createdAt;

  Sale({
    this.id,
    required this.billNumber,
    required this.totalAmount,
    this.isDue = false,
    this.dueName,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bill_number': billNumber,
      'total_amount': totalAmount,
      'is_due': isDue ? 1 : 0,
      'due_name': dueName,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'],
      billNumber: map['bill_number'],
      totalAmount: map['total_amount'],
      isDue: (map['is_due'] ?? 0) == 1,
      dueName: map['due_name'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Sale copyWith({
    int? id,
    String? billNumber,
    double? totalAmount,
    bool? isDue,
    String? dueName,
    DateTime? createdAt,
  }) {
    return Sale(
      id: id ?? this.id,
      billNumber: billNumber ?? this.billNumber,
      totalAmount: totalAmount ?? this.totalAmount,
      isDue: isDue ?? this.isDue,
      dueName: dueName ?? this.dueName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
