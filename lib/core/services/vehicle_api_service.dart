import 'api_client.dart';
import '../models/api_models.dart';

/// Vehicle Types API Service
/// Handles ride vehicle types API calls
class VehicleTypesApiService {
  final ApiClient _client = ApiClient();
  
  /// Get all active ride vehicle types
  /// Returns: Array of vehicles with pricing and capacity
  Future<List<VehicleType>> getActive() async {
    try {
      // Try /vehicle-types/active first, then fallback to /vehicle-types
      dynamic response;
      try {
        response = await _client.get('/vehicle-types/active');
      } catch (e) {
        response = await _client.get('/vehicle-types');
      }
      
      if (response is Map<String, dynamic>) {
        if (response.containsKey('data')) {
          final List<dynamic> data = response['data'] ?? [];
          return data.map((json) => VehicleType.fromJson(json as Map<String, dynamic>)).toList();
        }
      }
      
      if (response is List) {
        return response.map((json) => VehicleType.fromJson(json as Map<String, dynamic>)).toList();
      }
      
      return <VehicleType>[];
    } catch (e) {
      print('Error in getActive: $e');
      return <VehicleType>[];
    }
  }
  
  /// Calculate ride fare
  /// @param vehicleId - Vehicle type ID
  /// @param distanceKm - Distance in kilometers
  /// @param timeMinutes - Estimated time in minutes
  Future<Map<String, dynamic>> calculateFare({
    required String vehicleId,
    required double distanceKm,
    required int timeMinutes,
  }) async {
    return await _client.post('/vehicle-types/calculate-fare', body: {
      'vehicleId': vehicleId,
      'distanceKm': distanceKm,
      'timeMinutes': timeMinutes,
    });
  }
}

/// Parcel Vehicles API Service
/// Handles delivery vehicle API calls
class ParcelVehiclesApiService {
  final ApiClient _client = ApiClient();
  
  /// Get all active parcel delivery vehicles
  Future<List<dynamic>> getActive() async {
    try {
      final response = await _client.get('/parcel-vehicles/active');
      if (response is Map<String, dynamic> && response.containsKey('data')) {
        return response['data'] as List<dynamic>? ?? [];
      }
      if (response is List) return response;
      return [];
    } catch (e) {
      print('Error in ParcelVehicles.getActive: $e');
      return [];
    }
  }
  
  /// Find suitable vehicles for parcel dimensions
  /// @param weightKg - Parcel weight in kg
  /// @param length - Length in cm
  /// @param width - Width in cm
  /// @param height - Height in cm
  /// @param distanceKm - Delivery distance in km
  Future<List<dynamic>> findSuitable({
    required double weightKg,
    required double length,
    required double width,
    required double height,
    required double distanceKm,
  }) async {
    return await _client.get('/parcel-vehicles/find-suitable', queryParams: {
      'weightKg': weightKg.toString(),
      'length': length.toString(),
      'width': width.toString(),
      'height': height.toString(),
      'distanceKm': distanceKm.toString(),
    });
  }
  
  /// Calculate parcel delivery price
  /// @param vehicleId - Vehicle type ID
  /// @param distanceKm - Distance in kilometers
  /// @param weightKg - Parcel weight in kg
  /// @param dimensions - Optional: { length, width, height }
  Future<Map<String, dynamic>> calculatePrice({
    required String vehicleId,
    required double distanceKm,
    required double weightKg,
    double? length,
    double? width,
    double? height,
  }) async {
    return await _client.post('/parcel-vehicles/calculate-price', body: {
      'vehicleId': vehicleId,
      'distanceKm': distanceKm,
      'weightKg': weightKg,
      if (length != null) 'length': length,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
    });
  }
}

