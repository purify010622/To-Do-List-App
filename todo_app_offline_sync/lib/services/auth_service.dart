import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';

/// Service for handling authentication operations
class AuthService {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final FlutterSecureStorage _secureStorage;

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  AuthService({
    firebase_auth.FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    FlutterSecureStorage? secureStorage,
  })  : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Sign in with Google OAuth
  Future<User?> signInWithGoogle() async {
    try {
      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final firebase_auth.UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      final firebase_auth.User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        return null;
      }

      // Get the ID token
      final String? token = await firebaseUser.getIdToken();

      // Create our User model
      final user = User(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName,
        photoUrl: firebaseUser.photoURL,
      );

      // Store token and user data securely
      if (token != null) {
        await _secureStorage.write(key: _tokenKey, value: token);
      }
      await _secureStorage.write(
        key: _userKey,
        value: _userToJson(user),
      );

      return user;
    } catch (e) {
      throw Exception('Failed to sign in with Google: $e');
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    try {
      // Sign out from Google
      await _googleSignIn.signOut();

      // Sign out from Firebase
      await _firebaseAuth.signOut();

      // Clear stored token and user data
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.delete(key: _userKey);
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  /// Check authentication status on app start
  Future<User?> checkAuthStatus() async {
    try {
      // Check if we have a stored token
      final String? token = await _secureStorage.read(key: _tokenKey);

      if (token == null) {
        return null;
      }

      // Check if Firebase user is still signed in
      final firebase_auth.User? firebaseUser = _firebaseAuth.currentUser;

      if (firebaseUser == null) {
        // Token exists but user is not signed in - clear storage
        await _secureStorage.delete(key: _tokenKey);
        await _secureStorage.delete(key: _userKey);
        return null;
      }

      // Try to get a fresh token to verify it's still valid
      try {
        final String? freshToken = await firebaseUser.getIdToken(true);
        if (freshToken != null) {
          // Update stored token
          await _secureStorage.write(key: _tokenKey, value: freshToken);
        }
      } catch (e) {
        // Token refresh failed - user needs to sign in again
        await _secureStorage.delete(key: _tokenKey);
        await _secureStorage.delete(key: _userKey);
        return null;
      }

      // Retrieve stored user data
      final String? userData = await _secureStorage.read(key: _userKey);

      if (userData != null) {
        return _userFromJson(userData);
      }

      // If no stored user data, create from Firebase user
      final user = User(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName,
        photoUrl: firebaseUser.photoURL,
      );

      // Store user data
      await _secureStorage.write(
        key: _userKey,
        value: _userToJson(user),
      );

      return user;
    } catch (e) {
      throw Exception('Failed to check auth status: $e');
    }
  }

  /// Get the current authentication token
  Future<String?> getAuthToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  /// Helper method to convert User to JSON string
  String _userToJson(User user) {
    final json = user.toJson();
    return '${json['uid']}|${json['email']}|${json['displayName'] ?? ''}|${json['photoUrl'] ?? ''}';
  }

  /// Helper method to convert JSON string to User
  User _userFromJson(String jsonString) {
    final parts = jsonString.split('|');
    return User(
      uid: parts[0],
      email: parts[1],
      displayName: parts[2].isEmpty ? null : parts[2],
      photoUrl: parts[3].isEmpty ? null : parts[3],
    );
  }
}
