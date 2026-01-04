import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class RateRidesScreen extends StatefulWidget {
  const RateRidesScreen({super.key});

  @override
  State<RateRidesScreen> createState() => _RateRidesScreenState();
}

class _RateRidesScreenState extends State<RateRidesScreen> {
  final AppTheme _appTheme = AppTheme();

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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _appTheme.textDirection,
      child: Scaffold(
        backgroundColor: _appTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: _appTheme.cardColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              _appTheme.rtlEnabled ? Icons.arrow_forward : Icons.arrow_back,
              color: _appTheme.textColor,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Rate Your Rides',
            style: TextStyle(
              color: _appTheme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Past Rides List
            _buildRideCard(
              driverName: 'Rajesh Kumar',
              vehicleType: 'Bike',
              date: '15 Dec 2024',
              time: '10:30 AM',
              from: 'Lulu Mall, Kondapur',
              to: 'Hotel Grand Sitara, Banjara Hills',
              amount: '₹65',
              rating: 0,
            ),
            const SizedBox(height: 16),
            _buildRideCard(
              driverName: 'Suresh Reddy',
              vehicleType: 'Auto',
              date: '14 Dec 2024',
              time: '2:15 PM',
              from: 'GVK Mall, Banjara Hills',
              to: 'Metro Convention, Hyderabad',
              amount: '₹90',
              rating: 5,
            ),
            const SizedBox(height: 16),
            _buildRideCard(
              driverName: 'Mahesh Singh',
              vehicleType: 'Cab',
              date: '13 Dec 2024',
              time: '6:45 PM',
              from: 'Hitech City, Hyderabad',
              to: 'Secunderabad Station',
              amount: '₹180',
              rating: 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideCard({
    required String driverName,
    required String vehicleType,
    required String date,
    required String time,
    required String from,
    required String to,
    required String amount,
    required int rating,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _appTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _appTheme.dividerColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    driverName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _appTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    vehicleType,
                    style: TextStyle(
                      fontSize: 12,
                      color: _appTheme.textGrey,
                    ),
                  ),
                ],
              ),
              Text(
                amount,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.circle, color: Colors.green, size: 8),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  from,
                  style: TextStyle(
                    fontSize: 14,
                    color: _appTheme.textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.circle, color: _appTheme.brandRed, size: 8),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  to,
                  style: TextStyle(
                    fontSize: 14,
                    color: _appTheme.textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$date • $time',
                style: TextStyle(
                  fontSize: 12,
                  color: _appTheme.textGrey,
                ),
              ),
              if (rating == 0)
                ElevatedButton(
                  onPressed: () => _showRatingDialog(driverName),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _appTheme.brandRed,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Rate Now',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 16,
                    );
                  }),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRatingDialog(String driverName) {
    int selectedRating = 0;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            'Rate $driverName',
            style: TextStyle(color: _appTheme.textColor),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How was your ride?',
                style: TextStyle(color: _appTheme.textGrey),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      setDialogState(() {
                        selectedRating = index + 1;
                      });
                    },
                    child: Icon(
                      index < selectedRating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 40,
                    ),
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: _appTheme.textGrey),
              ),
            ),
            ElevatedButton(
              onPressed: selectedRating > 0
                  ? () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Thank you for rating!'),
                          backgroundColor: _appTheme.brandRed,
                        ),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _appTheme.brandRed,
                elevation: 0,
              ),
              child: const Text(
                'Submit',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

