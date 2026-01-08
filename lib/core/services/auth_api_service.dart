import 'api_client.dart';

/// Auth API Service
/// Handles authentication-related API calls
class AuthApiService {
  final ApiClient _client = ApiClient();

  Map<String, dynamic> _normalizeAuthResponse(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      // New format: { status, message, data: { user, tokens: { accessToken, refreshToken } } }
      final data = raw['data'];
      if (data is Map<String, dynamic>) {
        final user = data['user'];
        final tokens = data['tokens'];
        final access = (tokens is Map<String, dynamic>) ? tokens['accessToken'] : null;
        final refresh = (tokens is Map<String, dynamic>) ? tokens['refreshToken'] : null;
        if (user is Map<String, dynamic> && access is String) {
          return {
            'user': user,
            'token': access,
            if (refresh is String) 'refreshToken': refresh,
            'raw': raw,
          };
        }
      }

      // Old/other format: { token, user, ... }
      final token = raw['token'];
      final user = raw['user'];
      if (token is String && user is Map<String, dynamic>) {
        return {
          'user': user,
          'token': token,
          if (raw['refreshToken'] is String) 'refreshToken': raw['refreshToken'],
          'raw': raw,
        };
      }
    }

    return {
      'raw': raw,
    };
  }
  
  /// Login user or driver
  /// @param email - User email
  /// @param password - User password
  /// @param role - 'user' or 'driver'
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    String role = 'user',
  }) async {
    final raw = await _client.post('/auth/login', body: {
      'email': email,
      'password': password,
      // Some backends still accept role; harmless if ignored.
      'role': role,
    });
    return _normalizeAuthResponse(raw);
  }

  /// Register new user/driver (API docs: POST /auth/register)
  Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    String role = 'user',
  }) async {
    final raw = await _client.post('/auth/register', body: {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'password': password,
      'role': role,
    });
    return _normalizeAuthResponse(raw);
  }

  /// Signup new user (legacy wrapper) -> maps to /auth/register
  Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String password,
    required String phone,
    String? referralCode,
    String role = 'user',
  }) async {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    final firstName = parts.isNotEmpty ? parts.first : name.trim();
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    // Prefer new endpoint
    try {
      final raw = await _client.post('/auth/register', body: {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': phone,
        'password': password,
        'role': role,
        if (referralCode != null) 'referralCode': referralCode,
      });
      return _normalizeAuthResponse(raw);
    } catch (_) {
      // Fallback to older endpoint if backend still uses it
      final raw = await _client.post('/auth/signup', body: {
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        if (referralCode != null) 'referralCode': referralCode,
        'role': role,
      });
      return _normalizeAuthResponse(raw);
    }
  }
  
  /// Get current user profile
  Future<Map<String, dynamic>> getProfile() async {
    final raw = await _client.get('/auth/me');
    if (raw is Map<String, dynamic>) {
      final data = raw['data'];
      if (data is Map<String, dynamic>) {
        final user = data['user'];
        if (user is Map<String, dynamic>) {
          return {'user': user, 'raw': raw};
        }
      }
      if (raw['user'] is Map<String, dynamic>) {
        return {'user': raw['user'], 'raw': raw};
      }
    }
    return {'raw': raw};
  }
  
  /// Update user profile
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? email,
    String? phone,
  }) async {
    // Not in the provided API doc, but keep for backward compatibility.
    return await _client.put('/auth/profile', body: {
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
    });
  }

  /// Refresh access token using refresh token (POST /auth/refresh-token)
  Future<Map<String, dynamic>> refreshToken({required String refreshToken}) async {
    final raw = await _client.post('/auth/refresh-token', body: {
      'refreshToken': refreshToken,
    });
    return _normalizeAuthResponse(raw);
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

