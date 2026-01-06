import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'otp_verification_screen.dart';
import '../home/home_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/responsive.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AppTheme _appTheme = AppTheme();
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  final AuthService _authService = AuthService();
  bool _isSendingOTP = false;

  @override
  void initState() {
    super.initState();
    _appTheme.addListener(_onThemeChanged);
    // Request location permission after splash screen
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      
      // Request permission if denied
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      // If denied forever, user needs to enable in settings
      if (permission == LocationPermission.deniedForever) {
        // Permission denied forever - user needs to enable in settings
        return;
      }
    } catch (e) {
      print('Error requesting location permission: $e');
    }
  }

  @override
  void dispose() {
    _appTheme.removeListener(_onThemeChanged);
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  Future<void> _handleContinue() async {
    // Validate phone number
    if (_phoneController.text.isEmpty || _phoneController.text.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid phone number'),
          backgroundColor: _appTheme.brandRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      return;
    }

    setState(() => _isSendingOTP = true);

    final phoneNumber = '+91${_phoneController.text}';

    try {
      // Send OTP via Firebase
      await _authService.sendOtp(
        phone: phoneNumber,
        codeSent: (String verificationId) {
          setState(() => _isSendingOTP = false);
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('OTP sent to $phoneNumber'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Navigate to OTP verification screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OTPVerificationScreen(
                phoneNumber: phoneNumber,
                verificationId: verificationId,
              ),
            ),
          );
        },
        error: (String errorMessage) {
          setState(() => _isSendingOTP = false);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to send OTP: $errorMessage'),
              backgroundColor: _appTheme.brandRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      );
    } catch (e) {
      setState(() => _isSendingOTP = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: _appTheme.brandRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Directionality(
      textDirection: _appTheme.textDirection,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: Responsive.padding(context, 24)),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
                  ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                      SizedBox(height: Responsive.hp(context, 7.4)),

                /// APP BRANDING
                Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/logo_red.png',
                              width: Responsive.wp(context, 40),
                              height: Responsive.hp(context, 7.4),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Text(
                            'PIKKAR',
                            style: TextStyle(
                                    fontSize: Responsive.fontSize(context, 42),
                              fontWeight: FontWeight.bold,
                              color: _appTheme.textColor,
                              letterSpacing: 1,
                            ),
                          );
                        },
                      ),
                            SizedBox(height: Responsive.spacing(context, 8)),
                    ],
                  ),
                ),

                      SizedBox(height: Responsive.hp(context, 7.4)),

                /// LOGIN SECTION
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Login',
                      style: TextStyle(
                              fontSize: Responsive.fontSize(context, 32),
                        fontWeight: FontWeight.bold,
                        color: _appTheme.textColor,
                      ),
                    ),
                          SizedBox(height: Responsive.spacing(context, 8)),
                    Text(
                      'Enter your phone number to continue',
                      style: TextStyle(
                              fontSize: Responsive.fontSize(context, 14),
                        color: _appTheme.textGrey,
                      ),
                    ),
                          SizedBox(height: Responsive.spacing(context, 32)),

                    /// PHONE NUMBER INPUT
                    Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: Responsive.padding(context, 16),
                              vertical: 4,
                            ),
                      decoration: BoxDecoration(
                        color: _appTheme.iconBgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _phoneFocusNode.hasFocus
                              ? _appTheme.brandRed
                              : _appTheme.dividerColor,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Country Code
                          Text(
                            '+91',
                            style: TextStyle(
                                    fontSize: Responsive.fontSize(context, 16),
                              color: _appTheme.textColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                                SizedBox(width: Responsive.spacing(context, 12)),
                          // Divider
                          Container(
                            width: 1,
                                  height: Responsive.spacing(context, 24),
                            color: _appTheme.dividerColor,
                          ),
                                SizedBox(width: Responsive.spacing(context, 12)),
                          // Phone Number Input
                          Expanded(
                            child: TextField(
                              controller: _phoneController,
                              focusNode: _phoneFocusNode,
                              keyboardType: TextInputType.phone,
                              style: TextStyle(
                                      fontSize: Responsive.fontSize(context, 16),
                                color: _appTheme.textColor,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Phone number',
                                hintStyle: TextStyle(
                                  color: _appTheme.textGrey,
                                        fontSize: Responsive.fontSize(context, 16),
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                      SizedBox(height: Responsive.spacing(context, 32)),

                /// CONTINUE BUTTON
                SizedBox(
                  width: double.infinity,
                        height: Responsive.hp(context, 6.9),
                  child: ElevatedButton(
                    onPressed: _isSendingOTP ? null : _handleContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _appTheme.brandRed,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSendingOTP
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: Responsive.fontSize(context, 16),
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),

                      SizedBox(height: Responsive.spacing(context, 32)),

                /// DIVIDER
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: _appTheme.dividerColor,
                        thickness: 1,
                      ),
                    ),
                    Padding(
                            padding: EdgeInsets.symmetric(horizontal: Responsive.spacing(context, 16)),
                      child: Text(
                        'or',
                        style: TextStyle(
                          color: _appTheme.textGrey,
                                fontSize: Responsive.fontSize(context, 14),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: _appTheme.dividerColor,
                        thickness: 1,
                      ),
                    ),
                  ],
                ),

                      SizedBox(height: Responsive.spacing(context, 24)),

                /// CONTINUE WITH GOOGLE BUTTON
                _socialButton(
                  icon: Icons.g_mobiledata,
                  label: 'Continue with Google',
                  onTap: () {
                    // For Google login, navigate directly to home
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HomeScreen(),
                      ),
                    );
                  },
                  isGoogle: true,
                ),

                      SizedBox(height: Responsive.spacing(context, 40)),

                /// TERMS & PRIVACY POLICY
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: Responsive.spacing(context, 16)),
                        child: Center(
                  child: Text(
                    'By continuing, you agree to our Terms & Privacy Policy',
                    style: TextStyle(
                              fontSize: Responsive.fontSize(context, 12),
                      color: _appTheme.textGrey,
                    ),
                    textAlign: TextAlign.center,
                          ),
                  ),
                ),

                      SizedBox(height: Responsive.spacing(context, 40)),
              ],
            ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _socialButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isGoogle,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.padding(context, 16),
          vertical: Responsive.padding(context, 16),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _appTheme.dividerColor,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isGoogle)
              // Google Logo
              Image.asset(
                'assets/google_logo.png',
                width: Responsive.iconSize(context, 24),
                height: Responsive.iconSize(context, 24),
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to icon if image not found
                  return Icon(
                    Icons.g_mobiledata,
                    color: _appTheme.textColor,
                    size: Responsive.iconSize(context, 24),
                  );
                },
              )
            else
              Icon(
                icon,
                color: _appTheme.textColor,
                size: Responsive.iconSize(context, 24),
              ),
            SizedBox(width: Responsive.spacing(context, 12)),
            Flexible(
              child: Text(
              label,
              style: TextStyle(
                  fontSize: Responsive.fontSize(context, 16),
                fontWeight: FontWeight.w500,
                color: _appTheme.textColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

