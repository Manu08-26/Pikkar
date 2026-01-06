import 'api_client.dart';

/// Auth API Service
/// Handles authentication-related API calls
class AuthApiService {
  final ApiClient _client = ApiClient();
  
  /// Login user or driver
  /// @param email - User email
  /// @param password - User password
  /// @param role - 'user' or 'driver'
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    String role = 'user',
  }) async {
    return await _client.post('/auth/login', body: {
      'email': email,
      'password': password,
      'role': role,
    });
  }
  
  /// Signup new user
  Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String password,
    required String phone,
    String? referralCode,
  }) async {
    return await _client.post('/auth/signup', body: {
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
      if (referralCode != null) 'referralCode': referralCode,
    });
  }
  
  /// Get current user profile
  Future<Map<String, dynamic>> getProfile() async {
    return await _client.get('/auth/me');
  }
  
  /// Update user profile
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? email,
    String? phone,
  }) async {
    return await _client.put('/auth/profile', body: {
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
    });
  }
  
  /// Logout
  Future<void> logout() async {
    await _client.post('/auth/logout');
    await ApiClient.removeToken();
  }
  
  /// Forgot password
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    return await _client.post('/auth/forgot-password', body: {
      'email': email,
    });
  }
  
  /// Reset password
  Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    return await _client.post('/auth/reset-password', body: {
      'token': token,
      'newPassword': newPassword,
    });
  }
}

