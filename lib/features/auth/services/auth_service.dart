import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/models.dart';

/// Authentication Service
/// Handles all authentication operations including sign in, sign up, and sign out
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream of authentication state changes
  /// Emits UserModel when user is authenticated, null otherwise
  Stream<UserModel?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      
      // Fetch user data from Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();
      
      if (!userDoc.exists) return null;
      
      return UserModel.fromFirestore(userDoc);
    });
  }

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Sign in with email and password
  Future<UserModel> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Sign in failed');
      }

      // Fetch user data
      final userDoc = await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('User data not found');
      }

      return UserModel.fromFirestore(userDoc);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Register new user with email and password
  Future<UserModel> registerWithEmailPassword({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? companyName,
    String? phoneNumber,
  }) async {
    try {
      // Create auth user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Registration failed');
      }

      // Create user document in Firestore
      final user = UserModel(
        id: credential.user!.uid,
        email: email,
        name: name,
        role: role,
        companyName: companyName,
        phoneNumber: phoneNumber,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(user.id)
          .set(user.toFirestore());

      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Handle Firebase Auth exceptions and return user-friendly messages
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'invalid-email':
        return 'Invalid email address';
      case 'weak-password':
        return 'Password is too weak';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      default:
        return 'Authentication error: ${e.message}';
    }
  }
}