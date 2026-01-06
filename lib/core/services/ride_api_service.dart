import 'api_client.dart';

/// Rides API Service
/// Handles ride booking and management API calls
class RidesApiService {
  final ApiClient _client = ApiClient();
  
  /// Create new ride booking
  /// @param data - { vehicleType, pickup, dropoff, ... }
  Future<Map<String, dynamic>> create({
    required String vehicleType,
    required Map<String, dynamic> pickup,
    required Map<String, dynamic> dropoff,
    String? paymentMethod,
    String? notes,
    int? passengers,
  }) async {
    return await _client.post('/rides', body: {
      'vehicleType': vehicleType,
      'pickup': pickup,
      'dropoff': dropoff,
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      if (notes != null) 'notes': notes,
      if (passengers != null) 'passengers': passengers,
    });
  }
  
  /// Get user's rides
  /// @param status - Optional: 'pending', 'accepted', 'completed', etc.
  Future<List<dynamic>> getMyRides({String? status}) async {
    return await _client.get(
      '/rides/my-rides',
      queryParams: status != null ? {'status': status} : null,
    );
  }
  
  /// Get ride details by ID
  Future<Map<String, dynamic>> getById(String rideId) async {
    return await _client.get('/rides/$rideId');
  }
  
  /// Cancel ride
  Future<Map<String, dynamic>> cancel({
    required String rideId,
    String? reason,
  }) async {
    return await _client.put('/rides/$rideId/cancel', body: {
      if (reason != null) 'reason': reason,
    });
  }
  
  /// Rate completed ride
  Future<Map<String, dynamic>> rate({
    required String rideId,
    required int rating,
    String? review,
  }) async {
    return await _client.post('/rides/$rideId/rate', body: {
      'rating': rating,
      if (review != null) 'review': review,
    });
  }
  
  /// Get ride stats
  Future<Map<String, dynamic>> getStats() async {
    return await _client.get('/rides/stats');
  }
}

