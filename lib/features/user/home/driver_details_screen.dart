import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'ride_in_progress_screen.dart';
import 'cancel_ride_reasons_screen.dart';
import '../../../core/theme/app_theme.dart';

import '../../../core/utils/responsive.dart';

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
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
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
    
    // Driver location (initialize if not set)
    if (_driverLocation == null) {
      _driverLocation = LatLng(
        pickup.latitude + 0.02,
        pickup.longitude + 0.01,
      );
    }

    // Add markers using setState like ride_in_progress_screen
    setState(() {
      _markers = {
        // Pickup location marker (Blue - user's current location)
        Marker(
          markerId: const MarkerId('pickup'),
          position: pickup,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: 'Pickup Location',
            snippet: widget.pickupLocation,
          ),
        ),
        // Driver live location marker (Green)
        Marker(
          markerId: const MarkerId('driver'),
          position: _driverLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(
            title: 'Driver Location',
            snippet: 'Your driver is here',
          ),
        ),
        // Drop location marker (Red)
        Marker(
          markerId: const MarkerId('drop'),
          position: drop,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'Destination',
            snippet: widget.dropLocation,
          ),
        ),
      };
    });

    // Add route polyline from driver to drop (like ride_in_progress_screen)
    setState(() {
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: [_driverLocation!, drop],
          color: _appTheme.brandRed,
          width: 4,
        ),
      };
    });

    // Center on driver location
    if (_mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_driverLocation!, 14),
      );
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
    
    final pickup = widget.pickupLatLng ?? const LatLng(17.385044, 78.486671);
    final drop = widget.dropLatLng ?? const LatLng(17.440181, 78.348457);
    
    // Update markers using setState like ride_in_progress_screen
    setState(() {
      _markers = {
        // Pickup location marker (Blue - user's current location)
        Marker(
          markerId: const MarkerId('pickup'),
          position: pickup,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: 'Pickup Location',
            snippet: widget.pickupLocation,
          ),
        ),
        // Driver live location marker (Green)
        Marker(
          markerId: const MarkerId('driver'),
          position: _driverLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(
            title: 'Driver Location',
            snippet: 'Your driver is here',
          ),
        ),
        // Drop location marker (Red)
        Marker(
          markerId: const MarkerId('drop'),
          position: drop,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'Destination',
            snippet: widget.dropLocation,
          ),
        ),
      };
      
      // Update polyline from driver to drop
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: [_driverLocation!, drop],
          color: _appTheme.brandRed,
          width: 4,
        ),
      };
    });
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
    final screenHeight = Responsive.height(context);
    final buttonTop = screenHeight * 0.35;
    final sheetHeight = Responsive.hp(context, 55);
    final handleWidth = Responsive.spacing(context, 40);
    final handleHeight = Responsive.spacing(context, 4);
    final horizontalPadding = Responsive.padding(context, 20);
    final smallSpacing = Responsive.spacing(context, 12);
    final mediumSpacing = Responsive.spacing(context, 16);
    final bannerFontSize = Responsive.fontSize(context, 10);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Map View
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.pickupLatLng ?? const LatLng(17.4175, 78.4934),
              zoom: 14.0,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapType: MapType.normal,
            zoomControlsEnabled: false,
            compassEnabled: true,
            buildingsEnabled: true,
            trafficEnabled: false,
            mapToolbarEnabled: false,
            rotateGesturesEnabled: true,
            scrollGesturesEnabled: true,
            tiltGesturesEnabled: true,
            zoomGesturesEnabled: true,
            onMapCreated: (controller) {
              _mapController = controller;
              _initializeMap();
            },
          ),
            Positioned(
            top: buttonTop,
            left: Responsive.padding(context, 16),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              radius: Responsive.spacing(context, 20),
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: _appTheme.textColor,
                  size: Responsive.iconSize(context, 20),
                ),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
              ),
            ),
          ),

          // Re-center map button
          Positioned(
            top: buttonTop,
            right: Responsive.padding(context, 16),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              radius: Responsive.spacing(context, 20),
              child: IconButton(
                icon: Icon(
                  Icons.my_location,
                  color: _appTheme.textColor,
                  size: Responsive.iconSize(context, 20),
                ),
                onPressed: () {
                  if (_mapController != null && widget.dropLatLng != null) {
                    _mapController!.animateCamera(
                      CameraUpdate.newLatLngZoom(widget.dropLatLng!, 14),
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
            height: sheetHeight,
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
                    margin: EdgeInsets.symmetric(vertical: smallSpacing),
                    width: handleWidth,
                    height: handleHeight,
                    decoration: BoxDecoration(
                      color: _appTheme.textGrey,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Scrollable Content
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Arrival time - Centered
                            Center(
                              child: Text(
                                'Partner Arriving in $_arrivalMinutes mins',
                                style: TextStyle(
                                  fontSize: Responsive.fontSize(context, 18),
                                  fontWeight: FontWeight.w600,
                                  color: _appTheme.textColor,
                                ),
                              ),
                            ),
                            SizedBox(height: mediumSpacing),

                            // OTP Section - Label left, digits right
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    'Share OTP with Partner',
                                    style: TextStyle(
                                      fontSize: Responsive.fontSize(context, 16),
                                      color: _appTheme.textColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Row(
                                  children: _otp.split('').map((digit) {
                                    return Container(
                                      margin: EdgeInsets.only(left: smallSpacing / 2),
                                      width: Responsive.spacing(context, 40),
                                      height: Responsive.spacing(context, 40),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E3A5F),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        digit,
                                        style: TextStyle(
                                          fontSize: Responsive.fontSize(context, 20),
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                            SizedBox(height: mediumSpacing),

                            // Driver Card
                            Container(
                              padding: EdgeInsets.all(Responsive.padding(context, 16)),
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
                                            fontSize: Responsive.fontSize(context, 18),
                                            fontWeight: FontWeight.bold,
                                            color: _appTheme.textColor,
                                            letterSpacing: 0.5,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: Responsive.spacing(context, 4)),
                                        // Vehicle model
                                        Text(
                                          widget.rideDetails['vehicleModel'] ?? 'Hero Honda',
                                          style: TextStyle(
                                            fontSize: Responsive.fontSize(context, 12),
                                            color: _appTheme.textGrey,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: Responsive.spacing(context, 12)),
                                        // Driver name and rating
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                'Sri Akshay',
                                                style: TextStyle(
                                                  fontSize: Responsive.fontSize(context, 14),
                                                  fontWeight: FontWeight.w600,
                                                  color: _appTheme.textColor,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            SizedBox(width: Responsive.spacing(context, 6)),
                                            Text('⭐', style: TextStyle(fontSize: Responsive.fontSize(context, 14))),
                                            SizedBox(width: Responsive.spacing(context, 4)),
                                            Text(
                                              '4.9',
                                              style: TextStyle(
                                                fontSize: Responsive.fontSize(context, 12),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: Responsive.spacing(context, 12)),
                                        // Call and Message buttons
                                        Row(
                                          children: [
                                            // Call button - Green
                                            ElevatedButton.icon(
                                              onPressed: () => _makePhoneCall('+919876543210'),
                                              icon: Icon(Icons.phone, size: Responsive.iconSize(context, 18)),
                                              label: Text(
                                                'Call',
                                                style: TextStyle(fontSize: Responsive.fontSize(context, 14)),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                foregroundColor: Colors.white,
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: Responsive.padding(context, 16),
                                                  vertical: Responsive.padding(context, 10),
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(25),
                                                ),
                                                elevation: 0,
                                              ),
                                            ),
                                            SizedBox(width: Responsive.spacing(context, 12)),
                                            // Message button - Light
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                onPressed: () => _sendMessage('+919876543210'),
                                                icon: Icon(
                                                  Icons.message_outlined,
                                                  size: Responsive.iconSize(context, 18),
                                                  color: _appTheme.textGrey,
                                                ),
                                                label: Text(
                                                  'Send msg to Akshay',
                                                  style: TextStyle(
                                                    color: _appTheme.textGrey,
                                                    fontSize: Responsive.fontSize(context, 13),
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                style: OutlinedButton.styleFrom(
                                                  side: BorderSide(color: Colors.grey.shade300),
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: Responsive.padding(context, 12),
                                                    vertical: Responsive.padding(context, 10),
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
                                  SizedBox(width: Responsive.spacing(context, 12)),
                                  // Driver photo - Right side
                                  CircleAvatar(
                                    radius: Responsive.spacing(context, 30),
                                    backgroundColor: Colors.grey.shade300,
                                    backgroundImage: const AssetImage('assets/images/driver_placeholder.png'),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: Responsive.spacing(context, 20)),

                            // Ride Details
                            Text(
                              'Ride Details',
                              style: TextStyle(
                                fontSize: Responsive.fontSize(context, 16),
                                fontWeight: FontWeight.w600,
                                color: _appTheme.textColor,
                              ),
                            ),
                            SizedBox(height: smallSpacing),
                            Container(
                              padding: EdgeInsets.all(Responsive.padding(context, 14)),
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
                                  SizedBox(height: smallSpacing),
                                  _buildLocationRow(
                                    Icons.circle,
                                    _appTheme.brandRed,
                                    widget.dropLocation,
                                    'Drop',
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: mediumSpacing),
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
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.padding(context, 12),
                          vertical: Responsive.spacing(context, 8),
                        ),
                        color: Colors.green,
                        alignment: Alignment.center,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Transparent fares and zero hidden charges - only on Pikkar.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: bannerFontSize,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                          ),
                        ),
                      ),

                      // Payment Method and Cancel Ride Button in same row
                      Container(
                        padding: EdgeInsets.all(horizontalPadding),
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
                                  Text(
                                    'Cash',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w500,
                                      fontSize: Responsive.fontSize(context, 14),
                                    ),
                                  ),
                                  Text(
                                    ' | ',
                                    style: TextStyle(
                                      color: Colors.black.withOpacity(0.8),
                                      fontWeight: FontWeight.w600,
                                      fontSize: Responsive.fontSize(context, 13),
                                    ),
                                  ),
                                  Text(
                                    'Pay to Driver',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w600,
                                      fontSize: Responsive.fontSize(context, 13),
                                    ),
                                  ),
                                ],
                              ),
                              // Cancel Ride Button (Right)
                              OutlinedButton(
                                onPressed: _handleCancelRide,
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: _appTheme.brandRed, width: 2),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: Responsive.padding(context, 20),
                                    vertical: Responsive.padding(context, 12),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  backgroundColor: Colors.white,
                                  minimumSize: Size(
                                    Responsive.spacing(context, 100),
                                    Responsive.spacing(context, 40),
                                  ),
                                ),
                                child: Text(
                                  'Cancel Ride',
                                  style: TextStyle(
                                    color: _appTheme.brandRed,
                                    fontSize: Responsive.fontSize(context, 15),
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

