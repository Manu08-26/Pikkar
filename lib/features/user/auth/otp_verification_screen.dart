import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../home/home_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String phoneNumber;

  const OTPVerificationScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final AppTheme _appTheme = AppTheme();
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isVerifying = false;
  int _resendTimer = 30;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _appTheme.addListener(_onThemeChanged);
    _startResendTimer();
  }

  @override
  void dispose() {
    _appTheme.removeListener(_onThemeChanged);
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  void _startResendTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _resendTimer--;
          if (_resendTimer <= 0) {
            _canResend = true;
          } else {
            _startResendTimer();
          }
        });
      }
    });
  }

  void _handleOTPInput(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    // Auto verify when all fields are filled
    if (index == 5 && value.isNotEmpty) {
      _verifyOTP();
    }
  }

  void _verifyOTP() {
    String otp = _otpControllers.map((controller) => controller.text).join();
    
    if (otp.length != 6) {
      _showError('Please enter complete OTP');
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    // Simulate OTP verification
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
        // Navigate to home screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const HomeScreen(),
          ),
        );
      }
    });
  }

  void _resendOTP() {
    if (!_canResend) return;

    setState(() {
      _canResend = false;
      _resendTimer = 30;
    });
    _startResendTimer();
    _showSuccess('OTP resent successfully');
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _appTheme.brandRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _appTheme.textDirection,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              _appTheme.rtlEnabled ? Icons.arrow_forward : Icons.arrow_back,
              color: _appTheme.textColor,
              size: Responsive.iconSize(context, 24),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
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
                      SizedBox(height: Responsive.spacing(context, 20)),

                // Title
                Text(
                  'Enter OTP',
                  style: TextStyle(
                          fontSize: Responsive.fontSize(context, 32),
                    fontWeight: FontWeight.bold,
                    color: _appTheme.textColor,
                  ),
                ),
                      SizedBox(height: Responsive.spacing(context, 8)),

                // Description
                Text(
                  'We\'ve sent a 6-digit OTP to ${widget.phoneNumber}',
                  style: TextStyle(
                          fontSize: Responsive.fontSize(context, 14),
                    color: _appTheme.textGrey,
                  ),
                ),
                      SizedBox(height: Responsive.spacing(context, 40)),

                // OTP Input Fields
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final availableWidth = constraints.maxWidth;
                          final fieldWidth = Responsive.wp(context, 12.8); // ~48px on base
                          final totalFieldsWidth = fieldWidth * 6;
                          final spacingBetween = (availableWidth - totalFieldsWidth) / 5;
                          
                          return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) {
                    return SizedBox(
                                width: fieldWidth,
                                height: Responsive.hp(context, 6.9), // ~56px on base
                      child: TextField(
                        controller: _otpControllers[index],
                        focusNode: _focusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style: TextStyle(
                                    fontSize: Responsive.fontSize(context, 20),
                          fontWeight: FontWeight.bold,
                          color: _appTheme.textColor,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: _appTheme.iconBgColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _appTheme.dividerColor,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _appTheme.dividerColor,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _appTheme.brandRed,
                              width: 2,
                            ),
                          ),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (value) => _handleOTPInput(index, value),
                      ),
                    );
                  }),
                          );
                        },
                ),
                      SizedBox(height: Responsive.spacing(context, 32)),

                // Verify Button
                SizedBox(
                  width: double.infinity,
                        height: Responsive.hp(context, 6.9),
                  child: ElevatedButton(
                    onPressed: _isVerifying ? null : _verifyOTP,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _appTheme.brandRed,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: _appTheme.brandRed.withOpacity(0.6),
                    ),
                    child: _isVerifying
                        ? SizedBox(
                                  width: Responsive.iconSize(context, 24),
                                  height: Responsive.iconSize(context, 24),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Verify',
                            style: TextStyle(
                                    fontSize: Responsive.fontSize(context, 16),
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                      SizedBox(height: Responsive.spacing(context, 24)),

                // Resend OTP
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                            Flexible(
                              child: Text(
                        'Didn\'t receive OTP? ',
                        style: TextStyle(
                                  fontSize: Responsive.fontSize(context, 14),
                          color: _appTheme.textGrey,
                                ),
                        ),
                      ),
                      if (_canResend)
                        InkWell(
                          onTap: _resendOTP,
                          child: Text(
                            'Resend',
                            style: TextStyle(
                                    fontSize: Responsive.fontSize(context, 14),
                              fontWeight: FontWeight.w600,
                              color: _appTheme.brandRed,
                            ),
                          ),
                        )
                      else
                              Flexible(
                                child: Text(
                          'Resend in ${_resendTimer}s',
                          style: TextStyle(
                                    fontSize: Responsive.fontSize(context, 14),
                            color: _appTheme.textGrey,
                          ),
                                ),
                              ),
                          ],
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
}

