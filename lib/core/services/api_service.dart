/// PIKKAR API Service
/// Main export file for all API services
/// 
/// Import this file to access all API services:
/// ```dart
/// import 'package:pikkar/core/services/api_service.dart';
/// 
/// // Example usage:
/// final response = await PikkarApi.auth.login(
///   email: 'user@example.com',
///   password: 'password',
/// );
/// ```

import 'api_client.dart';
import 'auth_api_service.dart';
import 'vehicle_api_service.dart';
import 'ride_api_service.dart';
import 'driver_api_service.dart';
import 'payment_api_service.dart';
import 'promo_api_service.dart';
import 'user_api_service.dart';

// Re-export for convenience
export 'api_client.dart';
export 'auth_api_service.dart';
export 'vehicle_api_service.dart';
export 'ride_api_service.dart';
export 'driver_api_service.dart';
export 'payment_api_service.dart';
export 'promo_api_service.dart';
export 'user_api_service.dart';

/// Main API Service Class
/// Provides access to all API services
class PikkarApi {
  // Singleton instance
  static final PikkarApi _instance = PikkarApi._internal();
  factory PikkarApi() => _instance;
  PikkarApi._internal();
  
  // API Services
  static final auth = AuthApiService();
  static final vehicleTypes = VehicleTypesApiService();
  static final parcelVehicles = ParcelVehiclesApiService();
  static final rides = RidesApiService();
  static final driver = DriverApiService();
  static final payments = PaymentsApiService();
  static final wallet = WalletApiService();
  static final promo = PromoApiService();
  static final subscriptions = SubscriptionsApiService();
  static final referral = ReferralApiService();
  static final user = UserApiService();
  
  // Token management helpers
  static Future<void> saveToken(String token) => ApiClient.saveToken(token);
  static Future<void> removeToken() => ApiClient.removeToken();
  static Future<void> saveUserData(Map<String, dynamic> userData) => 
      ApiClient.saveUserData(userData);
  static Future<Map<String, dynamic>?> getUserData() => ApiClient.getUserData();
}

