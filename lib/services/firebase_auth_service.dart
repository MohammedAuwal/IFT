import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mix/services/fcm_service.dart';

class AuthFailure implements Exception {
  final String message;
  AuthFailure(this.message);

  @override
  String toString() => message;
}

class FirebaseAuthService {
  FirebaseAuthService({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  User? get currentUser => _firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<User?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        await FcmService.instance.syncTokenForCurrentUser();
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapFirebaseError(e.code, e.message));
    } catch (e) {
      if (e is AuthFailure) rethrow;
      throw AuthFailure('Login failed. Please try again.');
    }
  }

  Future<User?> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        await FcmService.instance.syncTokenForCurrentUser();
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapFirebaseError(e.code, e.message));
    } catch (e) {
      if (e is AuthFailure) rethrow;
      throw AuthFailure('Registration failed. Please try again.');
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw AuthFailure('Google sign-in was cancelled.');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if ((googleAuth.idToken ?? '').isEmpty) {
        throw AuthFailure(
          'Google sign-in failed because no ID token was returned.',
        );
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      final user = userCredential.user;
      if (user == null) {
        throw AuthFailure('Google sign-in failed. No user account was returned.');
      }

      await FcmService.instance.syncTokenForCurrentUser();
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapFirebaseError(e.code, e.message));
    } catch (e) {
      if (e is AuthFailure) rethrow;
      throw AuthFailure('Google Sign-In failed. Please try again.');
    }
  }

  Future<void> signOut() async {
    try {
      await FcmService.instance.removeCurrentDeviceTokenForCurrentUser();
    } catch (_) {}

    try {
      await _googleSignIn.signOut();
    } catch (_) {}

    await _firebaseAuth.signOut();
  }

  String _mapFirebaseError(String code, String? message) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email using a different sign-in method.';
      case 'email-already-in-use':
        return 'This email is already registered. Try signing in.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'popup-closed-by-user':
        return 'Google sign-in was cancelled.';
      default:
        return message ?? 'Authentication failed. Please try again.';
    }
  }
}
