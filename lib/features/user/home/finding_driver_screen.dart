import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'cancel_ride_reasons_screen.dart';
import 'driver_details_screen.dart';
import '../../../core/theme/app_theme.dart';

class FindingDriverScreen extends StatefulWidget {
  final String pickupLocation;
  final String dropLocation;
  final String rideType;
  final LatLng? pickupLatLng;
  final LatLng? dropLatLng;

  const FindingDriverScreen({
    super.key,
    required this.pickupLocation,
    required this.dropLocation,
    required this.rideType,
    this.pickupLatLng,
    this.dropLatLng,
  });

  @override
  State<FindingDriverScreen> createState() => _FindingDriverScreenState();
}

class _FindingDriverScreenState extends State<FindingDriverScreen> {
  final AppTheme _appTheme = AppTheme();
  GoogleMapController? _mapController;
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};
  Timer? _findingTimer;

  @override
  void initState() {
    super.initState();
    _initializeMap();
    _startFindingDriver();
  }

  @override
  void dispose() {
    _findingTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _initializeMap() {
    _markers.clear();
    _polylines.clear();

    if (widget.pickupLatLng != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: widget.pickupLatLng!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(title: widget.pickupLocation),
        ),
      );
    }

    if (widget.dropLatLng != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('drop'),
          position: widget.dropLatLng!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: widget.dropLocation),
        ),
      );
    }

    if (widget.pickupLatLng != null && widget.dropLatLng != null) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: [widget.pickupLatLng!, widget.dropLatLng!],
          color: _appTheme.brandRed,
          width: 5,
          patterns: [],
        ),
      );
      _zoomToFitMarkers();
    } else if (widget.pickupLatLng != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(widget.pickupLatLng!, 14.0),
      );
    }
  }

  void _zoomToFitMarkers() {
    if (widget.pickupLatLng != null && widget.dropLatLng != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(
              widget.pickupLatLng!.latitude < widget.dropLatLng!.latitude
                  ? widget.pickupLatLng!.latitude
                  : widget.dropLatLng!.latitude,
              widget.pickupLatLng!.longitude < widget.dropLatLng!.longitude
                  ? widget.pickupLatLng!.longitude
                  : widget.dropLatLng!.longitude,
            ),
            northeast: LatLng(
              widget.pickupLatLng!.latitude > widget.dropLatLng!.latitude
                  ? widget.pickupLatLng!.latitude
                  : widget.dropLatLng!.latitude,
              widget.pickupLatLng!.longitude > widget.dropLatLng!.longitude
                  ? widget.pickupLatLng!.longitude
                  : widget.dropLatLng!.longitude,
            ),
          ),
          100,
        ),
      );
    }
  }

  void _startFindingDriver() {
    // Simulate finding driver - automatically navigate after 5 seconds
    _findingTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        _navigateToDriverDetails();
      }
    });
  }
  
  void _navigateToDriverDetails() {
    // Mock ride details
    final rideDetails = {
      'vehicleNumber': 'TS02E1655',
      'vehicleModel': 'Hero Honda',
      'driverName': 'Sri Akshay',
      'driverRating': '4.9',
      'price': '₹120',
      'distance': '5.2 km',
      'duration': '15 mins',
    };
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DriverDetailsScreen(
          pickupLocation: widget.pickupLocation,
          dropLocation: widget.dropLocation,
          rideType: widget.rideType,
          pickupLatLng: widget.pickupLatLng,
          dropLatLng: widget.dropLatLng,
          rideDetails: rideDetails,
        ),
      ),
    );
  }

  void _handleCancelRide() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CancelRideReasonsScreen(
          onCancelConfirmed: (reason) {
            // Just pop the cancel reasons screen
            Navigator.pop(context, true);
          },
        ),
      ),
    );
    
    // If cancellation was confirmed, go back to ride booking screen
    if (result == true && mounted) {
      Navigator.pop(context); // Pop finding driver screen to go back to ride booking screen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Ride cancelled'),
          backgroundColor: _appTheme.brandRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _appTheme.textDirection,
      child: Scaffold(
        backgroundColor: _appTheme.backgroundColor,
        body: SizedBox.expand(
          child: Stack(
            children: [
              // Map View
              GoogleMap(
                onMapCreated: (controller) {
                  _mapController = controller;
                  if (widget.pickupLatLng != null) {
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLngZoom(widget.pickupLatLng!, 14.0),
                    );
                  }
                },
                initialCameraPosition: CameraPosition(
                  target: widget.pickupLatLng ?? const LatLng(17.4175, 78.4934),
                  zoom: 14.0,
                ),
                markers: const {},
                polylines: const {},
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
              ),

            // Fixed Bottom Sheet (not draggable)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.48,
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
                    // Drag Handle (visual only)
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: _appTheme.textGrey,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                    // Finding Driver Header with animated dots
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            Text(
                              'Looking for Pikkar',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: _appTheme.textColor,
                              ),
                            ),
                          const SizedBox(height: 12),
                            Text(
                              'We are finding the nearest ${widget.rideType} for you',
                              style: TextStyle(
                                fontSize: 14,
                                color: _appTheme.textGrey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          const SizedBox(height: 12),
                          // Static loading indicator
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(_appTheme.brandRed),
                            ),
                          ),
                          const SizedBox(height: 8),
                         
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                    // Ride Details (fixed content, no scroll)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            // Ride Options (Read-only)
                            _buildRideOptionCard(widget.rideType),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                    
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
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildRideOptionCard(String rideType) {
    Map<String, dynamic> rideDetails = _getRideDetails(rideType);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          // Ride Image/Icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _appTheme.cardColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                rideDetails['image'] as String,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    rideDetails['icon'] as IconData,
                    color: _appTheme.brandRed,
                    size: 32,
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Ride Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rideType,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _appTheme.textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${rideDetails['time']} | ${rideDetails['baseFare']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: _appTheme.textGrey,
                  ),
                ),
              ],
            ),
          ),
          // Price
          Text(
            rideDetails['price'] as String,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _appTheme.black,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getRideDetails(String rideType) {
    switch (rideType) {
      case 'Bike':
        return {
          'image': 'assets/bike1.png',
          'time': '2 Min',
          'baseFare': '1₹',
          'price': '₹65',
          'icon': Icons.two_wheeler,
        };
      case 'Auto':
        return {
          'image': 'assets/auto1.png',
          'time': '2 Min',
          'baseFare': '3₹',
          'price': '₹90',
          'icon': Icons.airport_shuttle,
        };
      case 'Cab':
        return {
          'image': 'assets/car1.png',
          'time': '2 Min',
          'baseFare': '4₹',
          'price': '₹180',
          'icon': Icons.directions_car,
        };
      case 'SUV':
        return {
          'image': 'assets/car1.png',
          'time': '3 Min',
          'baseFare': '5₹',
          'price': '₹250',
          'icon': Icons.directions_car,
        };
      case 'Prime Cab':
        return {
          'image': 'assets/car1.png',
          'time': '2 Min',
          'baseFare': '6₹',
          'price': '₹300',
          'icon': Icons.local_taxi,
        };
      default:
        return {
          'image': 'assets/bike1.png',
          'time': '2 Min',
          'baseFare': '1₹',
          'price': '₹65',
          'icon': Icons.two_wheeler,
        };
    }
  }
}
