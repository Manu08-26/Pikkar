import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'ride_completed_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';

class RideInProgressScreen extends StatefulWidget {
  final String pickupLocation;
  final String dropLocation;
  final String rideType;
  final LatLng? pickupLatLng;
  final LatLng? dropLatLng;
  final Map<String, dynamic> rideDetails;

  const RideInProgressScreen({
    super.key,
    required this.pickupLocation,
    required this.dropLocation,
    required this.rideType,
    this.pickupLatLng,
    this.dropLatLng,
    required this.rideDetails,
  });

  @override
  State<RideInProgressScreen> createState() => _RideInProgressScreenState();
}

class _RideInProgressScreenState extends State<RideInProgressScreen> {
  final AppTheme _appTheme = AppTheme();
  GoogleMapController? _mapController;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  final int _remainingMinutes = 15;
  final double _remainingKm = 5.2;
  Timer? _progressTimer;
  bool _isMapInitialized = false;

  @override
  void initState() {
    super.initState();
    _startRideProgress();
  }

  void _startRideProgress() {
    // Navigate to ride completed after 5 seconds for faster testing
    _progressTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        _navigateToRideCompleted();
      }
    });
  }

  void _navigateToRideCompleted() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => RideCompletedScreen(
          pickupLocation: widget.pickupLocation,
          dropLocation: widget.dropLocation,
          rideType: widget.rideType,
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
    
    // Driver location (slightly ahead of pickup for demo)
    final driverLocation = LatLng(
      pickup.latitude + 0.005,
      pickup.longitude + 0.005,
    );

    // Add markers
    setState(() {
      _markers = {
        // Pickup location marker
        Marker(
          markerId: const MarkerId('pickup'),
          position: pickup,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: 'Pickup Location',
            snippet: widget.pickupLocation,
          ),
        ),
        // Driver live location marker
        Marker(
          markerId: const MarkerId('driver'),
          position: driverLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: 'Driver Location',
            snippet: 'Your driver is here',
          ),
        ),
        // Drop location marker
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

    // Add route polyline from driver to drop
    setState(() {
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: [driverLocation, drop],
          color: _appTheme.brandRed,
          width: 4,
        ),
      };
    });

    // Center on driver location
    if (_mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(driverLocation, 14),
      );
    }
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    // Show dialog to simulate call
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Call Driver',
          style: TextStyle(fontSize: Responsive.fontSize(context, 18)),
        ),
        content: Text(
          'Calling $phoneNumber...',
          style: TextStyle(fontSize: Responsive.fontSize(context, 14)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(fontSize: Responsive.fontSize(context, 14)),
            ),
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
        title: Text(
          'Send Message',
          style: TextStyle(fontSize: Responsive.fontSize(context, 18)),
        ),
        content: Text(
          'Opening messages to $phoneNumber...',
          style: TextStyle(fontSize: Responsive.fontSize(context, 14)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(fontSize: Responsive.fontSize(context, 14)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = Responsive.height(context);
    final buttonTop = screenHeight * 0.68;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.dropLatLng ?? const LatLng(17.440181, 78.348457),
              zoom: 14,
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

          // Back button
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

          // ETA Card
          Positioned(
            top: Responsive.hp(context, 13.5),
            left: Responsive.padding(context, 16),
            right: Responsive.padding(context, 16),
            child: Container(
              padding: EdgeInsets.all(Responsive.padding(context, 16)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Flexible(
                    child: Column(
                      children: [
                        Text(
                          '$_remainingMinutes mins',
                          style: TextStyle(
                            fontSize: Responsive.fontSize(context, 20),
                            fontWeight: FontWeight.bold,
                            color: _appTheme.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: Responsive.spacing(context, 4)),
                        Text(
                          'ETA',
                          style: TextStyle(
                            fontSize: Responsive.fontSize(context, 12),
                            color: _appTheme.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: Responsive.spacing(context, 40),
                    color: Colors.grey.shade300,
                  ),
                  Flexible(
                    child: Column(
                      children: [
                        Text(
                          '${_remainingKm.toStringAsFixed(1)} km',
                          style: TextStyle(
                            fontSize: Responsive.fontSize(context, 20),
                            fontWeight: FontWeight.bold,
                            color: _appTheme.textColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: Responsive.spacing(context, 4)),
                        Text(
                          'Distance',
                          style: TextStyle(
                            fontSize: Responsive.fontSize(context, 12),
                            color: _appTheme.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: Responsive.spacing(context, 40),
                    color: Colors.grey.shade300,
                  ),
                  Flexible(
                    child: Column(
                      children: [
                        Text(
                          widget.rideDetails['price']?.toString() ?? '₹120',
                          style: TextStyle(
                            fontSize: Responsive.fontSize(context, 20),
                            fontWeight: FontWeight.bold,
                            color: _appTheme.textColor,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: Responsive.spacing(context, 4)),
                        Text(
                          'Fare',
                          style: TextStyle(
                            fontSize: Responsive.fontSize(context, 12),
                            color: _appTheme.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Sheet - Fixed (No Scroll)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: Responsive.hp(context, 37),
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag Handle
                  Container(
                    margin: EdgeInsets.symmetric(vertical: Responsive.spacing(context, 12)),
                    width: Responsive.spacing(context, 40),
                    height: Responsive.spacing(context, 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.padding(context, 20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                          // Ride in Progress Header
                          Center(
                            child: Text(
                              'Ride in Progress',
                              style: TextStyle(
                                fontSize: Responsive.fontSize(context, 18),
                                fontWeight: FontWeight.bold,
                                color: _appTheme.textColor,
                              ),
                            ),
                          ),
                          SizedBox(height: Responsive.spacing(context, 16)),

                          // Driver Card
                          Container(
                            padding: EdgeInsets.all(Responsive.padding(context, 12)),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: Responsive.spacing(context, 30),
                                  backgroundColor: Colors.grey.shade300,
                                  backgroundImage: const AssetImage('assets/images/driver_placeholder.png'),
                                ),
                                SizedBox(width: Responsive.spacing(context, 12)),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Sri Akshay',
                                        style: TextStyle(
                                          fontSize: Responsive.fontSize(context, 16),
                                          fontWeight: FontWeight.w600,
                                          color: _appTheme.textColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: Responsive.spacing(context, 4)),
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              widget.rideDetails['vehicleNumber'] ?? 'TS02E1655',
                                              style: TextStyle(
                                                fontSize: Responsive.fontSize(context, 14),
                                                color: _appTheme.textGrey,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          SizedBox(width: Responsive.spacing(context, 8)),
                                          Text(
                                            '⭐',
                                            style: TextStyle(fontSize: Responsive.fontSize(context, 12)),
                                          ),
                                          SizedBox(width: Responsive.spacing(context, 4)),
                                          Text(
                                            '4.9',
                                            style: TextStyle(
                                              fontSize: Responsive.fontSize(context, 13),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Call button
                                CircleAvatar(
                                  backgroundColor: Colors.grey.shade300,
                                  radius: Responsive.spacing(context, 22),
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.phone,
                                      color: Colors.black,
                                      size: Responsive.iconSize(context, 20),
                                    ),
                                    onPressed: () => _makePhoneCall('+919876543210'),
                                    padding: EdgeInsets.zero,
                                  ),    
                                ),
                                SizedBox(width: Responsive.spacing(context, 8)),
                                // Message button
                                CircleAvatar(
                                  backgroundColor: Colors.grey.shade300,
                                  radius: Responsive.spacing(context, 22),
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.message,
                                      color: _appTheme.textColor,
                                      size: Responsive.iconSize(context, 20),
                                    ),
                                    onPressed: () => _sendMessage('+919876543210'),
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: Responsive.spacing(context, 20)),

                          // Drop Details Header with Get Help button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  'Drop Details',
                                  style: TextStyle(
                                    fontSize: Responsive.fontSize(context, 18),
                                    fontWeight: FontWeight.w600,
                                    color: _appTheme.textColor,
                                  ),
                                ),
                              ),
                              Flexible(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text(
                                          'Get Help',
                                          style: TextStyle(fontSize: Responsive.fontSize(context, 18)),
                                        ),
                                        content: Text(
                                          'How can we help you?',
                                          style: TextStyle(fontSize: Responsive.fontSize(context, 14)),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: Text(
                                              'Close',
                                              style: TextStyle(fontSize: Responsive.fontSize(context, 14)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  icon: Icon(
                                    Icons.help_outline,
                                    size: Responsive.iconSize(context, 18),
                                  ),
                                  label: Text(
                                    'Get Help',
                                    style: TextStyle(fontSize: Responsive.fontSize(context, 14)),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _appTheme.brandRed,
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
                              ),
                            ],
                          ),
                          SizedBox(height: Responsive.spacing(context, 16)),

                          // Drop Location
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: EdgeInsets.only(top: Responsive.spacing(context, 2)),
                                padding: EdgeInsets.all(Responsive.padding(context, 4)),
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.circle,
                                  color: Colors.green,
                                  size: Responsive.spacing(context, 8),
                                ),
                              ),
                              SizedBox(width: Responsive.spacing(context, 12)),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Extract first part before comma as main address
                                    Text(
                                      widget.dropLocation.split(',').first.trim(),
                                      style: TextStyle(
                                        fontSize: Responsive.fontSize(context, 16),
                                        fontWeight: FontWeight.w600,
                                        color: _appTheme.textColor,
                                      ),
                                    ),
                                    SizedBox(height: Responsive.spacing(context, 4)),
                                    // Full address in grey
                                    Text(
                                      widget.dropLocation,
                                      style: TextStyle(
                                        fontSize: Responsive.fontSize(context, 13),
                                        color: _appTheme.textGrey,
                                        height: 1.4,
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: Responsive.spacing(context, 20)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        
        ],
      ),
    );
  }
}

