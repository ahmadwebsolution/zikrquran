import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_model.dart';

class FirebaseAuthService {
  UserModel? _localUser;
  String? _lastMockPhoneNumber;
  final StreamController<UserModel?> _localAuthStream = StreamController<UserModel?>.broadcast();
  static const String _localUserKey = 'local_saved_user';
  static const String _registeredUsersKey = 'local_registered_users_db';

  FirebaseAuthService() {
    _loadLocalUser();
  }

  Future<void> _loadLocalUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString(_localUserKey);
      if (userStr != null) {
        final map = jsonDecode(userStr) as Map<String, dynamic>;
        _localUser = UserModel.fromMap(map);
        _localAuthStream.add(_localUser);
      }
    } catch (e) {
      debugPrint('Error loading saved local user: $e');
    }
  }

  Future<void> _saveLocalUser(UserModel? user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (user != null) {
        await prefs.setString(_localUserKey, jsonEncode(user.toMap()));
      } else {
        await prefs.remove(_localUserKey);
      }
    } catch (e) {
      debugPrint('Error saving local user: $e');
    }
  }

  Future<Map<String, Map<String, dynamic>>> _getRegisteredUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_registeredUsersKey);
      if (str != null) {
        final decoded = jsonDecode(str) as Map<String, dynamic>;
        return decoded.map((k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)));
      }
    } catch (e) {
      debugPrint('Error reading registered users: $e');
    }
    return {};
  }

  Future<void> _saveRegisteredUserRecord(String email, String password, String name, String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final users = await _getRegisteredUsers();
    users[email.toLowerCase().trim()] = {
      'uid': uid,
      'email': email.trim(),
      'password': password,
      'displayName': name,
    };
    await prefs.setString(_registeredUsersKey, jsonEncode(users));
  }

  FirebaseAuth? get _auth {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseAuth.instance;
      }
    } catch (e) {
      debugPrint('Firebase not initialized yet: $e');
    }
    return null;
  }

  // Stream of auth state changes
  Stream<UserModel?> get authStateChanges {
    final auth = _auth;
    if (auth == null) {
      return _localAuthStream.stream;
    }
    return auth.authStateChanges().map((User? user) {
      if (user == null) return null;
      return UserModel(
        uid: user.uid,
        email: user.email,
        phoneNumber: user.phoneNumber,
        displayName: user.displayName,
        photoUrl: user.photoURL,
      );
    });
  }

  // Get current user
  UserModel? get currentUser {
    final auth = _auth;
    if (auth == null) return _localUser;
    final user = auth.currentUser;
    if (user == null) return null;
    return UserModel(
      uid: user.uid,
      email: user.email,
      phoneNumber: user.phoneNumber,
      displayName: user.displayName,
      photoUrl: user.photoURL,
    );
  }

  // Register with Email & Password
  Future<UserModel> registerWithEmailPassword({
    required String email,
    required String password,
    String? name,
  }) async {
    final auth = _auth;
    if (auth == null) {
      final cleanEmail = email.toLowerCase().trim();
      final users = await _getRegisteredUsers();
      if (users.containsKey(cleanEmail)) {
        throw 'This email is already registered. Please sign in instead.';
      }

      final uid = 'user_${DateTime.now().millisecondsSinceEpoch}';
      final displayName = (name != null && name.trim().isNotEmpty) ? name.trim() : email.split('@').first;
      await _saveRegisteredUserRecord(cleanEmail, password, displayName, uid);

      final user = UserModel(
        uid: uid,
        email: email.trim(),
        displayName: displayName,
      );
      _localUser = user;
      await _saveLocalUser(user);
      _localAuthStream.add(user);
      return user;
    }
    try {
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = userCredential.user!;
      if (name != null && name.isNotEmpty) {
        await user.updateDisplayName(name);
      }
      return UserModel(
        uid: user.uid,
        email: user.email,
        displayName: name ?? user.displayName,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign In with Email & Password
  Future<UserModel> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final auth = _auth;
    if (auth == null) {
      final cleanEmail = email.toLowerCase().trim();
      final users = await _getRegisteredUsers();
      if (!users.containsKey(cleanEmail)) {
        throw 'No account found with this email. Please register first.';
      }

      final record = users[cleanEmail]!;
      if (record['password'] != password) {
        throw 'Incorrect password. Please try again.';
      }

      final user = UserModel(
        uid: record['uid'] ?? 'user_${DateTime.now().millisecondsSinceEpoch}',
        email: record['email'],
        displayName: record['displayName'],
      );
      _localUser = user;
      await _saveLocalUser(user);
      _localAuthStream.add(user);
      return user;
    }
    try {
      final userCredential = await auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = userCredential.user!;
      return UserModel(
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Send OTP to Phone Number
  Future<void> sendOtpToPhone({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(FirebaseAuthException error) onVerificationFailed,
    required Function(PhoneAuthCredential credential) onVerificationCompleted,
    required Function(String verificationId) onCodeAutoRetrievalTimeout,
  }) async {
    final auth = _auth;
    if (auth == null) {
      _lastMockPhoneNumber = phoneNumber.trim();
      onCodeSent('mock_verification_id', 123456);
      return;
    }
    await auth.verifyPhoneNumber(
      phoneNumber: phoneNumber.trim(),
      verificationCompleted: onVerificationCompleted,
      verificationFailed: onVerificationFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout,
      timeout: const Duration(seconds: 60),
    );
  }

  // Verify OTP and Sign In
  Future<UserModel> verifyOtpAndSignIn({
    required String verificationId,
    required String smsCode,
  }) async {
    final auth = _auth;
    if (auth == null) {
      final phone = _lastMockPhoneNumber ?? '+919876543210';
      final user = UserModel(
        uid: 'phone_${DateTime.now().millisecondsSinceEpoch}',
        phoneNumber: phone,
        displayName: 'User $phone',
      );
      _localUser = user;
      await _saveLocalUser(user);
      _localAuthStream.add(user);
      return user;
    }
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );
      final userCredential = await auth.signInWithCredential(credential);
      final user = userCredential.user!;
      return UserModel(
        uid: user.uid,
        phoneNumber: user.phoneNumber,
        displayName: user.displayName,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign Out
  Future<void> signOut() async {
    final auth = _auth;
    if (auth != null) {
      await auth.signOut();
    }
    _localUser = null;
    await _saveLocalUser(null);
    _localAuthStream.add(null);
  }

  // Error Mapper
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email. Please register first.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'This email is already registered. Please sign in instead.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'weak-password':
        return 'The password is too weak. Please choose a stronger password.';
      case 'invalid-verification-code':
        return 'Invalid OTP entered. Please check and try again.';
      case 'session-expired':
        return 'OTP has expired. Please request a new code.';
      default:
        return e.message ?? 'An unexpected authentication error occurred.';
    }
  }
}
