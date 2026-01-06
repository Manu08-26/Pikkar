import 'api_client.dart';

/// Driver API Service
/// Handles driver-related API calls
class DriverApiService {
  final ApiClient _client = ApiClient();
  
  /// Get nearby drivers
  /// @param latitude - User's latitude
  /// @param longitude - User's longitude
  /// @param radius - Radius in km (default: 5)
  Future<List<dynamic>> getNearby({
    required double latitude,
    required double longitude,
    double radius = 5.0,
  }) async {
    return await _client.get('/drivers/nearby', queryParams: {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'radius': radius.toString(),
    });
  }
  
  /// Get driver details
  Future<Map<String, dynamic>> getById(String driverId) async {
    return await _client.get('/drivers/$driverId');
  }
  
  /// Apply to become a driver
  Future<Map<String, dynamic>> apply({
    required String name,
    required String email,
    required String phone,
    required String licenseNumber,
    required String vehicleType,
    required String vehicleNumber,
    String? vehicleModel,
    String? vehicleColor,
  }) async {
    return await _client.post('/drivers/apply', body: {
      'name': name,
      'email': email,
      'phone': phone,
      'licenseNumber': licenseNumber,
      'vehicleType': vehicleType,
      'vehicleNumber': vehicleNumber,
      if (vehicleModel != null) 'vehicleModel': vehicleModel,
      if (vehicleColor != null) 'vehicleColor': vehicleColor,
    });
  }
  
  /// Get driver stats (for driver app)
  Future<Map<String, dynamic>> getStats() async {
    return await _client.get('/drivers/stats');
  }
}

