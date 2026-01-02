import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'ride_completed_screen.dart';
import '../../../core/theme/app_theme.dart';

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
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};
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
    _progressTimer = Timer(const Duration(seconds: 15), () {
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

    // Add markers
    _markers.addAll({
      Marker(
        markerId: const MarkerId('drop'),
        position: drop,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: 'Destination', snippet: widget.dropLocation),
      ),
    });

    // Add route polyline
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('route'),
        points: [pickup, drop],
        color: _appTheme.brandRed,
        width: 4,
      ),
    );

    // Center on destination
    if (_mapController != null) {
      await _mapController!.animateCamera(CameraUpdate.newLatLngZoom(drop, 14));
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

  @override
  Widget build(BuildContext context) {
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
            top: 550,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              radius: 20,
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: _appTheme.textColor, size: 20),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
              ),
            ),
          ),

          // Re-center map button
          Positioned(
            top: 550,
            right: 16,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              radius: 20,
              child: IconButton(
                icon: Icon(Icons.my_location, color: _appTheme.textColor, size: 20),
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
            top: 110,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
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
                  Column(
                    children: [
                      Text(
                        '$_remainingMinutes mins',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _appTheme.black,
                        ),
                      ),
                      Text(
                        'ETA',
                        style: TextStyle(
                          fontSize: 12,
                          color: _appTheme.textGrey,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey.shade300,
                  ),
                  Column(
                    children: [
                      Text(
                        '${_remainingKm.toStringAsFixed(1)} km',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _appTheme.textColor,
                        ),
                      ),
                      Text(
                        'Distance',
                        style: TextStyle(
                          fontSize: 12,
                          color: _appTheme.textGrey,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey.shade300,
                  ),
                  Column(
                    children: [
                      Text(
                        widget.rideDetails['price']?.toString() ?? '₹120',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _appTheme.textColor,
                        ),
                      ),
                      Text(
                        'Fare',
                        style: TextStyle(
                          fontSize: 12,
                          color: _appTheme.textGrey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Bottom Sheet - Fixed
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.35,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
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
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Ride in Progress Header
                          Center(
                            child: Text(
                              'Ride in Progress',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _appTheme.textColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Driver Card
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Colors.grey.shade300,
                                  backgroundImage: const AssetImage('assets/images/driver_placeholder.png'),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Sri Akshay',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: _appTheme.textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            widget.rideDetails['vehicleNumber'] ?? 'TS02E1655',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: _appTheme.textGrey,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Text('⭐', style: TextStyle(fontSize: 12)),
                                          const SizedBox(width: 4),
                                          const Text(
                                            '4.9',
                                            style: TextStyle(
                                              fontSize: 13,
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
                                  radius: 22,
                                  child: IconButton(
                                    icon: const Icon(Icons.phone, color: Colors.black, size: 20),
                                    onPressed: () => _makePhoneCall('+919876543210'),
                                    padding: EdgeInsets.zero,
                                  ),    
                                ),
                                const SizedBox(width: 8),
                                // Message button
                                CircleAvatar(
                                  backgroundColor: Colors.grey.shade300,
                                  radius: 22,
                                  child: IconButton(
                                    icon: Icon(Icons.message, color: _appTheme.textColor, size: 20),
                                    onPressed: () => _sendMessage('+919876543210'),
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Drop Details Header with Get Help button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Drop Details',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: _appTheme.textColor,
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  // Handle get help action
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Get Help'),
                                      content: const Text('How can we help you?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('Close'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.help_outline, size: 18),
                                label: const Text('Get Help'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _appTheme.brandRed,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Drop Location
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.circle,
                                  color: Colors.green,
                                  size: 8,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Extract first part before comma as main address
                                    Text(
                                      widget.dropLocation.split(',').first.trim(),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: _appTheme.textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    // Full address in grey
                                    Text(
                                      widget.dropLocation,
                                      style: TextStyle(
                                        fontSize: 13,
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
                          const SizedBox(height: 20),
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

