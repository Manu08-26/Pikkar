import 'package:http/http.dart' as http;
import 'api_client.dart';

/// User API Service
/// Handles user-related API calls
class UserApiService {
  final ApiClient _client = ApiClient();
  
  /// Update user location (for real-time tracking)
  Future<Map<String, dynamic>> updateLocation({
    required double latitude,
    required double longitude,
  }) async {
    return await _client.put('/users/location', body: {
      'latitude': latitude,
      'longitude': longitude,
    });
  }
  
  /// Get user by ID
  Future<Map<String, dynamic>> getById(String userId) async {
    return await _client.get('/users/$userId');
  }
  
  /// Update user profile
  Future<Map<String, dynamic>> update({
    String? name,
    String? email,
    String? phone,
    String? address,
  }) async {
    return await _client.put('/users/profile', body: {
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
    });
  }
  
  /// Upload profile picture
  Future<Map<String, dynamic>> uploadPicture(String filePath) async {
    final file = await http.MultipartFile.fromPath('profile', filePath);
    
    return await _client.postMultipart(
      '/upload/profile',
      fields: {},
      files: [file],
    );
  }
}

