# Pikkar API Integration Guide

This guide explains how to use the integrated API services in your Flutter app.

## 📋 Table of Contents
- [Setup](#setup)
- [Configuration](#configuration)
- [Usage Examples](#usage-examples)
- [API Services](#api-services)
- [Error Handling](#error-handling)

## 🔧 Setup

### 1. Install Dependencies

The required dependencies are already added to `pubspec.yaml`:
- `http: ^1.1.0` - For HTTP requests
- `shared_preferences: ^2.2.2` - For token storage

Run:
```bash
flutter pub get
```

### 2. Import the API Service

```dart
import 'package:pikkar/core/services/api_service.dart';
```

## ⚙️ Configuration

### Update API Base URL

Edit `lib/core/services/api_client.dart` and change the base URL based on your environment:

```dart
// For Development (localhost)
static const String _baseUrl = 'http://localhost:5001/api/v1';

// For Android Emulator
static const String _baseUrl = 'http://10.0.2.2:5001/api/v1';

// For Physical Device (replace with your IP)
static const String _baseUrl = 'http://192.168.1.100:5001/api/v1';

// For Production
static const String _baseUrl = 'https://api.pikkar.com/api/v1';
```

## 📖 Usage Examples

### Authentication

#### Login
```dart
try {
  final response = await PikkarApi.auth.login(
    email: 'user@example.com',
    password: 'password123',
    role: 'user', // or 'driver'
  );
  
  // Save token
  await PikkarApi.saveToken(response['token']);
  await PikkarApi.saveUserData(response['user']);
  
  print('Login successful: ${response['user']['name']}');
} on ApiException catch (e) {
  print('Login failed: ${e.message}');
}
```

#### Signup
```dart
try {
  final response = await PikkarApi.auth.signup(
    name: 'John Doe',
    email: 'john@example.com',
    password: 'password123',
    phone: '+919876543210',
    referralCode: 'FRIEND123', // optional
  );
  
  await PikkarApi.saveToken(response['token']);
  await PikkarApi.saveUserData(response['user']);
  
  print('Signup successful!');
} on ApiException catch (e) {
  print('Signup failed: ${e.message}');
}
```

#### Get Profile
```dart
try {
  final user = await PikkarApi.auth.getProfile();
  print('User: ${user['name']} - ${user['email']}');
} on ApiException catch (e) {
  print('Error: ${e.message}');
}
```

#### Logout
```dart
try {
  await PikkarApi.auth.logout();
  print('Logged out successfully');
} on ApiException catch (e) {
  print('Logout error: ${e.message}');
}
```

### Vehicle Types

#### Get Active Vehicles
```dart
try {
  final vehicles = await PikkarApi.vehicleTypes.getActive();
  
  for (var vehicle in vehicles) {
    print('${vehicle['name']} - ₹${vehicle['baseFare']}');
  }
} on ApiException catch (e) {
  print('Error: ${e.message}');
}
```

#### Calculate Fare
```dart
try {
  final fareData = await PikkarApi.vehicleTypes.calculateFare(
    vehicleId: 'vehicle_123',
    distanceKm: 5.5,
    timeMinutes: 15,
  );
  
  print('Fare: ₹${fareData['fare']}');
  print('Breakdown: ${fareData['breakdown']}');
} on ApiException catch (e) {
  print('Error: ${e.message}');
}
```

### Rides

#### Create Ride
```dart
try {
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
    paymentMethod: 'cash', // or 'wallet', 'card'
    notes: 'Please call when you arrive',
    passengers: 2,
  );
  
  print('Ride created: ${ride['_id']}');
  print('Status: ${ride['status']}');
} on ApiException catch (e) {
  print('Error: ${e.message}');
}
```

#### Get My Rides
```dart
try {
  // Get all rides
  final allRides = await PikkarApi.rides.getMyRides();
  
  // Get rides by status
  final pendingRides = await PikkarApi.rides.getMyRides(status: 'pending');
  final completedRides = await PikkarApi.rides.getMyRides(status: 'completed');
  
  print('Total rides: ${allRides.length}');
} on ApiException catch (e) {
  print('Error: ${e.message}');
}
```

#### Cancel Ride
```dart
try {
  await PikkarApi.rides.cancel(
    rideId: 'ride_123',
    reason: 'Change of plans',
  );
  
  print('Ride cancelled');
} on ApiException catch (e) {
  print('Error: ${e.message}');
}
```

#### Rate Ride
```dart
try {
  await PikkarApi.rides.rate(
    rideId: 'ride_123',
    rating: 5,
    review: 'Excellent service!',
  );
  
  print('Ride rated successfully');
} on ApiException catch (e) {
  print('Error: ${e.message}');
}
```

### Drivers

#### Get Nearby Drivers
```dart
try {
  final drivers = await PikkarApi.driver.getNearby(
    latitude: 17.4065,
    longitude: 78.4772,
    radius: 5.0, // km
  );
  
  print('Found ${drivers.length} nearby drivers');
} on ApiException catch (e) {
  print('Error: ${e.message}');
}
```

### Payments & Wallet

#### Get Wallet Balance
```dart
try {
  final wallet = await PikkarApi.wallet.getBalance();
  print('Balance: ₹${wallet['balance']}');
} on ApiException catch (e) {
  print('Error: ${e.message}');
}
```

#### Add Money to Wallet
```dart
try {
  final result = await PikkarApi.wallet.addMoney(
    amount: 500.0,
    paymentMethod: 'card',
  );
  
  print('Money added: ₹${result['amount']}');
} on ApiException catch (e) {
  print('Error: ${e.message}');
}
```

#### Get Payment History
```dart
try {
  final payments = await PikkarApi.payments.getHistory(
    limit: 20,
    skip: 0,
  );
  
  print('Total payments: ${payments.length}');
} on ApiException catch (e) {
  print('Error: ${e.message}');
}
```

### Promo Codes

#### Get Available Promos
```dart
try {
  final promos = await PikkarApi.promo.getAvailable();
  
  for (var promo in promos) {
    print('${promo['code']} - ${promo['description']}');
  }
} on ApiException catch (e) {
  print('Error: ${e.message}');
}
```

#### Apply Promo Code
```dart
try {
  final result = await PikkarApi.promo.apply(
    code: 'FIRST50',
    amount: 200.0,
  );
  
  print('Discount: ₹${result['discount']}');
  print('Final amount: ₹${result['finalAmount']}');
} on ApiException catch (e) {
  print('Error: ${e.message}');
}
```

### User Location

#### Update Location
```dart
try {
  await PikkarApi.user.updateLocation(
    latitude: 17.4065,
    longitude: 78.4772,
  );
  
  print('Location updated');
} on ApiException catch (e) {
  print('Error: ${e.message}');
}
```

## 🔐 API Services

All available API services:

- **PikkarApi.auth** - Authentication (login, signup, profile)
- **PikkarApi.vehicleTypes** - Ride vehicles
- **PikkarApi.parcelVehicles** - Delivery vehicles
- **PikkarApi.rides** - Ride booking and management
- **PikkarApi.driver** - Driver information
- **PikkarApi.payments** - Payment processing
- **PikkarApi.wallet** - Wallet management
- **PikkarApi.promo** - Promo codes
- **PikkarApi.subscriptions** - Driver subscriptions
- **PikkarApi.referral** - Referral system
- **PikkarApi.user** - User profile and location

## ⚠️ Error Handling

All API calls can throw `ApiException`. Always wrap API calls in try-catch:

```dart
try {
  final result = await PikkarApi.auth.login(
    email: email,
    password: password,
  );
  // Handle success
} on ApiException catch (e) {
  // Handle API error
  print('Status Code: ${e.statusCode}');
  print('Message: ${e.message}');
  print('Data: ${e.data}');
} catch (e) {
  // Handle other errors (network, timeout, etc.)
  print('Unexpected error: $e');
}
```

### Common Error Status Codes
- **400** - Bad Request (validation error)
- **401** - Unauthorized (invalid/expired token)
- **404** - Not Found
- **500** - Server Error

## 📝 Notes

1. **Token Management**: The API client automatically adds the auth token to requests
2. **Auto Logout**: On 401 errors, the token is automatically removed
3. **Timeout**: API requests timeout after 15 seconds
4. **Logging**: All requests and responses are logged to console

## 🚀 Next Steps

1. Update the API base URL in `api_client.dart`
2. Test the API integration with your backend
3. Implement proper error handling in your UI
4. Add loading states during API calls
5. Consider using state management (Provider, Riverpod, Bloc) for API data

## 📞 Support

For issues or questions, check:
- Backend API documentation
- Flutter app logs
- Network inspector

