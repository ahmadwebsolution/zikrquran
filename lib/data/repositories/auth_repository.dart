import 'package:firebase_auth/firebase_auth.dart';
import '../datasources/remote/firebase_auth_service.dart';
import '../models/user_model.dart';

class AuthRepository {
  final FirebaseAuthService _authService;

  AuthRepository({FirebaseAuthService? authService})
      : _authService = authService ?? FirebaseAuthService();

  Stream<UserModel?> get authStateChanges => _authService.authStateChanges;
  UserModel? get currentUser => _authService.currentUser;

  Future<UserModel> register(String email, String password, [String? name]) {
    return _authService.registerWithEmailPassword(
      email: email,
      password: password,
      name: name,
    );
  }

  Future<UserModel> login(String email, String password) {
    return _authService.signInWithEmailPassword(
      email: email,
      password: password,
    );
  }

  Future<void> sendOtp({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(FirebaseAuthException error) onVerificationFailed,
    required Function(PhoneAuthCredential credential) onVerificationCompleted,
    required Function(String verificationId) onCodeAutoRetrievalTimeout,
  }) {
    return _authService.sendOtpToPhone(
      phoneNumber: phoneNumber,
      onCodeSent: onCodeSent,
      onVerificationFailed: onVerificationFailed,
      onVerificationCompleted: onVerificationCompleted,
      onCodeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout,
    );
  }

  Future<UserModel> verifyOtp(String verificationId, String smsCode) {
    return _authService.verifyOtpAndSignIn(
      verificationId: verificationId,
      smsCode: smsCode,
    );
  }

  Future<void> logout() {
    return _authService.signOut();
  }
}
