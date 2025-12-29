import 'package:flutter/material.dart';
import '../features/user/splash_screen.dart';
import '../features/user/location_permission_screen.dart';
import '../features/user/login_screen.dart';
import '../features/user/otp_verification_screen.dart';
import '../features/user/home_screen.dart';

class AppRoutes {
  // Initial route - Splash Screen
  static const String splash = '/';
  
  // Location Permission Screen
  static const String locationPermission = '/location-permission';
  
  // Login Screen
  static const String login = '/login';
  
  // OTP Verification Screen
  static const String otpVerification = '/otp-verification';
  
  // Home Screen
  static const String home = '/home';

  static Map<String, WidgetBuilder> routes = {
    splash: (_) => const SplashScreen(),
    locationPermission: (_) => const LocationPermissionScreen(),
    login: (_) => const LoginScreen(),
    otpVerification: (_) => OTPVerificationScreen(phoneNumber: ''),
    home: (_) => const HomeScreen(),
  };
}
