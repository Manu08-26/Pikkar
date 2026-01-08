import 'api_client.dart';

/// Driver API Service
/// Handles driver-related API calls
class DriverApiService {
  final ApiClient _client = ApiClient();

  List<dynamic> _unwrapDriversList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map<String, dynamic>) {
      final data = raw['data'];
      if (data is Map<String, dynamic>) {
        final drivers = data['drivers'];
        if (drivers is List) return drivers;
      }
      final drivers = raw['drivers'];
      if (drivers is List) return drivers;
    }
    return const [];
  }
  
  /// Get nearby drivers
  /// @param latitude - User's latitude
  /// @param longitude - User's longitude
  /// @param radius - Radius in km (legacy) (default: 5)
  Future<List<dynamic>> getNearby({
    required double latitude,
    required double longitude,
    double radius = 5.0,
    int? maxDistance, // meters (API docs)
    String? vehicleType,
  }) async {
    final raw = await _client.get('/drivers/nearby', queryParams: {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      // New API uses maxDistance in meters
      'maxDistance': (maxDistance ?? (radius * 1000).round()).toString(),
      if (vehicleType != null) 'vehicleType': vehicleType,
      // Keep legacy param too (harmless if ignored)
      'radius': radius.toString(),
    });
    return _unwrapDriversList(raw);
  }
  
  /// Get driver details
  Future<Map<String, dynamic>> getById(String driverId) async {
    return await _client.get('/drivers/$driverId');
  }
  
  /// Register as a driver (API docs: POST /drivers/register)
  Future<Map<String, dynamic>> register({
    required String licenseNumber,
    required String licenseExpiry, // ISO date or yyyy-mm-dd
    required String vehicleType,
    required String vehicleModel,
    required String vehicleMake,
    required int vehicleYear,
    required String vehicleColor,
    required String vehicleNumber,
  }) async {
    return await _client.post('/drivers/register', body: {
      'licenseNumber': licenseNumber,
      'licenseExpiry': licenseExpiry,
      'vehicleType': vehicleType,
      'vehicleModel': vehicleModel,
      'vehicleMake': vehicleMake,
      'vehicleYear': vehicleYear,
      'vehicleColor': vehicleColor,
      'vehicleNumber': vehicleNumber,
    });
  }

  /// Update driver location (Driver only) - PUT /drivers/location
  Future<Map<String, dynamic>> updateLocation({
    required double longitude,
    required double latitude,
  }) async {
    return await _client.put('/drivers/location', body: {
      'longitude': longitude,
      'latitude': latitude,
    });
  }

  /// Toggle online/offline (Driver only) - PUT /drivers/toggle-online
  Future<Map<String, dynamic>> toggleOnline() async {
    return await _client.put('/drivers/toggle-online');
  }

  /// Apply to become a driver (legacy) -> maps to register when possible
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
    try {
      return await register(
        licenseNumber: licenseNumber,
        licenseExpiry: DateTime.now().add(const Duration(days: 365)).toIso8601String(),
        vehicleType: vehicleType,
        vehicleModel: vehicleModel ?? '',
        vehicleMake: '',
        vehicleYear: DateTime.now().year,
        vehicleColor: vehicleColor ?? '',
        vehicleNumber: vehicleNumber,
      );
    } catch (_) {
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
  }
  
  /// Get driver stats (for driver app)
  Future<Map<String, dynamic>> getStats() async {
    return await _client.get('/drivers/stats');
  }
}

