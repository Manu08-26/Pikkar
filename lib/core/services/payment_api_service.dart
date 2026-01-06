import 'api_client.dart';

/// Payments API Service
/// Handles payment-related API calls
class PaymentsApiService {
  final ApiClient _client = ApiClient();
  
  /// Create payment intent
  Future<Map<String, dynamic>> createIntent({
    required double amount,
    required String rideId,
    String paymentMethod = 'card',
  }) async {
    return await _client.post('/payments/create-intent', body: {
      'amount': amount,
      'rideId': rideId,
      'paymentMethod': paymentMethod,
    });
  }
  
  /// Confirm payment
  Future<Map<String, dynamic>> confirm(String paymentIntentId) async {
    return await _client.post('/payments/confirm', body: {
      'paymentIntentId': paymentIntentId,
    });
  }
  
  /// Get payment history
  Future<List<dynamic>> getHistory({
    int limit = 20,
    int skip = 0,
  }) async {
    return await _client.get('/payments/my-payments', queryParams: {
      'limit': limit.toString(),
      'skip': skip.toString(),
    });
  }
  
  /// Request refund
  Future<Map<String, dynamic>> requestRefund({
    required String paymentId,
    required String reason,
  }) async {
    return await _client.post('/payments/$paymentId/refund', body: {
      'reason': reason,
    });
  }
}

/// Wallet API Service
/// Handles wallet-related API calls
class WalletApiService {
  final ApiClient _client = ApiClient();
  
  /// Get wallet balance
  Future<Map<String, dynamic>> getBalance() async {
    return await _client.get('/wallet/balance');
  }
  
  /// Add money to wallet
  Future<Map<String, dynamic>> addMoney({
    required double amount,
    String paymentMethod = 'card',
  }) async {
    return await _client.post('/wallet/add-money', body: {
      'amount': amount,
      'paymentMethod': paymentMethod,
    });
  }
  
  /// Get wallet transactions
  Future<List<dynamic>> getTransactions({
    int limit = 20,
    int skip = 0,
  }) async {
    return await _client.get('/wallet/transactions', queryParams: {
      'limit': limit.toString(),
      'skip': skip.toString(),
    });
  }
  
  /// Withdraw money (for drivers)
  Future<Map<String, dynamic>> withdraw({
    required double amount,
    required Map<String, dynamic> bankAccount,
  }) async {
    return await _client.post('/wallet/withdraw', body: {
      'amount': amount,
      'bankAccount': bankAccount,
    });
  }
}

