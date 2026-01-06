/// 🚀 QUICK API REFERENCE
/// Copy-paste ready code snippets for common API operations

import 'package:pikkar/core/services/api_service.dart';

// ============================================
// 🔐 AUTHENTICATION
// ============================================

// Login
Future<void> login() async {
  final response = await PikkarApi.auth.login(
    email: 'user@example.com',
    password: 'password123',
  );
  await PikkarApi.saveToken(response['token']);
  await PikkarApi.saveUserData(response['user']);
}

// Signup
Future<void> signup() async {
  final response = await PikkarApi.auth.signup(
    name: 'John Doe',
    email: 'john@example.com',
    password: 'password123',
    phone: '+919876543210',
  );
  await PikkarApi.saveToken(response['token']);
}

// Get Profile
Future<void> getProfile() async {
  final user = await PikkarApi.auth.getProfile();
  print(user['name']);
}

// Logout
Future<void> logout() async {
  await PikkarApi.auth.logout();
}

// ============================================
// 🚗 VEHICLES
// ============================================

// Get Active Vehicles
Future<void> getVehicles() async {
  final vehicles = await PikkarApi.vehicleTypes.getActive();
  for (var v in vehicles) {
    print('${v['name']} - ₹${v['baseFare']}');
  }
}

// Calculate Fare
Future<void> calculateFare() async {
  final fare = await PikkarApi.vehicleTypes.calculateFare(
    vehicleId: 'vehicle_123',
    distanceKm: 5.5,
    timeMinutes: 15,
  );
  print('Fare: ₹${fare['fare']}');
}

// ============================================
// 🚕 RIDES
// ============================================

// Book Ride
Future<void> bookRide() async {
  final ride = await PikkarApi.rides.create(
    vehicleType: 'vehicle_123',
    pickup: {
      'latitude': 17.4065,
      'longitude': 78.4772,
      'address': 'Charminar, Hyderabad',
    },
    dropoff: {
      'latitude': 17.4400,
      'longitude': 78.4983,
      'address': 'Hitech City, Hyderabad',
    },
    paymentMethod: 'cash',
    passengers: 2,
  );
  print('Ride ID: ${ride['_id']}');
}

// Get My Rides
Future<void> getMyRides() async {
  final rides = await PikkarApi.rides.getMyRides();
  print('Total rides: ${rides.length}');
}

// Get Pending Rides
Future<void> getPendingRides() async {
  final rides = await PikkarApi.rides.getMyRides(status: 'pending');
  print('Pending: ${rides.length}');
}

// Cancel Ride
Future<void> cancelRide() async {
  await PikkarApi.rides.cancel(
    rideId: 'ride_123',
    reason: 'Change of plans',
  );
}

// Rate Ride
Future<void> rateRide() async {
  await PikkarApi.rides.rate(
    rideId: 'ride_123',
    rating: 5,
    review: 'Excellent!',
  );
}

// ============================================
// 👨‍✈️ DRIVERS
// ============================================

// Get Nearby Drivers
Future<void> getNearbyDrivers() async {
  final drivers = await PikkarApi.driver.getNearby(
    latitude: 17.4065,
    longitude: 78.4772,
    radius: 5.0,
  );
  print('Found ${drivers.length} drivers');
}

// ============================================
// 💰 WALLET
// ============================================

// Get Balance
Future<void> getBalance() async {
  final wallet = await PikkarApi.wallet.getBalance();
  print('Balance: ₹${wallet['balance']}');
}

// Add Money
Future<void> addMoney() async {
  await PikkarApi.wallet.addMoney(
    amount: 500.0,
    paymentMethod: 'card',
  );
}

// Get Transactions
Future<void> getTransactions() async {
  final txns = await PikkarApi.wallet.getTransactions(limit: 10);
  print('Transactions: ${txns.length}');
}

// ============================================
// 🎟️ PROMO CODES
// ============================================

// Get Available Promos
Future<void> getPromos() async {
  final promos = await PikkarApi.promo.getAvailable();
  for (var p in promos) {
    print('${p['code']} - ${p['description']}');
  }
}

// Apply Promo
Future<void> applyPromo() async {
  final result = await PikkarApi.promo.apply(
    code: 'FIRST50',
    amount: 200.0,
  );
  print('Discount: ₹${result['discount']}');
}

