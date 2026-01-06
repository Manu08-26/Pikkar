# 🚀 How to Run Pikkar App

## ✅ Firebase Error Fixed!

The app now runs properly on all platforms. The Firebase initialization error has been resolved.

## 🎯 Quick Start

### Option 1: Run on Android (Recommended)
```bash
# Launch Android emulator and run app
flutter emulators --launch Pixel_9_Pro
flutter run
```

### Option 2: Run on iOS Simulator
```bash
# Launch iOS simulator and run app
flutter emulators --launch apple_ios_simulator
flutter run
```

### Option 3: Run on Chrome (Limited - No Phone Auth)
```bash
flutter run -d chrome
```

## 📱 Available Devices

You have these devices available:
- ✅ **Pixel 9 Pro** (Android Emulator) - Full functionality
- ✅ **iOS Simulator** - Full functionality
- ✅ **Chrome** (Web) - Limited (no Firebase Phone Auth)
- ✅ **macOS** - Desktop app

## 🔧 What Was Fixed

Your app had a Firebase web configuration error. Here's what was fixed:

1. ✅ Made Firebase initialization conditional (only on mobile)
2. ✅ Web now skips Firebase and can use API backend
3. ✅ Added proper error handling
4. ✅ Added debug messages

## 💡 Recommendations

### For Testing & Development
**Use Android or iOS emulator** for the best experience:
```bash
# Android (Recommended)
flutter emulators --launch Pixel_9_Pro
flutter run

# iOS
flutter emulators --launch apple_ios_simulator  
flutter run
```

### For API Backend Testing
1. Configure API URL in `lib/core/services/api_client.dart`
2. For Android emulator, use: `http://10.0.2.2:5001/api/v1`
3. For iOS simulator, use: `http://localhost:5001/api/v1`

## 📋 Step-by-Step Instructions

### 1. Choose Your Platform
```bash
# See available devices
flutter devices

# See available emulators
flutter emulators
```

### 2. Launch Emulator (if needed)
```bash
# For Android
flutter emulators --launch Pixel_9_Pro

# For iOS
flutter emulators --launch apple_ios_simulator
```

### 3. Run the App
```bash
# Run on any available device
flutter run

# Or specify a device
flutter run -d android
flutter run -d ios
flutter run -d chrome
```

## ⚠️ Platform Limitations

| Platform | Phone OTP | Google Sign-In | API Backend |
|----------|-----------|----------------|-------------|
| Android | ✅ Yes | ✅ Yes | ✅ Yes |
| iOS | ✅ Yes | ✅ Yes | ✅ Yes |
| Web | ❌ No | ⚠️ Needs config | ✅ Yes |
| macOS | ❌ No | ❌ No | ✅ Yes |

## 🎯 Recommended Workflow

1. **Start Android Emulator**:
   ```bash
   flutter emulators --launch Pixel_9_Pro
   ```

2. **Wait for emulator to fully boot** (30-60 seconds)

3. **Run the app**:
   ```bash
   flutter run
   ```

4. **Test features**:
   - Phone OTP login
   - Google Sign-In
   - Location services
   - Ride booking

## 🐛 Troubleshooting

### If emulator doesn't start:
```bash
# Check emulator status
flutter doctor

# Try launching manually from Android Studio
```

### If app doesn't run:
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

### If Firebase errors persist:
- Use Android or iOS (not web)
- Check Firebase console for project setup
- Verify google-services.json (Android) is in place

## 📱 Quick Commands Reference

```bash
# List devices
flutter devices

# List emulators
flutter emulators

# Launch Android
flutter emulators --launch Pixel_9_Pro

# Launch iOS
flutter emulators --launch apple_ios_simulator

# Run app
flutter run

# Run on specific device
flutter run -d android
flutter run -d ios
flutter run -d chrome

# Hot reload (while app is running)
Press 'r'

# Hot restart (while app is running)
Press 'R'

# Quit
Press 'q'
```

## ✅ Your App is Ready!

The Firebase error has been fixed. Just run:

```bash
flutter emulators --launch Pixel_9_Pro
flutter run
```

And you're good to go! 🚀

---

**Need help?** Check:
- `PLATFORM_GUIDE.md` - Platform-specific information
- `API_README.md` - API integration guide
- `START_HERE.md` - API quick start

