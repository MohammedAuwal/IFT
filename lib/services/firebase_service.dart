import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mix/core/constants/app_constants.dart';
import 'package:mix/models/order_model.dart';
import 'package:mix/models/product_model.dart';
import 'package:mix/models/ride_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  User? get currentUser => auth.currentUser;

  bool get isSuperAdmin => currentUser?.uid == AppConstants.superAdminUid;

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
          .where((ride) => ride.status != 'completed' && ride.status != 'cancelled')
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
                'subtitle': '${data['pickup'] ?? ''} → ${data['destination'] ?? ''}',
                'createdAt': data['createdAt'] ?? '',
              };
            }).toList());

    return productStream.asyncMap((products) async {
      final orders = await orderStream.first;
      final rides = await rideStream.first;

      final merged = [...products, ...orders, ...rides];
      merged.sort((a, b) => (b['createdAt'] ?? '').toString().compareTo((a['createdAt'] ?? '').toString()));
      return merged.take(8).toList();
    });
  }

  Stream<List<String>> watchCategories() {
    return firestore
        .collection('categories')
        .orderBy('name')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => (doc.data()['name'] ?? '').toString()).where((e) => e.isNotEmpty).toList());
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
        'email': user.email,
        'displayName': user.displayName,
        'photoUrl': user.photoURL,
        'favorites': [],
        'cart': [],
        'addresses': [],
        'createdAt': DateTime.now().toIso8601String(),
      });
    }
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
      'email': user.email,
      'displayName': user.displayName,
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

    await ref.set({'addresses': addresses}, SetOptions(merge: true));
  }

  Future<void> removeAddress(String address) async {
    final user = currentUser;
    if (user == null) return;

    final ref = _userDoc(user.uid);
    final snap = await ref.get();
    final data = snap.data() ?? {};
    final addresses = List<String>.from(data['addresses'] ?? []);
    addresses.remove(address);

    await ref.set({'addresses': addresses}, SetOptions(merge: true));
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

      final snapshot = await firestore
          .collection(AppConstants.productsCollection)
          .get();

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
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
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
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
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
    await firestore.collection(AppConstants.ordersCollection).doc(orderId).set({
      'status': status,
    }, SetOptions(merge: true));
  }

  Future<void> placeOrder(List<Map<String, dynamic>> cart) async {
    final user = currentUser;
    if (user == null || cart.isEmpty) return;

    final total = cart.fold<double>(
      0,
      (sum, item) => sum + (((item['price'] ?? 0) as num).toDouble() * ((item['qty'] ?? 1) as int)),
    );

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final order = OrderModel(
      id: id,
      userId: user.uid,
      items: cart,
      totalAmount: total,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    await firestore.collection(AppConstants.ordersCollection).doc(id).set(order.toMap());
    await clearCart();
  }

  Stream<List<RideModel>> watchUserRides() {
    final user = currentUser;
    if (user == null) return Stream.value([]);

    return firestore
        .collection(AppConstants.ridesCollection)
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => RideModel.fromMap(doc.id, doc.data())).toList());
  }

  Stream<List<RideModel>> watchAllRides() {
    return firestore
        .collection(AppConstants.ridesCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => RideModel.fromMap(doc.id, doc.data())).toList());
  }

  Stream<List<RideModel>> watchDriverAssignedRides(String driverName) {
    return firestore
        .collection(AppConstants.ridesCollection)
        .where('driver', isEqualTo: driverName)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => RideModel.fromMap(doc.id, doc.data())).toList());
  }

  Future<bool> hasActiveRide() async {
    final user = currentUser;
    if (user == null) return false;

    final snapshot = await firestore
        .collection(AppConstants.ridesCollection)
        .where('userId', isEqualTo: user.uid)
        .get();

    final rides = snapshot.docs.map((doc) => RideModel.fromMap(doc.id, doc.data())).toList();
    return rides.any((r) => r.status != 'completed' && r.status != 'cancelled');
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

    final id = DateTime.now().millisecondsSinceEpoch.toString();

    final ride = RideModel(
      id: id,
      type: 'ride',
      userId: user.uid,
      pickup: pickup,
      destination: destination,
      rideType: rideType,
      status: 'searching',
      driver: null,
      price: price,
      note: note,
      eta: '5 mins',
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      destinationLat: destinationLat,
      destinationLng: destinationLng,
      driverLat: null,
      driverLng: null,
      createdAt: DateTime.now(),
    );

    await firestore.collection(AppConstants.ridesCollection).doc(id).set(ride.toMap());
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
}
