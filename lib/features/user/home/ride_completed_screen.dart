import 'package:flutter/material.dart';
import 'rate_ride_screen.dart';
import '../../../core/theme/app_theme.dart';

class RideCompletedScreen extends StatefulWidget {
  final String pickupLocation;
  final String dropLocation;
  final String rideType;
  final Map<String, dynamic> rideDetails;

  const RideCompletedScreen({
    super.key,
    required this.pickupLocation,
    required this.dropLocation,
    required this.rideType,
    required this.rideDetails,
  });

  @override
  State<RideCompletedScreen> createState() => _RideCompletedScreenState();
}

class _RideCompletedScreenState extends State<RideCompletedScreen> with SingleTickerProviderStateMixin {
  final AppTheme _appTheme = AppTheme();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToRating() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => RateRideScreen(
          pickupLocation: widget.pickupLocation,
          dropLocation: widget.dropLocation,
          rideType: widget.rideType,
          rideDetails: widget.rideDetails,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fare = widget.rideDetails['price']?.toString() ?? '₹120';
    final distance = '5.2 km';
    final duration = '15 mins';
    final vehicleNumber = widget.rideDetails['vehicleNumber'] ?? 'TS02E1655';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              // Success Animation - GREEN icon
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 70,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Title
              Text(
                'Ride Completed!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _appTheme.textColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Hope you had a great journey',
                style: TextStyle(
                  fontSize: 14,
                  color: _appTheme.textGrey,
                ),
              ),
              const SizedBox(height: 24),
              
              // Fare Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    // Total Fare
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Fare',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _appTheme.textColor,
                          ),
                        ),
                        Text(
                          fare,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: _appTheme.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(color: Colors.grey.shade300, height: 1),
                    const SizedBox(height: 12),
                    
                    // Ride Details
                    _buildDetailRow('Distance', distance),
                    const SizedBox(height: 10),
                    _buildDetailRow('Duration', duration),
                    const SizedBox(height: 10),
                    _buildDetailRow('Vehicle', vehicleNumber),
                    const SizedBox(height: 10),
                    _buildDetailRow('Ride Type', widget.rideType),
                    const SizedBox(height: 12),
                    Divider(color: Colors.grey.shade300, height: 1),
                    const SizedBox(height: 12),
                    
                    // Payment Method
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.payments_outlined, color: _appTheme.textColor, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Cash Payment',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _appTheme.textColor,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          fare,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _appTheme.textColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Trip Details
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trip Details',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _appTheme.textColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildLocationRow(
                      Icons.circle,
                      Colors.green,
                      widget.pickupLocation,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 11),
                      child: Column(
                        children: List.generate(2, (index) => Container(
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          width: 2,
                          height: 3,
                          color: Colors.grey.shade300,
                        )),
                      ),
                    ),
                    _buildLocationRow(
                      Icons.circle,
                      _appTheme.brandRed,
                      widget.dropLocation,
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Rate Ride Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _navigateToRating,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _appTheme.brandRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Rate Your Ride',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              
              // Skip Button
              TextButton(
                onPressed: () {
                  // Navigate to home
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: Text(
                  'Skip for now',
                  style: TextStyle(
                    fontSize: 15,
                    color: _appTheme.textGrey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: _appTheme.textGrey,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _appTheme.textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationRow(IconData icon, Color color, String location) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.2),
          ),
          child: Icon(icon, color: color, size: 10),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            location,
            style: TextStyle(
              fontSize: 13,
              color: _appTheme.textColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
