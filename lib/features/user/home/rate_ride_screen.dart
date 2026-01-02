import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class RateRideScreen extends StatefulWidget {
  final String pickupLocation;
  final String dropLocation;
  final String rideType;
  final Map<String, dynamic> rideDetails;

  const RateRideScreen({
    super.key,
    required this.pickupLocation,
    required this.dropLocation,
    required this.rideType,
    required this.rideDetails,
  });

  @override
  State<RateRideScreen> createState() => _RateRideScreenState();
}

class _RateRideScreenState extends State<RateRideScreen> {
  final AppTheme _appTheme = AppTheme();
  int _selectedRating = 0;
  final TextEditingController _feedbackController = TextEditingController();
  final List<String> _selectedReasons = [];
  int _tipAmount = 0;

  final List<Map<String, dynamic>> _ratingReasons = [
    {'rating': 5, 'reasons': ['Friendly driver', 'Clean vehicle', 'Smooth ride', 'On time', 'Safe driving']},
    {'rating': 4, 'reasons': ['Good service', 'Polite driver', 'Comfortable ride']},
    {'rating': 3, 'reasons': ['Average experience', 'Could be better', 'Long wait time']},
    {'rating': 2, 'reasons': ['Rude behavior', 'Unsafe driving', 'Dirty vehicle', 'Took wrong route']},
    {'rating': 1, 'reasons': ['Very rude', 'Dangerous driving', 'Demanded extra money', 'Refused to go']},
  ];

  final List<int> _tipOptions = [0, 10, 20, 30, 50];

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  List<String> _getReasonsForRating(int rating) {
    final reasonData = _ratingReasons.firstWhere(
      (r) => r['rating'] == rating,
      orElse: () => {'reasons': []},
    );
    return List<String>.from(reasonData['reasons'] ?? []);
  }

  void _submitRating() {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a rating'),
          backgroundColor: _appTheme.brandRed,
        ),
      );
      return;
    }

    // Show success message
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: _appTheme.brandRed,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              'Thank You!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _appTheme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your feedback helps us improve',
              style: TextStyle(
                fontSize: 14,
                color: _appTheme.textGrey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

    // Navigate to home after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).popUntil((route) => route.isFirst);
    });
  }

  @override
  Widget build(BuildContext context) {
    final reasons = _selectedRating > 0 ? _getReasonsForRating(_selectedRating) : [];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: _appTheme.textColor),
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
        title: Text(
          'Rate your ride',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _appTheme.textColor,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Driver Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: const AssetImage('assets/images/driver_placeholder.png'),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sri Akshay',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: _appTheme.textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.rideDetails['vehicleNumber'] ?? 'TS02E1655',
                            style: TextStyle(
                              fontSize: 14,
                              color: _appTheme.textGrey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.rideDetails['vehicleModel'] ?? 'Hero Honda',
                            style: TextStyle(
                              fontSize: 13,
                              color: _appTheme.textGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Rating Stars
              Center(
                child: Column(
                  children: [
                    Text(
                      'How was your ride?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _appTheme.textColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starRating = index + 1;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedRating = starRating;
                              _selectedReasons.clear();
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(
                              _selectedRating >= starRating ? Icons.star : Icons.star_border,
                              size: 48,
                              color: _selectedRating >= starRating
                                  ? _appTheme.brandRed
                                  : Colors.grey.shade400,
                            ),
                          ),
                        );
                      }),
                    ),
                    if (_selectedRating > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        _getRatingText(_selectedRating),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: _appTheme.textGrey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Reasons (if rating is selected)
              if (_selectedRating > 0 && reasons.isNotEmpty) ...[
                const SizedBox(height: 32),
                Text(
                  'What went well?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _appTheme.textColor,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: reasons.map((reason) {
                    final isSelected = _selectedReasons.contains(reason);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedReasons.remove(reason);
                          } else {
                            _selectedReasons.add(reason);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? _appTheme.brandRed.withOpacity(0.1) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? _appTheme.brandRed : Colors.grey.shade300,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Text(
                          reason,
                          style: TextStyle(
                            fontSize: 14,
                            color: isSelected ? _appTheme.brandRed : _appTheme.textColor,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              // Additional Feedback
              if (_selectedRating > 0) ...[
                const SizedBox(height: 24),
                Text(
                  'Additional Feedback (Optional)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _appTheme.textColor,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _feedbackController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Share more details about your experience...',
                    hintStyle: TextStyle(color: _appTheme.textGrey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _appTheme.brandRed),
                    ),
                  ),
                ),
              ],

              // Tip Section (only for good ratings)
              if (_selectedRating >= 4) ...[
                const SizedBox(height: 24),
                Text(
                  'Add a tip for your driver',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _appTheme.textColor,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: _tipOptions.map((tip) {
                    final isSelected = _tipAmount == tip;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _tipAmount = tip;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? _appTheme.brandRed : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? _appTheme.brandRed : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Text(
                            tip == 0 ? 'No tip' : '₹$tip',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : _appTheme.textColor,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 40),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _selectedRating > 0 ? _submitRating : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _appTheme.brandRed,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Submit Rating',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _selectedRating > 0 ? Colors.white : Colors.grey.shade500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 5:
        return 'Excellent!';
      case 4:
        return 'Good';
      case 3:
        return 'Average';
      case 2:
        return 'Below Average';
      case 1:
        return 'Poor';
      default:
        return '';
    }
  }
}

