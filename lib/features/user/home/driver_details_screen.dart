import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'ride_in_progress_screen.dart';
import 'cancel_ride_reasons_screen.dart';
import '../../../core/theme/app_theme.dart';

class DriverDetailsScreen extends StatefulWidget {
  final String pickupLocation;
  final String dropLocation;
  final String rideType;
  final LatLng? pickupLatLng;
  final LatLng? dropLatLng;
  final Map<String, dynamic> rideDetails;

  const DriverDetailsScreen({
    super.key,
    required this.pickupLocation,
    required this.dropLocation,
    required this.rideType,
    this.pickupLatLng,
    this.dropLatLng,
    required this.rideDetails,
  });

  @override
  State<DriverDetailsScreen> createState() => _DriverDetailsScreenState();
}

class _DriverDetailsScreenState extends State<DriverDetailsScreen> {
  final AppTheme _appTheme = AppTheme();
  GoogleMapController? _mapController;
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};
  final int _arrivalMinutes = 10;
  Timer? _countdownTimer;
  Timer? _driverLocationTimer;
  final String _otp = '1205'; // In real app, this comes from backend
  bool _isMapInitialized = false;
  LatLng? _driverLocation; // Driver's current location

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _simulateDriverMovement(); // Simulate driver approaching
  }

  void _startCountdown() {
    // Navigate to ride in progress after 5 seconds
    _countdownTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        _navigateToRideInProgress();
      }
    });
  }

  void _navigateToRideInProgress() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => RideInProgressScreen(
          pickupLocation: widget.pickupLocation,
          dropLocation: widget.dropLocation,
          rideType: widget.rideType,
          pickupLatLng: widget.pickupLatLng,
          dropLatLng: widget.dropLatLng,
          rideDetails: widget.rideDetails,
        ),
      ),
    );
  }

  Future<void> _initializeMap() async {
    if (_isMapInitialized) return; // Prevent multiple initializations
    _isMapInitialized = true;
    
    final pickup = widget.pickupLatLng ?? const LatLng(17.385044, 78.486671);
    final drop = widget.dropLatLng ?? const LatLng(17.440181, 78.348457);

    // Add pickup marker
    _markers.add(
      Marker(
        markerId: const MarkerId('pickup'),
        position: pickup,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: 'Pickup', snippet: widget.pickupLocation),
      ),
    );

    // Add drop marker
    _markers.add(
      Marker(
        markerId: const MarkerId('drop'),
        position: drop,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: 'Drop', snippet: widget.dropLocation),
      ),
    );

    // Add driver marker (moving)
    if (_driverLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: _driverLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Driver', snippet: 'Sri Akshay'),
        ),
      );
    }

    // Add route polyline from driver to pickup
    if (_driverLocation != null) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('driverRoute'),
          points: [_driverLocation!, pickup],
          color: Colors.blue,
          width: 4,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ),
      );
    }

    // Add route polyline from pickup to drop
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('route'),
        points: [pickup, drop],
        color: _appTheme.brandRed,
        width: 4,
      ),
    );

    // Fit bounds to show all markers
    if (_mapController != null && _driverLocation != null) {
      final bounds = LatLngBounds(
        southwest: LatLng(
          [pickup.latitude, drop.latitude, _driverLocation!.latitude].reduce((a, b) => a < b ? a : b),
          [pickup.longitude, drop.longitude, _driverLocation!.longitude].reduce((a, b) => a < b ? a : b),
        ),
        northeast: LatLng(
          [pickup.latitude, drop.latitude, _driverLocation!.latitude].reduce((a, b) => a > b ? a : b),
          [pickup.longitude, drop.longitude, _driverLocation!.longitude].reduce((a, b) => a > b ? a : b),
        ),
      );
      await _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _driverLocationTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _simulateDriverMovement() {
    // In real app, get driver location from Firebase/backend
    // This simulates driver moving towards pickup location
    final pickup = widget.pickupLatLng ?? const LatLng(17.385044, 78.486671);
    
    // Start driver 2km away (simulate)
    _driverLocation = LatLng(
      pickup.latitude + 0.02, // ~2km north
      pickup.longitude + 0.01, // ~1km east
    );
    
    // Update driver location every 2 seconds (simulate movement)
    _driverLocationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted && _driverLocation != null) {
        setState(() {
          // Move driver closer to pickup
          _driverLocation = LatLng(
            _driverLocation!.latitude - 0.004, // Move south
            _driverLocation!.longitude - 0.002, // Move west
          );
        });
        _updateDriverMarker();
      }
    });
  }

  void _updateDriverMarker() async {
    if (_driverLocation == null || !_isMapInitialized) return;
    
    // Remove old driver marker
    _markers.removeWhere((marker) => marker.markerId.value == 'driver');
    
    // Add updated driver marker with custom icon (car)
    _markers.add(
      Marker(
        markerId: const MarkerId('driver'),
        position: _driverLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'Driver', snippet: 'Sri Akshay'),
        rotation: 45, // Car rotation angle
      ),
    );
    
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    // Show dialog to simulate call
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Call Driver'),
        content: Text('Calling $phoneNumber...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage(String phoneNumber) async {
    // Show dialog to simulate message
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Message'),
        content: Text('Opening messages to $phoneNumber...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _handleCancelRide() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CancelRideReasonsScreen(
          onCancelConfirmed: (reason) {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Full Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.pickupLatLng ?? const LatLng(17.385044, 78.486671),
              zoom: 12,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
              _initializeMap();
            },
          ),

          // Re-center map button
          Positioned(
            top: 300,
            right: 16,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              radius: 20,
              child: IconButton(
                icon: Icon(Icons.my_location, color: _appTheme.textColor, size: 20),
                onPressed: () {
                  if (_mapController != null && widget.pickupLatLng != null) {
                    _mapController!.animateCamera(
                      CameraUpdate.newLatLngZoom(widget.pickupLatLng!, 14),
                    );
                  }
                },
                padding: EdgeInsets.zero,
              ),
            ),
          ),

          // Bottom Sheet - Fixed
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.55,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Drag Handle
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _appTheme.textGrey,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Scrollable Content
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Arrival time - Centered
                            Center(
                              child: Text(
                                'Partner Arriving in $_arrivalMinutes mins',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: _appTheme.textColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // OTP Section - Label left, digits right
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Share OTP with Partner',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: _appTheme.textColor,
                                  ),
                                ),
                                Row(
                                  children: _otp.split('').map((digit) {
                                    return Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E3A5F),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        digit,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Driver Card
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                children: [
                                  // Driver info - Left side
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Vehicle number
                                        Text(
                                          widget.rideDetails['vehicleNumber'] ?? 'TS02E1655',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: _appTheme.textColor,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        // Vehicle model
                                        Text(
                                          widget.rideDetails['vehicleModel'] ?? 'Hero Honda',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: _appTheme.textGrey,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        // Driver name and rating
                                        Row(
                                          children: [
                                            Text(
                                              'Sri Akshay',
                                              style: TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w600,
                                                color: _appTheme.textColor,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Text('⭐', style: TextStyle(fontSize: 16)),
                                            const SizedBox(width: 4),
                                            const Text(
                                              '4.9',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        // Call and Message buttons
                                        Row(
                                          children: [
                                            // Call button - Green
                                            ElevatedButton.icon(
                                              onPressed: () => _makePhoneCall('+919876543210'),
                                              icon: const Icon(Icons.phone, size: 18),
                                              label: const Text('call'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 20,
                                                  vertical: 12,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(25),
                                                ),
                                                elevation: 0,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            // Message button - Light
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                onPressed: () => _sendMessage('+919876543210'),
                                                icon: Icon(Icons.message_outlined, size: 18, color: _appTheme.textGrey),
                                                label: Text(
                                                  'Send msg to Akshay',
                                                  style: TextStyle(
                                                    color: _appTheme.textGrey,
                                                    fontSize: 13,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                style: OutlinedButton.styleFrom(
                                                  side: BorderSide(color: Colors.grey.shade300),
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 12,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(25),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Driver photo - Right side
                                  CircleAvatar(
                                    radius: 45,
                                    backgroundColor: Colors.grey.shade300,
                                    backgroundImage: const AssetImage('assets/images/driver_placeholder.png'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Ride Details
                            Text(
                              'Ride Details',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: _appTheme.textColor,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Column(
                                children: [
                                  _buildLocationRow(
                                    Icons.circle,
                                    Colors.green,
                                    widget.pickupLocation,
                                    'Pickup',
                                  ),
                                  const SizedBox(height: 16),
                                  _buildLocationRow(
                                    Icons.circle,
                                    _appTheme.brandRed,
                                    widget.dropLocation,
                                    'Drop',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Fixed Bottom Section
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Promotional Banner
                      Container(
                        width: double.infinity,
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        color: Colors.green,
                        alignment: Alignment.center,
                        child: const Text(
                          '"Transparent fares and zero hidden charges - only on Pikkar."',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),

                      // Payment Method and Cancel Ride Button in same row
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _appTheme.cardColor,
                          border: Border(
                            top: BorderSide(
                              color: _appTheme.dividerColor,
                              width: 1,
                            ),
                          ),
                        ),
                        child: SafeArea(
                          top: false,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Payment Method (Left)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Cash',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w400,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    ' | ',
                                    style: TextStyle(
                                      color: Colors.black.withOpacity(0.8),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const Text(
                                    'Pay to Driver',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              // Cancel Ride Button (Right)
                              OutlinedButton(
                                onPressed: _handleCancelRide,
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: _appTheme.brandRed, width: 2),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  backgroundColor: Colors.white,
                                  minimumSize: const Size(0, 50),
                                ),
                                child: Text(
                                  'Cancel Ride',
                                  style: TextStyle(
                                    color: _appTheme.brandRed,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow(IconData icon, Color color, String location, String label) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.2),
          ),
          child: Icon(icon, color: color, size: 12),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                location.split(',').first,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _appTheme.textColor,
                ),
              ),
              if (location.contains(','))
                Text(
                  location.substring(location.indexOf(',') + 1).trim(),
                  style: TextStyle(
                    fontSize: 12,
                    color: _appTheme.textGrey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        Icon(Icons.edit_outlined, color: _appTheme.textGrey, size: 20),
      ],
    );
  }
}

