import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase only on mobile platforms (Android/iOS)
  // For web, we'll use the API backend instead
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();
      debugPrint('✅ Firebase initialized successfully');
    } catch (e) {
      debugPrint('⚠️ Firebase initialization failed: $e');
      // Continue without Firebase - API backend will handle authentication
    }
  } else {
    debugPrint('ℹ️ Running on Web - Skipping Firebase, using API backend');
    debugPrint('ℹ️ Phone OTP not available on web. Please test on Android/iOS.');
  }
  
  runApp(const RapidoApp());
}
