import 'package:flutter/material.dart';
import 'home_screen.dart';
import '../../core/theme/app_theme.dart';

class CancelRideScreen extends StatefulWidget {
  final String rideType;
  final String pickupLocation;
  final String dropLocation;

  const CancelRideScreen({
    super.key,
    required this.rideType,
    required this.pickupLocation,
    required this.dropLocation,
  });

  @override
  State<CancelRideScreen> createState() => _CancelRideScreenState();
}

class _CancelRideScreenState extends State<CancelRideScreen> {
  final AppTheme _appTheme = AppTheme();
  String? _selectedReason;

  final List<Map<String, String>> _cancelReasons = [
    {
      'title': 'Driver is taking too long',
      'description': 'The driver is delayed',
    },
    {
      'title': 'I booked by mistake',
      'description': 'I didn\'t mean to book this ride',
    },
    {
      'title': 'I found another ride',
      'description': 'I\'m using a different service',
    },
    {
      'title': 'Change in plans',
      'description': 'My plans have changed',
    },
    {
      'title': 'Driver is too far',
      'description': 'The driver is not nearby',
    },
    {
      'title': 'Other reason',
      'description': 'Something else',
    },
  ];

  @override
  void initState() {
    super.initState();
    _appTheme.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _appTheme.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  void _handleCancel() {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a reason for cancellation'),
          backgroundColor: _appTheme.brandRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      return;
    }

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Cancel Ride?',
          style: TextStyle(
            color: _appTheme.textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to cancel this ride?',
          style: TextStyle(
            color: _appTheme.textGrey,
            fontSize: 14,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'No',
              style: TextStyle(
                color: _appTheme.textGrey,
                fontSize: 16,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _confirmCancel();
            },
            child: Text(
              'Yes, Cancel',
              style: TextStyle(
                color: _appTheme.brandRed,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmCancel() {
    // Navigate back to home screen
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const HomeScreen(),
      ),
      (route) => false,
    );

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Ride cancelled successfully'),
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
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Cancel Ride',
            style: TextStyle(
              color: _appTheme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Text(
                        'Why are you cancelling?',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _appTheme.textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please select a reason to help us improve',
                        style: TextStyle(
                          fontSize: 14,
                          color: _appTheme.textGrey,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Cancel Reasons List
                      ..._cancelReasons.map((reason) {
                        final isSelected = _selectedReason == reason['title'];
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedReason = reason['title'];
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _appTheme.brandRed.withOpacity(0.1)
                                  : _appTheme.iconBgColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? _appTheme.brandRed
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Radio Button
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? _appTheme.brandRed
                                          : _appTheme.textGrey,
                                      width: 2,
                                    ),
                                  ),
                                  child: isSelected
                                      ? Center(
                                          child: Container(
                                            width: 12,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: _appTheme.brandRed,
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                // Reason Text
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        reason['title']!,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: _appTheme.textColor,
                                        ),
                                      ),
                                      if (reason['description'] != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          reason['description']!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: _appTheme.textGrey,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Cancel Button
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: _appTheme.dividerColor,
                      width: 1,
                    ),
                  ),
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleCancel,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _appTheme.brandRed,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Cancel Ride',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

