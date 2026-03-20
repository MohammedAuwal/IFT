import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mix/core/constants/app_constants.dart';
import 'package:mix/models/order_model.dart';
import 'package:mix/models/product_model.dart';
import 'package:mix/models/ride_model.dart';
import 'package:mix/services/geocoding_service.dart';
import 'package:mix/services/pricing_service.dart';
import 'package:mix/services/routing_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MovementEstimate {
  final String pickupLabel;
  final String destinationLabel;
  final double pickupLat;
  final double pickupLng;
  final double destinationLat;
  final double destinationLng;
  final double distanceKm;
  final double durationMin;
  final double price;
  final String eta;
  final String routeGeometry;

  const MovementEstimate({
    required this.pickupLabel,
    required this.destinationLabel,
    required this.pickupLat,
    required this.pickupLng,
    required this.destinationLat,
    required this.destinationLng,
    required this.distanceKm,
    required this.durationMin,
    required this.price,
    required this.eta,
    required this.routeGeometry,
  });
}

class FirebaseService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  final GeocodingService _geocodingService = GeocodingService();
  final RoutingService _routingService = RoutingService();
  final PricingService _pricingService = PricingService();

  User? get currentUser => auth.currentUser;

  bool get isSuperAdmin => currentUser?.uid == AppConstants.superAdminUid;

  DocumentReference<Map<String, dynamic>> get _settingsDoc =>
      firestore.collection('app_settings').doc('general');

  Future<String> getVendorPickupAddress() async {
    final doc = await _settingsDoc.get();
    final data = doc.data() ?? {};
    final value = (data['vendorPickupAddress'] ?? '').toString().trim();

    if (value.isNotEmpty) {
      return value;
    }

    return AppConstants.defaultVendorLocation;
  }

  Stream<String> watchVendorPickupAddress() {
    return _settingsDoc.snapshots().map((doc) {
      final data = doc.data() ?? {};
      final value = (data['vendorPickupAddress'] ?? '').toString().trim();

      if (value.isNotEmpty) {
        return value;
      }

      return AppConstants.defaultVendorLocation;
    });
  }

  Future<void> updateVendorPickupAddress(String address) async {
    final trimmed = address.trim();
    if (trimmed.isEmpty) {
      throw Exception('Vendor pickup address cannot be empty');
    }

    await _settingsDoc.set({
      'vendorPickupAddress': trimmed,
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  Future<void> seedDefaultAppSettings() async {
    final doc = await _settingsDoc.get();
    if (!doc.exists) {
      await _settingsDoc.set({
        'vendorPickupAddress': AppConstants.defaultVendorLocation,
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
      return;
    }

    final data = doc.data() ?? {};
    final existing = (data['vendorPickupAddress'] ?? '').toString().trim();

    if (existing.isEmpty) {
      await _settingsDoc.set({
        'vendorPickupAddress': AppConstants.defaultVendorLocation,
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    }
  }

  Future<bool> isAdmin() async {
    final user = currentUser;
    if (user == null) return false;

    if (user.uid == AppConstants.superAdminUid) return true;

    final doc = await firestore
        .collection(AppConstants.adminsCollection)
        .doc(user.uid)
        .get();

    return doc.exists;
  }

  Future<bool> isDriver() async {
    final user = currentUser;
    if (user == null) return false;

    final doc = await firestore.collection('drivers').doc(user.uid).get();
    return doc.exists;
  }

  Future<void> addAdmin({
    required String uid,
    required String email,
  }) async {
    final addedBy = currentUser?.uid ?? '';
    await firestore.collection(AppConstants.adminsCollection).doc(uid).set({
      'uid': uid,
      'email': email,
      'role': 'admin',
      'addedBy': addedBy,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> addDriver({
    required String uid,
    required String name,
    required String email,
  }) async {
    await firestore.collection('drivers').doc(uid).set({
      'uid': uid,
      'name': name,
      'email': email,
      'available': true,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Stream<List<Map<String, dynamic>>> watchAdmins() {
    return firestore
        .collection(AppConstants.adminsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((e) => e.data()).toList());
  }

  Stream<List<Map<String, dynamic>>> watchDrivers() {
    return firestore
        .collection('drivers')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((e) => e.data()).toList());
  }

  Stream<int> watchProductsCount() {
    return firestore
        .collection(AppConstants.productsCollection)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> watchOrdersCount() {
    return firestore
        .collection(AppConstants.ordersCollection)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> watchRidesCount() {
    return firestore
        .collection(AppConstants.ridesCollection)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> watchAdminsCount() {
    return firestore
        .collection(AppConstants.adminsCollection)
        .snapshots()
        .map((snapshot) => snapshot.docs.length + 1);
  }

  Stream<int> watchActiveRideCount() {
    final user = currentUser;
    if (user == null) return Stream.value(0);

    return firestore
        .collection(AppConstants.ridesCollection)
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
      final rides = snapshot.docs
          .map((doc) => RideModel.fromMap(doc.id, doc.data()))
          .where((ride) => ride.isActive)
          .toList();
      return rides.length;
    });
  }

  Stream<List<Map<String, dynamic>>> watchRecentAdminActivity() {
    final productStream = firestore
        .collection(AppConstants.productsCollection)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'type': 'product',
                'title': 'Product: ${data['name'] ?? 'Unnamed'}',
                'subtitle': '₦${data['price'] ?? 0}',
                'createdAt': data['createdAt'] ?? '',
              };
            }).toList());

    final orderStream = firestore
        .collection(AppConstants.ordersCollection)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'type': 'order',
                'title': 'Order: ${doc.id}',
                'subtitle': 'Status: ${data['status'] ?? 'pending'}',
                'createdAt': data['createdAt'] ?? '',
              };
            }).toList());

    final rideStream = firestore
        .collection(AppConstants.ridesCollection)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'type': 'ride',
                'title': 'Ride: ${doc.id}',
                'subtitle':
                    '${data['pickup'] ?? ''} → ${data['destination'] ?? ''}',
                'createdAt': data['createdAt'] ?? '',
              };
            }).toList());

    return productStream.asyncMap((products) async {
      final orders = await orderStream.first;
      final rides = await rideStream.first;

      final merged = [...products, ...orders, ...rides];
      merged.sort((a, b) => (b['createdAt'] ?? '')
          .toString()
          .compareTo((a['createdAt'] ?? '').toString()));
      return merged.take(8).toList();
    });
  }

  Stream<List<String>> watchCategories() {
    return firestore
        .collection('categories')
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      final dbCategories = snapshot.docs
          .map((doc) => (doc.data()['name'] ?? '').toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final defaults = <String>[
        'General',
        'Spices',
        'Flours',
        'Foods',
        'Oils',
        'Trending',
        'Featured',
      ];

      return {...defaults, ...dbCategories}.toList()..sort();
    });
  }

  Future<void> addCategory(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    await firestore.collection('categories').doc(trimmed.toLowerCase()).set({
      'name': trimmed,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> removeCategory(String name) async {
    final trimmed = name.trim().toLowerCase();
    if (trimmed.isEmpty) return;

    await firestore.collection('categories').doc(trimmed).delete();
  }

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) {
    return firestore.collection(AppConstants.usersCollection).doc(uid);
  }

  Future<void> ensureUserProfile() async {
    final user = currentUser;
    if (user == null) return;

    final ref = _userDoc(user.uid);
    final snap = await ref.get();

    if (!snap.exists) {
      await ref.set({
        'uid': user.uid,
        'email': user.email ?? '',
        'displayName': user.displayName ?? '',
        'photoUrl': user.photoURL ?? '',
        'favorites': [],
        'cart': [],
        'addresses': [],
        'selectedAddress': '',
        'createdAt': DateTime.now().toIso8601String(),
      });
    } else {
      final data = snap.data() ?? {};
      final updates = <String, dynamic>{};

      if (user.displayName != null &&
          user.displayName!.isNotEmpty &&
          data['displayName'] != user.displayName) {
        updates['displayName'] = user.displayName;
      }

      if (user.photoURL != null &&
          user.photoURL!.isNotEmpty &&
          data['photoUrl'] != user.photoURL) {
        updates['photoUrl'] = user.photoURL;
      }

      if (user.email != null &&
          user.email!.isNotEmpty &&
          data['email'] != user.email) {
        updates['email'] = user.email;
      }

      if (updates.isNotEmpty) {
        await ref.set(updates, SetOptions(merge: true));
      }
    }
  }

  Future<void> updateDisplayName(String displayName) async {
    final user = currentUser;
    if (user == null) return;

    final trimmed = displayName.trim();
    if (trimmed.isEmpty) return;

    await user.updateDisplayName(trimmed);
    await user.reload();

    await _userDoc(user.uid).set({
      'displayName': trimmed,
    }, SetOptions(merge: true));
  }

  Stream<Map<String, dynamic>?> watchUserProfile() {
    final user = currentUser;
    if (user == null) return const Stream.empty();

    return _userDoc(user.uid).snapshots().map((doc) => doc.data());
  }

  Future<void> updateProfilePhoto(String photoUrl) async {
    final user = currentUser;
    if (user == null) return;

    await _userDoc(user.uid).set({
      'uid': user.uid,
      'email': user.email ?? '',
      'displayName': user.displayName ?? '',
      'photoUrl': photoUrl,
    }, SetOptions(merge: true));
  }

  Future<void> addAddress(String address) async {
    final user = currentUser;
    if (user == null || address.trim().isEmpty) return;

    final ref = _userDoc(user.uid);
    final snap = await ref.get();
    final data = snap.data() ?? {};
    final addresses = List<String>.from(data['addresses'] ?? []);
    addresses.add(address.trim());

    await ref.set({
      'addresses': addresses,
      'selectedAddress': address.trim(),
    }, SetOptions(merge: true));
  }

  Future<void> removeAddress(String address) async {
    final user = currentUser;
    if (user == null) return;

    final ref = _userDoc(user.uid);
    final snap = await ref.get();
    final data = snap.data() ?? {};
    final addresses = List<String>.from(data['addresses'] ?? []);
    final selectedAddress = (data['selectedAddress'] ?? '').toString();

    addresses.remove(address);

    await ref.set({
      'addresses': addresses,
      'selectedAddress': selectedAddress == address
          ? (addresses.isNotEmpty ? addresses.first : '')
          : selectedAddress,
    }, SetOptions(merge: true));
  }

  Future<void> setSelectedAddress(String address) async {
    final user = currentUser;
    if (user == null) return;

    await _userDoc(user.uid).set({
      'selectedAddress': address.trim(),
    }, SetOptions(merge: true));
  }

  Stream<String> watchSelectedAddress() {
    final user = currentUser;
    if (user == null) return Stream.value('');

    return _userDoc(user.uid).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return '';
      return (data['selectedAddress'] ?? '').toString();
    });
  }

  Stream<List<String>> watchFavorites() {
    final user = currentUser;
    if (user == null) return Stream.value([]);

    return _userDoc(user.uid).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return <String>[];
      return List<String>.from(data['favorites'] ?? []);
    });
  }

  Stream<List<ProductModel>> watchFavoriteProducts() {
    final user = currentUser;
    if (user == null) return Stream.value([]);

    return _userDoc(user.uid).snapshots().asyncMap((doc) async {
      final data = doc.data();
      final ids = List<String>.from(data?['favorites'] ?? []);
      if (ids.isEmpty) return <ProductModel>[];

      final snapshot =
          await firestore.collection(AppConstants.productsCollection).get();

      return snapshot.docs
          .where((doc) => ids.contains(doc.id))
          .map((doc) => ProductModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<void> toggleFavorite(String productId) async {
    final user = currentUser;
    if (user == null) return;

    final ref = _userDoc(user.uid);
    final snap = await ref.get();
    final data = snap.data() ?? {};
    final favorites = List<String>.from(data['favorites'] ?? []);

    if (favorites.contains(productId)) {
      favorites.remove(productId);
    } else {
      favorites.add(productId);
    }

    await ref.set({
      'favorites': favorites,
    }, SetOptions(merge: true));
  }

  Stream<List<Map<String, dynamic>>> watchCart() {
    final user = currentUser;
    if (user == null) return Stream.value([]);

    return _userDoc(user.uid).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return <Map<String, dynamic>>[];
      return List<Map<String, dynamic>>.from(data['cart'] ?? []);
    });
  }

  Stream<int> watchCartCount() {
    return watchCart().map(
      (cart) => cart.fold<int>(
        0,
        (sum, item) => sum + ((item['qty'] ?? 1) as int),
      ),
    );
  }

  Future<void> _saveLocalCart(List<Map<String, dynamic>> cart) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mix_local_cart', jsonEncode(cart));
  }

  Future<List<Map<String, dynamic>>> getLocalCart() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('mix_local_cart');
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List;
    return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> syncLocalCartToFirestore() async {
    final user = currentUser;
    if (user == null) return;

    final localCart = await getLocalCart();
    if (localCart.isEmpty) return;

    final ref = _userDoc(user.uid);
    await ref.set({'cart': localCart}, SetOptions(merge: true));
    await _saveLocalCart([]);
  }

  Future<void> addToCart({
    required String productId,
    required String name,
    required double price,
    required String imageUrl,
  }) async {
    final user = currentUser;

    if (user == null) {
      final local = await getLocalCart();
      final index = local.indexWhere((e) => e['productId'] == productId);

      if (index >= 0) {
        local[index] = {
          ...local[index],
          'qty': ((local[index]['qty'] ?? 1) as int) + 1,
        };
      } else {
        local.add({
          'productId': productId,
          'name': name,
          'price': price,
          'imageUrl': imageUrl,
          'qty': 1,
        });
      }

      await _saveLocalCart(local);
      return;
    }

    final ref = _userDoc(user.uid);
    final snap = await ref.get();
    final data = snap.data() ?? {};
    final cart = List<Map<String, dynamic>>.from(data['cart'] ?? []);

    final index = cart.indexWhere((e) => e['productId'] == productId);

    if (index >= 0) {
      final currentQty = (cart[index]['qty'] ?? 1) as int;
      cart[index] = {
        ...cart[index],
        'qty': currentQty + 1,
      };
    } else {
      cart.add({
        'productId': productId,
        'name': name,
        'price': price,
        'imageUrl': imageUrl,
        'qty': 1,
      });
    }

    await ref.set({
      'cart': cart,
    }, SetOptions(merge: true));
  }

  Future<void> updateCartQty({
    required String productId,
    required int qty,
  }) async {
    final user = currentUser;
    if (user == null) return;

    final ref = _userDoc(user.uid);
    final snap = await ref.get();
    final data = snap.data() ?? {};
    final cart = List<Map<String, dynamic>>.from(data['cart'] ?? []);

    final index = cart.indexWhere((e) => e['productId'] == productId);
    if (index < 0) return;

    if (qty <= 0) {
      cart.removeAt(index);
    } else {
      cart[index] = {
        ...cart[index],
        'qty': qty,
      };
    }

    await ref.set({'cart': cart}, SetOptions(merge: true));
  }

  Future<void> clearCart() async {
    final user = currentUser;
    if (user == null) {
      await _saveLocalCart([]);
      return;
    }

    await _userDoc(user.uid).set({
      'cart': [],
    }, SetOptions(merge: true));
  }

  Stream<List<OrderModel>> watchOrders() {
    final user = currentUser;
    if (user == null) return Stream.value([]);

    return firestore
        .collection(AppConstants.ordersCollection)
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OrderModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  Stream<List<OrderModel>> watchAllOrders() {
    return firestore
        .collection(AppConstants.ordersCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OrderModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    await firestore
        .collection(AppConstants.ordersCollection)
        .doc(orderId)
        .set({
      'status': status,
    }, SetOptions(merge: true));
  }

  Future<String> _resolveDeliveryAddress() async {
    final user = currentUser;
    if (user == null) return 'Customer delivery address';

    final profile = await _userDoc(user.uid).get();
    final data = profile.data() ?? {};
    final selected = (data['selectedAddress'] ?? '').toString().trim();
    final addresses = List<String>.from(data['addresses'] ?? []);

    if (selected.isNotEmpty) return selected;
    if (addresses.isNotEmpty) return addresses.first;

    throw Exception('Please save/select a delivery address before checkout');
  }

  Future<MovementEstimate> estimateMovement({
    required String type,
    required String pickup,
    required String destination,
  }) async {
    final pickupText = pickup.trim();
    final destinationText = destination.trim();

    if (pickupText.isEmpty || destinationText.isEmpty) {
      throw Exception('Pickup and destination are required');
    }

    final pickupLocation = await _geocodingService.searchLocation(pickupText);
    final destinationLocation =
        await _geocodingService.searchLocation(destinationText);

    final route = await _routingService.getRoute(
      pickupLat: pickupLocation.latitude,
      pickupLng: pickupLocation.longitude,
      destinationLat: destinationLocation.latitude,
      destinationLng: destinationLocation.longitude,
    );

    final price = _pricingService.calculateFare(
      type: type,
      distanceKm: route.distanceKm,
    );

    return MovementEstimate(
      pickupLabel: pickupLocation.displayName,
      destinationLabel: destinationLocation.displayName,
      pickupLat: pickupLocation.latitude,
      pickupLng: pickupLocation.longitude,
      destinationLat: destinationLocation.latitude,
      destinationLng: destinationLocation.longitude,
      distanceKm: route.distanceKm,
      durationMin: route.durationMin,
      price: price,
      eta: _pricingService.formatEta(route.durationMin),
      routeGeometry: route.geometry,
    );
  }

  Future<RideModel> _buildMovementRide({
    required String type,
    required String pickup,
    required String destination,
    required String rideType,
    required String note,
    String? productId,
    String? orderId,
    String? addressLabel,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('You need to be signed in');
    }

    final estimate = await estimateMovement(
      type: type,
      pickup: pickup,
      destination: destination,
    );

    final id = DateTime.now().millisecondsSinceEpoch.toString();

    return RideModel(
      id: id,
      type: type,
      userId: user.uid,
      pickup: estimate.pickupLabel,
      destination: estimate.destinationLabel,
      rideType: rideType,
      status: 'searching',
      driver: null,
      price: estimate.price,
      note: note,
      eta: estimate.eta,
      pickupLat: estimate.pickupLat,
      pickupLng: estimate.pickupLng,
      destinationLat: estimate.destinationLat,
      destinationLng: estimate.destinationLng,
      driverLat: null,
      driverLng: null,
      distanceKm: estimate.distanceKm,
      durationMin: estimate.durationMin,
      routeGeometry: estimate.routeGeometry,
      productId: productId,
      orderId: orderId,
      addressLabel: addressLabel,
      createdAt: DateTime.now(),
    );
  }

  Future<void> placeOrder(List<Map<String, dynamic>> cart) async {
    final user = currentUser;
    if (user == null || cart.isEmpty) return;

    final total = cart.fold<double>(
      0,
      (sum, item) =>
          sum +
          (((item['price'] ?? 0) as num).toDouble() *
              ((item['qty'] ?? 1) as int)),
    );

    final deliveryAddress = await _resolveDeliveryAddress();
    final vendorPickupAddress = await getVendorPickupAddress();
    final orderId = DateTime.now().millisecondsSinceEpoch.toString();

    final deliveryRide = await _buildMovementRide(
      type: 'delivery',
      pickup: vendorPickupAddress,
      destination: deliveryAddress,
      rideType: 'delivery',
      note: 'Auto-created from order $orderId',
      orderId: orderId,
      productId:
          cart.isNotEmpty ? (cart.first['productId'] ?? '').toString() : null,
      addressLabel: deliveryAddress,
    );

    final order = OrderModel(
      id: orderId,
      userId: user.uid,
      items: cart,
      totalAmount: total,
      status: 'pending',
      createdAt: DateTime.now(),
      deliveryRideId: deliveryRide.id,
      deliveryAddress: deliveryAddress,
    );

    await firestore
        .collection(AppConstants.ordersCollection)
        .doc(orderId)
        .set(order.toMap());

    await firestore
        .collection(AppConstants.ridesCollection)
        .doc(deliveryRide.id)
        .set(deliveryRide.toMap());

    await clearCart();
  }

  Stream<List<RideModel>> watchUserRides() {
    final user = currentUser;
    if (user == null) return Stream.value([]);

    return firestore
        .collection(AppConstants.ridesCollection)
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RideModel.fromMap(doc.id, doc.data()))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  Stream<List<RideModel>> watchAllRides() {
    return firestore
        .collection(AppConstants.ridesCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RideModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  Stream<List<RideModel>> watchDriverAssignedRides(String driverName) {
    return firestore
        .collection(AppConstants.ridesCollection)
        .where('driver', isEqualTo: driverName)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RideModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<bool> hasActiveRide() async {
    final user = currentUser;
    if (user == null) return false;

    final snapshot = await firestore
        .collection(AppConstants.ridesCollection)
        .where('userId', isEqualTo: user.uid)
        .get();

    final rides = snapshot.docs
        .map((doc) => RideModel.fromMap(doc.id, doc.data()))
        .toList();

    return rides.any(
      (r) => r.isActive && r.type == 'ride',
    );
  }

  Future<void> createRide({
    required String pickup,
    required String destination,
    required String rideType,
    required double price,
    String note = '',
    double? pickupLat,
    double? pickupLng,
    double? destinationLat,
    double? destinationLng,
  }) async {
    final user = currentUser;
    if (user == null) return;

    final active = await hasActiveRide();
    if (active) {
      throw Exception('You already have an active ride');
    }

    final ride = await _buildMovementRide(
      type: 'ride',
      pickup: pickup,
      destination: destination,
      rideType: rideType,
      note: note,
    );

    await firestore
        .collection(AppConstants.ridesCollection)
        .doc(ride.id)
        .set(ride.toMap());
  }

  Future<void> updateRideStatus({
    required String rideId,
    required String status,
    String? driver,
    String? eta,
    double? driverLat,
    double? driverLng,
  }) async {
    await firestore.collection(AppConstants.ridesCollection).doc(rideId).set({
      'status': status,
      if (driver != null) 'driver': driver,
      if (eta != null) 'eta': eta,
      if (driverLat != null) 'driverLat': driverLat,
      if (driverLng != null) 'driverLng': driverLng,
    }, SetOptions(merge: true));
  }

  Future<void> cancelRide(String rideId) async {
    await firestore.collection(AppConstants.ridesCollection).doc(rideId).set({
      'status': 'cancelled',
    }, SetOptions(merge: true));
  }

  Future<void> updateProduct(ProductModel product) async {
    await firestore
        .collection(AppConstants.productsCollection)
        .doc(product.id)
        .set(product.toMap(), SetOptions(merge: true));
  }

  Stream<List<ProductModel>> watchAllProducts() {
    return firestore
        .collection(AppConstants.productsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ProductModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<List<ProductModel>> watchTrendingProducts() {
    return watchAllProducts().map(
      (items) => items.where((item) => item.isTrending).toList(),
    );
  }

  Stream<List<ProductModel>> watchMyUploadedProducts() {
    final user = currentUser;
    if (user == null) return Stream.value([]);

    return firestore
        .collection(AppConstants.productsCollection)
        .where('createdBy', isEqualTo: user.uid)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ProductModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> deleteProduct(String productId) async {
    await firestore
        .collection(AppConstants.productsCollection)
        .doc(productId)
        .delete();
  }

  Future<void> seedDefaultCategoriesIfMissing() async {
    final defaults = [
      'General',
      'Spices',
      'Flours',
      'Foods',
      'Oils',
      'Trending',
      'Featured',
    ];

    for (final category in defaults) {
      final ref = firestore.collection('categories').doc(category.toLowerCase());
      final snap = await ref.get();
      if (!snap.exists) {
        await ref.set({
          'name': category,
          'createdAt': DateTime.now().toIso8601String(),
        });
      }
    }
  }
}
