import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class CancelRideReasonsScreen extends StatefulWidget {
  final Function(String) onCancelConfirmed;

  const CancelRideReasonsScreen({
    super.key,
    required this.onCancelConfirmed,
  });

  @override
  State<CancelRideReasonsScreen> createState() => _CancelRideReasonsScreenState();
}

class _CancelRideReasonsScreenState extends State<CancelRideReasonsScreen> {
  final AppTheme _appTheme = AppTheme();
  String? _selectedReason;

  final List<Map<String, String>> _cancelReasons = [
    {
      'title': 'Driver is taking too long',
      'icon': '⏱️',
    },
    {
      'title': 'I found another ride',
      'icon': '🚗',
    },
    {
      'title': 'Change of plans',
      'icon': '📅',
    },
    {
      'title': 'Wrong pickup location',
      'icon': '📍',
    },
    {
      'title': 'Driver asked to cancel',
      'icon': '👤',
    },
    {
      'title': 'Price is too high',
      'icon': '💰',
    },
    {
      'title': 'Other reason',
      'icon': '📝',
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

  void _handleCancelRide() {
    if (_selectedReason != null) {
      widget.onCancelConfirmed(_selectedReason!);
      // Don't pop here, let the parent handle it
    } else {
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
    }
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
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Why are you cancelling this ride?',
                      style: TextStyle(
                        fontSize: 20,
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
                              // Icon
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? _appTheme.brandRed
                                      : _appTheme.cardColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    reason['icon']!,
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Title
                              Expanded(
                                child: Text(
                                  reason['title']!,
                                  style: TextStyle(
                                   fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                                  ),
                                ),
                              ),
                              // Selection Indicator
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: _appTheme.brandRed,
                                  size: 24,
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

            // Cancel Ride Button
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
                    onPressed: _handleCancelRide,
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
    );
  }
}

