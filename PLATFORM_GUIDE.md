# 📱 Platform Guide - Running Pikkar App

## ✅ Issue Fixed!

The Firebase web configuration error has been resolved. Your app now:
- ✅ Runs on **Android** with Firebase Phone Auth
- ✅ Runs on **iOS** with Firebase Phone Auth  
- ✅ Runs on **Web** without Firebase (uses API backend)

## 🚀 How to Run

### For Android (Recommended for Testing)
```bash
flutter run -d android
```

### For iOS
```bash
flutter run -d ios
```

### For Web (Limited - No Phone OTP)
```bash
flutter run -d chrome
```

**Note:** Phone OTP authentication (Firebase) is not available on web. For full functionality, use Android or iOS.

## 🔧 Platform-Specific Features

### Android & iOS
✅ Firebase Phone Authentication (OTP)  
✅ Google Sign-In  
✅ All features fully functional  
✅ Push notifications  
✅ Location services  

### Web
⚠️ Firebase Phone Auth not configured  
✅ API Backend integration available  
✅ Can add email/password login (API)  
⚠️ Limited for testing purposes  

## 💡 Recommendation for Development

1. **Primary Testing**: Use Android Emulator or iOS Simulator
2. **API Testing**: Configure API backend and test on Android/iOS
3. **Web Support**: Add email/password authentication using the API backend

## 🛠️ To Add Full Web Support

If you need phone authentication on web, you have two options:

### Option 1: Configure Firebase for Web

1. Install FlutterFire CLI:
```bash
dart pub global activate flutterfire_cli
```

2. Configure Firebase:
```bash
flutterfire configure
```

3. Select web platform when prompted

### Option 2: Use API Backend (Recommended)

Use the API backend with email/password authentication:

```dart
import 'package:pikkar/core/services/api_service.dart';

// Login with email (works on all platforms including web)
final response = await PikkarApi.auth.login(
  email: 'user@example.com',
  password: 'password123',
);
await PikkarApi.saveToken(response['token']);
```

## 📱 Quick Test Commands

```bash
# List available devices
flutter devices

# Run on Android
flutter run -d android

# Run on iOS
flutter run -d ios

# Run on Chrome (Web)
flutter run -d chrome

# Run on specific device
flutter run -d <device-id>
```

## ✅ Current Status

| Platform | Status | Authentication Method |
|----------|--------|----------------------|
| Android | ✅ Working | Firebase Phone OTP |
| iOS | ✅ Working | Firebase Phone OTP |
| Web | ⚠️ Limited | API Backend (to be configured) |

## 🎯 Next Steps

1. **Run on Android/iOS** for full functionality
2. **Configure API backend** URL in `api_client.dart`
3. **Test API integration** on mobile platforms
4. **(Optional)** Add web support with Firebase configuration

## 📞 Need Help?

- **API Integration**: See `API_README.md`
- **Firebase Setup**: See Firebase documentation
- **Platform Issues**: Check Flutter documentation

---

**Your app is now ready to run on Android and iOS!** 🚀

