class OrderModel {
  final String id;
  final String userId;
  final List<Map<String, dynamic>> items;
  final double totalAmount;
  final String status;
  final DateTime createdAt;
  final String deliveryRideId;
  final String deliveryAddress;

  OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.deliveryRideId = '',
    this.deliveryAddress = '',
  });

  factory OrderModel.fromMap(String id, Map<String, dynamic> map) {
    return OrderModel(
      id: id,
      userId: (map['userId'] ?? '').toString(),
      items: List<Map<String, dynamic>>.from(map['items'] ?? []),
      totalAmount: ((map['totalAmount'] ?? 0) as num).toDouble(),
      status: (map['status'] ?? 'pending').toString(),
      createdAt:
          DateTime.tryParse((map['createdAt'] ?? '').toString()) ??
              DateTime.now(),
      deliveryRideId: (map['deliveryRideId'] ?? '').toString(),
      deliveryAddress: (map['deliveryAddress'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'items': items,
      'totalAmount': totalAmount,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'deliveryRideId': deliveryRideId,
      'deliveryAddress': deliveryAddress,
    };
  }

  OrderModel copyWith({
    String? id,
    String? userId,
    List<Map<String, dynamic>>? items,
    double? totalAmount,
    String? status,
    DateTime? createdAt,
    String? deliveryRideId,
    String? deliveryAddress,
  }) {
    return OrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      deliveryRideId: deliveryRideId ?? this.deliveryRideId,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
    );
  }
}
