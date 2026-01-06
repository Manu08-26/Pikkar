import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'api_service.dart';

/// Integrated Auth Service
/// Combines Firebase Auth with Backend API Auth
/// 
/// This service allows you to:
/// 1. Use Firebase for phone authentication (OTP)
/// 2. Use Backend API for email/password authentication
/// 3. Sync user data between Firebase and Backend
class IntegratedAuthService {
  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  final AuthApiService _apiAuth = PikkarApi.auth;
  
  /// Current Firebase user
  firebase_auth.User? get currentFirebaseUser => _firebaseAuth.currentUser;
  
  /// Check if user is authenticated (either Firebase or API)
  Future<bool> isAuthenticated() async {
    // Check Firebase auth
    if (_firebaseAuth.currentUser != null) {
      return true;
    }
    
    // Check API auth (check if token exists)
    final userData = await PikkarApi.getUserData();
    return userData != null;
  }
  
  // ============================================
  // FIREBASE AUTH METHODS (Phone OTP)
  // ============================================
  
  /// Send OTP to phone number (Firebase)
  Future<void> sendOtpFirebase({
    required String phone,
    required Function(String) codeSent,
    required Function(String) error,
  }) async {
    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (firebase_auth.PhoneAuthCredential credential) async {
        await _firebaseAuth.signInWithCredential(credential);
      },
      verificationFailed: (firebase_auth.FirebaseAuthException e) {
        error(e.message ?? "Verification failed");
      },
      codeSent: (String verificationId, int? resendToken) {
        codeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }
  
  /// Verify OTP (Firebase)
  Future<firebase_auth.UserCredential> verifyOtpFirebase({
    required String verificationId,
    required String otp,
  }) async {
    final credential = firebase_auth.PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: otp,
    );
    return await _firebaseAuth.signInWithCredential(credential);
  }
  
  // ============================================
  // BACKEND API AUTH METHODS
  // ============================================
  
  /// Login with email and password (Backend API)
  Future<Map<String, dynamic>> loginWithEmail({
    required String email,
    required String password,
    String role = 'user',
  }) async {
    try {
      final response = await _apiAuth.login(
        email: email,
        password: password,
        role: role,
      );
      
      // Save token and user data
      if (response['token'] != null) {
        await PikkarApi.saveToken(response['token']);
      }
      if (response['user'] != null) {
        await PikkarApi.saveUserData(response['user']);
      }
      
      return response;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Signup with email and password (Backend API)
  Future<Map<String, dynamic>> signupWithEmail({
    required String name,
    required String email,
    required String password,
    required String phone,
    String? referralCode,
  }) async {
    try {
      final response = await _apiAuth.signup(
        name: name,
        email: email,
        password: password,
        phone: phone,
        referralCode: referralCode,
      );
      
      // Save token and user data
      if (response['token'] != null) {
        await PikkarApi.saveToken(response['token']);
      }
      if (response['user'] != null) {
        await PikkarApi.saveUserData(response['user']);
      }
      
      return response;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Get user profile (Backend API)
  Future<Map<String, dynamic>> getProfile() async {
    return await _apiAuth.getProfile();
  }
  
  /// Update user profile (Backend API)
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? email,
    String? phone,
  }) async {
    return await _apiAuth.updateProfile(
      name: name,
      email: email,
      phone: phone,
    );
  }
  
  /// Forgot password (Backend API)
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    return await _apiAuth.forgotPassword(email);
  }
  
  /// Reset password (Backend API)
  Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    return await _apiAuth.resetPassword(
      token: token,
      newPassword: newPassword,
    );
  }
  
  // ============================================
  // LOGOUT
  // ============================================
  
  /// Logout from both Firebase and Backend API
  Future<void> logout() async {
    // Logout from Firebase
    if (_firebaseAuth.currentUser != null) {
      await _firebaseAuth.signOut();
    }
    
    // Logout from Backend API
    try {
      await _apiAuth.logout();
    } catch (e) {
      // If API logout fails, still remove local token
      await PikkarApi.removeToken();
    }
  }
  
  // ============================================
  // USER DATA HELPERS
  // ============================================
  
  /// Get stored user data
  Future<Map<String, dynamic>?> getUserData() async {
    return await PikkarApi.getUserData();
  }
  
  /// Save user data
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    await PikkarApi.saveUserData(userData);
  }
}

