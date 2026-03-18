class OrderModel {
  final String id;
  final String userId;
  final List<Map<String, dynamic>> items;
  final double totalAmount;
  final String status;
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
  });

  factory OrderModel.fromMap(String id, Map<String, dynamic> map) {
    return OrderModel(
      id: id,
      userId: (map['userId'] ?? '').toString(),
      items: List<Map<String, dynamic>>.from(map['items'] ?? []),
      totalAmount: ((map['totalAmount'] ?? 0) as num).toDouble(),
      status: (map['status'] ?? 'pending').toString(),
      createdAt: DateTime.tryParse((map['createdAt'] ?? '').toString()) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'items': items,
      'totalAmount': totalAmount,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
