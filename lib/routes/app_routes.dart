import 'package:flutter/material.dart';
import '../features/user/auth/splash_screen.dart';
import '../features/user/home/location_permission_screen.dart';
import '../features/user/auth/login_screen.dart';
import '../features/user/home/home_screen.dart';

class AppRoutes {
  // Initial route - Splash Screen
  static const String splash = '/';
  
  // Location Permission Screen
  static const String locationPermission = '/location-permission';
  
  // Login Screen
  static const String login = '/login';
  
  // Home Screen
  static const String home = '/home';

  static Map<String, WidgetBuilder> routes = {
    splash: (_) => const SplashScreen(),
    locationPermission: (_) => const LocationPermissionScreen(),
    login: (_) => const LoginScreen(),
    home: (_) => const HomeScreen(),
  };
}

// Note: OTP Verification Screen is accessed via Navigator.push from LoginScreen
// with dynamic parameters (phoneNumber and verificationId), so it's not included
// in static routes