// Validate Promo
Future<void> validatePromo() async {
  final result = await PikkarApi.promo.validate('FIRST50');
  print('Valid: ${result['valid']}');
}

// ============================================
// 📍 LOCATION
// ============================================

// Update Location
Future<void> updateLocation() async {
  await PikkarApi.user.updateLocation(
    latitude: 17.4065,
    longitude: 78.4772,
  );
}

// ============================================
// 💳 PAYMENTS
// ============================================

// Get Payment History
Future<void> getPayments() async {
  final payments = await PikkarApi.payments.getHistory(limit: 20);
  print('Payments: ${payments.length}');
}

// Create Payment Intent
Future<void> createPayment() async {
  final intent = await PikkarApi.payments.createIntent(
    amount: 250.0,
    rideId: 'ride_123',
    paymentMethod: 'card',
  );
  print('Intent ID: ${intent['id']}');
}

// ============================================
// 🎁 REFERRALS
// ============================================

// Get Referral Code
Future<void> getReferralCode() async {
  final result = await PikkarApi.referral.getCode();
  print('Your code: ${result['code']}');
}

// Apply Referral
Future<void> applyReferral() async {
  await PikkarApi.referral.apply('FRIEND123');
}

// Get Referral Stats
Future<void> getReferralStats() async {
  final stats = await PikkarApi.referral.getStats();
  print('Total referrals: ${stats['totalReferrals']}');
}

// ============================================
// 📦 PARCEL DELIVERY
// ============================================

// Get Parcel Vehicles
Future<void> getParcelVehicles() async {
  final vehicles = await PikkarApi.parcelVehicles.getActive();
  print('Delivery vehicles: ${vehicles.length}');
}

// Find Suitable Vehicle
Future<void> findSuitableVehicle() async {
  final vehicles = await PikkarApi.parcelVehicles.findSuitable(
    weightKg: 5.0,
    length: 30.0,
    width: 20.0,
    height: 15.0,
    distanceKm: 10.0,
  );
  print('Suitable vehicles: ${vehicles.length}');
}

// Calculate Delivery Price
Future<void> calculateDeliveryPrice() async {
  final price = await PikkarApi.parcelVehicles.calculatePrice(
    vehicleId: 'parcel_van_001',
    distanceKm: 10.0,
    weightKg: 5.0,
  );
  print('Price: ₹${price['price']}');
}

// ============================================
// 📊 STATISTICS
// ============================================

// Get Ride Stats
Future<void> getRideStats() async {
  final stats = await PikkarApi.rides.getStats();
  print('Total rides: ${stats['totalRides']}');
}

// Get Driver Stats (for drivers)
Future<void> getDriverStats() async {
  final stats = await PikkarApi.driver.getStats();
  print('Earnings: ₹${stats['totalEarnings']}');
}

// ============================================
// 🔄 ERROR HANDLING TEMPLATE
// ============================================

Future<void> apiCallWithErrorHandling() async {
  try {
    // Your API call here
    final result = await PikkarApi.auth.getProfile();
    print('Success: $result');
  } on ApiException catch (e) {
    // Handle API errors
    print('API Error: ${e.message}');
    print('Status Code: ${e.statusCode}');
    
    if (e.statusCode == 401) {
      // Unauthorized - redirect to login
      print('Please login again');
    } else if (e.statusCode == 400) {
      // Bad request
      print('Invalid request: ${e.data}');
    }
  } catch (e) {
    // Handle other errors
    print('Unexpected error: $e');
  }
}

// ============================================
// 🎨 WIDGET INTEGRATION TEMPLATE
// ============================================

/*
import 'package:flutter/material.dart';
import 'package:pikkar/core/services/api_service.dart';

class MyApiWidget extends StatefulWidget {
  const MyApiWidget({super.key});

  @override
  State<MyApiWidget> createState() => _MyApiWidgetState();
}

class _MyApiWidgetState extends State<MyApiWidget> {
  bool _isLoading = false;
  String? _error;
  dynamic _data;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Your API call
      final data = await PikkarApi.vehicleTypes.getActive();
      
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error'),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return ListView(
      children: [
        // Your UI here
        Text('Data: $_data'),
      ],
    );
  }
}
*/

