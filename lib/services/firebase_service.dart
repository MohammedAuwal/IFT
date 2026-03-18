import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mix/core/constants/app_constants.dart';
import 'package:mix/models/order_model.dart';
import 'package:mix/models/product_model.dart';

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

  Stream<bool> watchIsAdmin() async* {
    final user = currentUser;
    if (user == null) {
      yield false;
      return;
    }

    if (user.uid == AppConstants.superAdminUid) {
      yield true;
      return;
    }

    yield* firestore
        .collection(AppConstants.adminsCollection)
        .doc(user.uid)
        .snapshots()
        .map((doc) => doc.exists);
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

  Stream<List<Map<String, dynamic>>> watchAdmins() {
    return firestore
        .collection(AppConstants.adminsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((e) => e.data()).toList());
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

  Future<void> addToCart({
    required String productId,
    required String name,
    required double price,
    required String imageUrl,
  }) async {
    final user = currentUser;
    if (user == null) return;

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
    if (user == null) return;

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

  Future<void> updateProduct(ProductModel product) async {
    await firestore
        .collection(AppConstants.productsCollection)
        .doc(product.id)
        .set(product.toMap(), SetOptions(merge: true));
  }
}
