import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AppTheme _appTheme = AppTheme();

  @override
  void initState() {
    super.initState();
    _navigateToLogin();
  }

  void _navigateToLogin() {
    // Wait for 2-3 seconds then navigate to login screen
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const LoginScreen(),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final logoSize = Responsive.wp(context, 53.3); // ~200px on base design
    return Scaffold(
      backgroundColor: _appTheme.brandRed,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: _appTheme.brandRed,
          child: Center(
            child: Image.asset(
              'assets/logo.png',
              width: logoSize,
              height: logoSize,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Fallback to text if image not found
                return Text(
                  '',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 32),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

