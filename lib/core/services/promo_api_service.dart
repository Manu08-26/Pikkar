import 'api_client.dart';

/// Promo Codes API Service
/// Handles promo code-related API calls
class PromoApiService {
  final ApiClient _client = ApiClient();
  
  /// Get available promo codes
  Future<List<dynamic>> getAvailable() async {
    return await _client.get('/promo/available');
  }
  
  /// Apply promo code
  Future<Map<String, dynamic>> apply({
    required String code,
    required double amount,
  }) async {
    return await _client.post('/promo/apply', body: {
      'code': code,
      'amount': amount,
    });
  }
  
  /// Validate promo code
  Future<Map<String, dynamic>> validate(String code) async {
    return await _client.post('/promo/validate', body: {
      'code': code,
    });
  }
}

/// Subscriptions API Service (for Drivers)
/// Handles subscription-related API calls
class SubscriptionsApiService {
  final ApiClient _client = ApiClient();
  
  /// Get subscription plans
  Future<List<dynamic>> getPlans() async {
    return await _client.get('/subscriptions/plans');
  }
  
  /// Get active subscription
  Future<Map<String, dynamic>> getActive() async {
    return await _client.get('/subscriptions/active');
  }
  
  /// Subscribe to plan
  Future<Map<String, dynamic>> subscribe({
    required String planId,
    String paymentMethod = 'card',
  }) async {
    return await _client.post('/subscriptions/subscribe', body: {
      'planId': planId,
      'paymentMethod': paymentMethod,
    });
  }
  
  /// Cancel subscription
  Future<Map<String, dynamic>> cancel({String? reason}) async {
    return await _client.post('/subscriptions/cancel', body: {
      if (reason != null) 'reason': reason,
    });
  }
  
  /// Get subscription stats
  Future<Map<String, dynamic>> getStats() async {
    return await _client.get('/subscriptions/stats');
  }
}

/// Referral API Service
/// Handles referral-related API calls
class ReferralApiService {
  final ApiClient _client = ApiClient();
  
  /// Get referral code
  Future<Map<String, dynamic>> getCode() async {
    return await _client.get('/referral/my-code');
  }
  
  /// Apply referral code
  Future<Map<String, dynamic>> apply(String code) async {
    return await _client.post('/referral/apply', body: {
      'code': code,
    });
  }
  
  /// Get referral stats
  Future<Map<String, dynamic>> getStats() async {
    return await _client.get('/referral/stats');
  }
  
  /// Get referral history
  Future<List<dynamic>> getHistory() async {
    return await _client.get('/referral/history');
  }
}

