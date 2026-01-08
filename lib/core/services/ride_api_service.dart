import 'api_client.dart';

/// Rides API Service
/// Handles ride booking and management API calls
class RidesApiService {
  final ApiClient _client = ApiClient();

  List<dynamic> _unwrapRidesList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map<String, dynamic>) {
      final data = raw['data'];
      if (data is Map<String, dynamic>) {
        final rides = data['rides'];
        if (rides is List) return rides;
      }
      final rides = raw['rides'];
      if (rides is List) return rides;
    }
    return const [];
  }

  Map<String, dynamic> _unwrapRide(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final data = raw['data'];
      if (data is Map<String, dynamic>) {
        final ride = data['ride'];
        if (ride is Map<String, dynamic>) return ride;
      }
      final ride = raw['ride'];
      if (ride is Map<String, dynamic>) return ride;
      return raw;
    }
    return <String, dynamic>{};
  }
  
  /// Create new ride booking
  /// @param data - { vehicleType, pickup, dropoff, ... }
  Future<Map<String, dynamic>> create({
    required String vehicleType,
    required Map<String, dynamic> pickup,
    required Map<String, dynamic> dropoff,
    String? paymentMethod,
    String? notes,
    int? passengers,
    DateTime? scheduledTime,
  }) async {
    // API docs body:
    // { pickupLocation: { coordinates: [lng, lat], address }, dropoffLocation: {...}, vehicleType, paymentMethod, scheduledTime }
    final pLat = (pickup['latitude'] ?? pickup['lat']);
    final pLng = (pickup['longitude'] ?? pickup['lng']);
    final dLat = (dropoff['latitude'] ?? dropoff['lat']);
    final dLng = (dropoff['longitude'] ?? dropoff['lng']);
    final pickupAddress = (pickup['address'] ?? pickup['name'] ?? '').toString();
    final dropoffAddress = (dropoff['address'] ?? dropoff['name'] ?? '').toString();

    final body = <String, dynamic>{
      'vehicleType': vehicleType,
      'pickupLocation': {
        if (pLng != null && pLat != null) 'coordinates': [pLng, pLat],
        'address': pickupAddress,
      },
      'dropoffLocation': {
        if (dLng != null && dLat != null) 'coordinates': [dLng, dLat],
        'address': dropoffAddress,
      },
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      if (scheduledTime != null) 'scheduledTime': scheduledTime.toIso8601String(),
      // Keep legacy keys too (some backends still accept these)
      'pickup': pickup,
      'dropoff': dropoff,
      if (notes != null) 'notes': notes,
      if (passengers != null) 'passengers': passengers,
    };

    final raw = await _client.post('/rides', body: body);
    return {'ride': _unwrapRide(raw), 'raw': raw};
  }
  
  /// Get rides list (API docs: GET /rides?page=1&limit=10&status=completed)
  Future<List<dynamic>> getAll({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    final raw = await _client.get('/rides', queryParams: {
      'page': page.toString(),
      'limit': limit.toString(),
      if (status != null) 'status': status,
    });
    return _unwrapRidesList(raw);
  }

  /// Get user's rides (legacy name)
  Future<List<dynamic>> getMyRides({String? status}) async {
    // Prefer new endpoint
    try {
      return await getAll(status: status);
    } catch (_) {
      // Fallback to older endpoint if backend still supports it
      final raw = await _client.get(
        '/rides/my-rides',
        queryParams: status != null ? {'status': status} : null,
      );
      return _unwrapRidesList(raw);
    }
  }
  
  /// Get ride details by ID
  Future<Map<String, dynamic>> getById(String rideId) async {
    final raw = await _client.get('/rides/$rideId');
    return _unwrapRide(raw);
  }
  
  /// Cancel ride
  Future<Map<String, dynamic>> cancel({
    required String rideId,
    String? reason,
  }) async {
    final raw = await _client.put('/rides/$rideId/cancel', body: {
      if (reason != null) 'reason': reason,
    });
    return {'ride': _unwrapRide(raw), 'raw': raw};
  }
  
  /// Rate completed ride
  Future<Map<String, dynamic>> rate({
    required String rideId,
    required int rating,
    String? review,
  }) async {
    // API docs: PUT /rides/:id/rate
    try {
      final raw = await _client.put('/rides/$rideId/rate', body: {
        'rating': rating,
        if (review != null) 'review': review,
      });
      return {'ride': _unwrapRide(raw), 'raw': raw};
    } catch (_) {
      // Fallback if backend still uses POST
      final raw = await _client.post('/rides/$rideId/rate', body: {
        'rating': rating,
        if (review != null) 'review': review,
      });
      return {'ride': _unwrapRide(raw), 'raw': raw};
    }
  }

  /// Accept ride request (Driver only) - PUT /rides/:id/accept
  Future<Map<String, dynamic>> accept({required String rideId}) async {
    final raw = await _client.put('/rides/$rideId/accept');
    return {'ride': _unwrapRide(raw), 'raw': raw};
  }

  /// Update ride status (Driver only) - PUT /rides/:id/status
  Future<Map<String, dynamic>> updateStatus({
    required String rideId,
    required String status,
  }) async {
    final raw = await _client.put('/rides/$rideId/status', body: {
      'status': status,
    });
    return {'ride': _unwrapRide(raw), 'raw': raw};
  }
  
  /// Get ride stats
  Future<Map<String, dynamic>> getStats() async {
    return await _client.get('/rides/stats');
  }
}

