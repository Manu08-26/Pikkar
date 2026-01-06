# 🚀 Pikkar API Integration - Complete Guide

## ✅ What's Been Integrated

Your Pikkar Flutter app now has a complete API client system integrated from the JavaScript API client. All API endpoints are now available in Dart/Flutter format.

## 📁 Files Created

### Core API Services
- `lib/core/services/api_client.dart` - Base HTTP client with interceptors
- `lib/core/services/auth_api_service.dart` - Authentication APIs
- `lib/core/services/vehicle_api_service.dart` - Vehicle & Parcel APIs
- `lib/core/services/ride_api_service.dart` - Ride booking & management
- `lib/core/services/driver_api_service.dart` - Driver APIs
- `lib/core/services/payment_api_service.dart` - Payment & Wallet APIs
- `lib/core/services/promo_api_service.dart` - Promo, Subscription & Referral APIs
- `lib/core/services/user_api_service.dart` - User profile & location APIs
- `lib/core/services/api_service.dart` - Main export file (use this!)
- `lib/core/services/integrated_auth_service.dart` - Combined Firebase + API auth

### Models & Documentation
- `lib/core/models/api_models.dart` - Type-safe data models
- `lib/API_INTEGRATION_GUIDE.md` - Detailed usage guide
- `lib/EXAMPLE_API_USAGE.dart` - Practical code examples
- `API_README.md` - This file

## 🎯 Quick Start

### 1. Configure API URL

Edit `lib/core/services/api_client.dart` line 19:

```dart
// Choose based on your environment:

// Local development
static const String _baseUrl = 'http://localhost:5001/api/v1';

// Android Emulator
static const String _baseUrl = 'http://10.0.2.2:5001/api/v1';

// Physical device (replace with your computer's IP)
static const String _baseUrl = 'http://192.168.1.100:5001/api/v1';

// Production
static const String _baseUrl = 'https://api.pikkar.com/api/v1';
```

### 2. Import in Your Code

```dart
import 'package:pikkar/core/services/api_service.dart';
```

### 3. Use the API

```dart
// Login example
try {
  final response = await PikkarApi.auth.login(
    email: 'user@example.com',
    password: 'password123',
  );
  
  // Save token
  await PikkarApi.saveToken(response['token']);
  await PikkarApi.saveUserData(response['user']);
  
  print('Welcome ${response['user']['name']}!');
} on ApiException catch (e) {
  print('Error: ${e.message}');
}
```

## 📚 Available API Services

### 🔐 Authentication (`PikkarApi.auth`)
- `login()` - Email/password login
- `signup()` - User registration
- `getProfile()` - Get user profile
- `updateProfile()` - Update profile
- `logout()` - Logout user
- `forgotPassword()` - Request password reset
- `resetPassword()` - Reset password with token

### 🚗 Vehicle Types (`PikkarApi.vehicleTypes`)
- `getActive()` - Get all active ride vehicles
- `calculateFare()` - Calculate ride fare

### 📦 Parcel Vehicles (`PikkarApi.parcelVehicles`)
- `getActive()` - Get all delivery vehicles
- `findSuitable()` - Find vehicles for parcel dimensions
- `calculatePrice()` - Calculate delivery price

### 🚕 Rides (`PikkarApi.rides`)
- `create()` - Book a new ride
- `getMyRides()` - Get user's rides
- `getById()` - Get ride details
- `cancel()` - Cancel a ride
- `rate()` - Rate completed ride
- `getStats()` - Get ride statistics

### 👨‍✈️ Drivers (`PikkarApi.driver`)
- `getNearby()` - Find nearby drivers
- `getById()` - Get driver details
- `apply()` - Apply to become driver
- `getStats()` - Get driver statistics

### 💳 Payments (`PikkarApi.payments`)
- `createIntent()` - Create payment intent
- `confirm()` - Confirm payment
- `getHistory()` - Get payment history
- `requestRefund()` - Request refund

### 💰 Wallet (`PikkarApi.wallet`)
- `getBalance()` - Get wallet balance
- `addMoney()` - Add money to wallet
- `getTransactions()` - Get transaction history
- `withdraw()` - Withdraw money (drivers)

### 🎟️ Promo Codes (`PikkarApi.promo`)
- `getAvailable()` - Get available promos
- `apply()` - Apply promo code
- `validate()` - Validate promo code

### 📱 Subscriptions (`PikkarApi.subscriptions`)
- `getPlans()` - Get subscription plans
- `getActive()` - Get active subscription
- `subscribe()` - Subscribe to plan
- `cancel()` - Cancel subscription
- `getStats()` - Get subscription stats

### 🎁 Referrals (`PikkarApi.referral`)
- `getCode()` - Get referral code
- `apply()` - Apply referral code
- `getStats()` - Get referral stats
- `getHistory()` - Get referral history

### 👤 User (`PikkarApi.user`)
- `updateLocation()` - Update user location
- `getById()` - Get user by ID
- `update()` - Update user profile
- `uploadPicture()` - Upload profile picture

## 🔄 Integration with Existing Firebase Auth

Your app currently uses Firebase for phone OTP authentication. You have two options:

### Option 1: Keep Firebase + Add API Auth (Recommended)

