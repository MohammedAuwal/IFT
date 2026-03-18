import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mix/core/constants/app_constants.dart';

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
}
