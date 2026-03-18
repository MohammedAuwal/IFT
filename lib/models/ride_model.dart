class RideModel {
  final String id;
  final String type;
  final String userId;
  final String pickup;
  final String destination;
  final String rideType;
  final String status;
  final String? driver;
  final double price;
  final DateTime createdAt;

  RideModel({
    required this.id,
    required this.type,
    required this.userId,
    required this.pickup,
    required this.destination,
    required this.rideType,
    required this.status,
    required this.driver,
    required this.price,
    required this.createdAt,
  });

  factory RideModel.fromMap(String id, Map<String, dynamic> map) {
    return RideModel(
      id: id,
      type: (map['type'] ?? 'ride').toString(),
      userId: (map['userId'] ?? '').toString(),
      pickup: (map['pickup'] ?? '').toString(),
      destination: (map['destination'] ?? '').toString(),
      rideType: (map['rideType'] ?? 'car').toString(),
      status: (map['status'] ?? 'searching').toString(),
      driver: map['driver']?.toString(),
      price: ((map['price'] ?? 0) as num).toDouble(),
      createdAt: DateTime.tryParse((map['createdAt'] ?? '').toString()) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'userId': userId,
      'pickup': pickup,
      'destination': destination,
      'rideType': rideType,
      'status': status,
      'driver': driver,
      'price': price,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