Use the `IntegratedAuthService` which combines both:

```dart
import 'package:pikkar/core/services/integrated_auth_service.dart';

final authService = IntegratedAuthService();

// For phone login (Firebase)
await authService.sendOtpFirebase(
  phone: '+919876543210',
  codeSent: (verificationId) {
    // Handle OTP sent
  },
  error: (error) {
    // Handle error
  },
);

// For email login (Backend API)
await authService.loginWithEmail(
  email: 'user@example.com',
  password: 'password',
);
```

### Option 2: Use Only API Auth

Replace Firebase auth with API auth in your login screen:

```dart
// Instead of Firebase OTP, use API login
final response = await PikkarApi.auth.login(
  email: email,
  password: password,
);
```

## 🎨 Example: Update Login Screen

Here's how to add API login to your existing login screen:

```dart
// In login_screen.dart

import 'package:pikkar/core/services/api_service.dart';

// Add email/password fields
final _emailController = TextEditingController();
final _passwordController = TextEditingController();

// Add login method
Future<void> _handleApiLogin() async {
  try {
    final response = await PikkarApi.auth.login(
      email: _emailController.text,
      password: _passwordController.text,
      role: 'user',
    );
    
    // Save token
    await PikkarApi.saveToken(response['token']);
    await PikkarApi.saveUserData(response['user']);
    
    // Navigate to home
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomeScreen()),
    );
  } on ApiException catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.message)),
    );
  }
}
```

## 🛠️ Testing the Integration

### 1. Start Your Backend Server

Make sure your Pikkar backend is running on the configured URL.

### 2. Test Authentication

```dart
// Test login
final response = await PikkarApi.auth.login(
  email: 'test@example.com',
  password: 'password123',
);
print('Token: ${response['token']}');
```

### 3. Test Vehicle Listing

```dart
// Test getting vehicles
final vehicles = await PikkarApi.vehicleTypes.getActive();
print('Found ${vehicles.length} vehicles');
```

### 4. Check Console Logs

The API client logs all requests and responses:
```
📡 API Request: GET /api/v1/vehicle-types/active
✅ API Response: 200 /api/v1/vehicle-types/active
```

## ⚠️ Error Handling

All API calls can throw `ApiException`:

```dart
try {
  final result = await PikkarApi.rides.create(...);
} on ApiException catch (e) {
  // Handle API errors
  print('Status: ${e.statusCode}');
  print('Message: ${e.message}');
  print('Data: ${e.data}');
  
  if (e.statusCode == 401) {
    // Unauthorized - redirect to login
  } else if (e.statusCode == 400) {
    // Bad request - show validation errors
  }
} on TimeoutException {
  // Handle timeout
  print('Request timed out');
} catch (e) {
  // Handle other errors
  print('Unexpected error: $e');
}
```

## 🔒 Security Notes

1. **Token Storage**: Tokens are stored securely using `shared_preferences`
2. **Auto Logout**: On 401 errors, tokens are automatically removed
3. **HTTPS**: Use HTTPS in production (`https://api.pikkar.com`)
4. **Token Expiry**: Implement token refresh if your backend supports it

## 📱 Platform-Specific Configuration

### Android
- Emulator: Use `http://10.0.2.2:5001/api/v1`
- Physical device: Use your computer's IP address

### iOS
- Simulator: Use `http://localhost:5001/api/v1`
- Physical device: Use your computer's IP address

### Finding Your IP Address
```bash
# macOS/Linux
ifconfig | grep "inet "

# Windows
ipconfig
```

## 🎯 Next Steps

1. ✅ Configure API base URL
2. ✅ Test authentication
3. ✅ Integrate with existing screens
4. ✅ Add error handling
5. ✅ Test all API endpoints
6. ✅ Add loading states
7. ✅ Implement state management (Provider/Riverpod/Bloc)
8. ✅ Add offline support (optional)

## 📖 Additional Resources

- **Detailed Guide**: See `lib/API_INTEGRATION_GUIDE.md`
- **Code Examples**: See `lib/EXAMPLE_API_USAGE.dart`
- **Data Models**: See `lib/core/models/api_models.dart`

## 🐛 Troubleshooting

### "Connection refused" error
- Check if backend server is running
- Verify the API URL is correct
- For Android emulator, use `10.0.2.2` instead of `localhost`

### "401 Unauthorized" error
- Token might be expired
- Try logging in again
- Check if token is being saved correctly

### "Timeout" error
- Check network connection
- Verify backend server is accessible
- Increase timeout in `api_client.dart` if needed

### "Certificate verification failed" (iOS)
- For development, you may need to add exception for local server
- In production, always use valid SSL certificates

## 💡 Tips

1. **Use try-catch**: Always wrap API calls in try-catch blocks
2. **Show loading**: Display loading indicators during API calls
3. **Cache data**: Consider caching frequently accessed data
4. **Retry logic**: Implement retry for failed requests
5. **State management**: Use Provider/Riverpod for managing API state

## 🎉 You're All Set!

Your Pikkar app now has full API integration. Start building amazing features! 🚀

For questions or issues, check the documentation files or review the example code.

Happy coding! 👨‍💻👩‍💻

