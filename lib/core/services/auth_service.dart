import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  late final FirebaseAuth _auth;

  AuthService() {
    // On web we don't use Firebase phone OTP in this app.
    if (!kIsWeb) {
      _auth = FirebaseAuth.instance;
    }
  }

  Future<void> sendOtp({
    required String phone,
    required Function(String) codeSent,
    required Function(String) error,
  }) async {
    if (kIsWeb) {
      error('Phone OTP is not available on Web. Please test on Android/iOS.');
      return;
    }
    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        error(e.message ?? "Verification failed");
      },
      codeSent: (String verificationId, int? resendToken) {
        codeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  Future<UserCredential> verifyOtp({
    required String verificationId,
    required String otp,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('Phone OTP is not available on Web.');
    }
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: otp,
    );
    return await _auth.signInWithCredential(credential);
  }

  User? get currentUser => kIsWeb ? null : _auth.currentUser;
}
