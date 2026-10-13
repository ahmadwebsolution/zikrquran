import 'package:flutter/material.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  // Phone Auth State
  String? _verificationId;
  int? _resendToken;
  bool _isCodeSent = false;

  AuthViewModel({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository() {
    _initAuth();
  }

  UserModel? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get verificationId => _verificationId;
  int? get resendToken => _resendToken;
  bool get isCodeSent => _isCodeSent;

  void _initAuth() {
    try {
      _user = _authRepository.currentUser;
      _authRepository.authStateChanges.listen((user) {
        _user = user;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Auth initialization note: $e');
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Register with Email
  Future<bool> register({
    required String email,
    required String password,
    String? name,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _user = await _authRepository.register(email, password, name);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  // Login with Email
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _user = await _authRepository.login(email, password);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  // Send OTP to Phone
  Future<void> sendOtp(String phoneNumber) async {
    _setLoading(true);
    _errorMessage = null;
    _isCodeSent = false;

    await _authRepository.sendOtp(
      phoneNumber: phoneNumber,
      onCodeSent: (verificationId, resendToken) {
        _verificationId = verificationId;
        _resendToken = resendToken;
        _isCodeSent = true;
        _setLoading(false);
      },
      onVerificationFailed: (error) {
        _errorMessage = error.message ?? 'Phone verification failed';
        _setLoading(false);
      },
      onVerificationCompleted: (credential) async {
        // Auto-resolution (on Android devices when SMS is read automatically)
        _setLoading(false);
      },
      onCodeAutoRetrievalTimeout: (verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  // Verify Phone OTP
  Future<bool> verifyOtp(String smsCode) async {
    if (_verificationId == null) {
      _errorMessage = 'No active verification session. Please resend OTP.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _errorMessage = null;
    try {
      _user = await _authRepository.verifyOtp(_verificationId!, smsCode);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  // Sign out
  Future<void> logout() async {
    _setLoading(true);
    await _authRepository.logout();
    _user = null;
    _setLoading(false);
  }
}
