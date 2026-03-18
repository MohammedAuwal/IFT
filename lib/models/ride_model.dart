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
  final String note;
  final String eta;
  final double? pickupLat;
  final double? pickupLng;
  final double? destinationLat;
  final double? destinationLng;
  final double? driverLat;
  final double? driverLng;
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
    required this.note,
    required this.eta,
    this.pickupLat,
    this.pickupLng,
    this.destinationLat,
    this.destinationLng,
    this.driverLat,
    this.driverLng,
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
      note: (map['note'] ?? '').toString(),
      eta: (map['eta'] ?? '').toString(),
      pickupLat: (map['pickupLat'] as num?)?.toDouble(),
      pickupLng: (map['pickupLng'] as num?)?.toDouble(),
      destinationLat: (map['destinationLat'] as num?)?.toDouble(),
      destinationLng: (map['destinationLng'] as num?)?.toDouble(),
      driverLat: (map['driverLat'] as num?)?.toDouble(),
      driverLng: (map['driverLng'] as num?)?.toDouble(),
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
      'note': note,
      'eta': eta,
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
      'destinationLat': destinationLat,
      'destinationLng': destinationLng,
      'driverLat': driverLat,
      'driverLng': driverLng,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
