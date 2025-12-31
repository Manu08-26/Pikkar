import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'cancel_ride_reasons_screen.dart';
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
  bool _isFindingDriver = true;
  double _progressValue = 0.0;

  @override
  void initState() {
    super.initState();
    _appTheme.addListener(_onThemeChanged);
    _initializeMap();
    _startFindingDriver();
  }

  @override
  void dispose() {
    _appTheme.removeListener(_onThemeChanged);
    _mapController?.dispose();
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
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
    // Simulate finding driver progress
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && _isFindingDriver) {
        setState(() {
          _progressValue += 0.02;
          if (_progressValue >= 1.0) {
            _progressValue = 0.0;
          }
        });
        _startFindingDriver();
      }
    });
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
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.pickupLocation,
                style: TextStyle(
                  color: _appTheme.textGrey,
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                widget.dropLocation,
                style: TextStyle(
                  color: _appTheme.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        body: SizedBox.expand(
          child: Stack(
            children: [
              // Map View
              GoogleMap(
              onMapCreated: (controller) {
                _mapController = controller;
                Future.delayed(const Duration(milliseconds: 500), () {
                  _zoomToFitMarkers();
                });
              },
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
            ),

            // Finding Driver Bottom Sheet
            DraggableScrollableSheet(
              initialChildSize: 0.5,
              minChildSize: 0.3,
              maxChildSize: 0.85,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: _appTheme.cardColor,
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

                      // Finding Driver Header
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
                            const SizedBox(height: 8),
                            Text(
                              'We are finding the nearest ${widget.rideType} for you',
                              style: TextStyle(
                                fontSize: 14,
                                color: _appTheme.textGrey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Progress Indicator
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: LinearProgressIndicator(
                          value: _progressValue,
                          backgroundColor: _appTheme.iconBgColor,
                          valueColor: AlwaysStoppedAnimation<Color>(_appTheme.brandRed),
                          minHeight: 4,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Ride Details
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          children: [
                            // Ride Options (Read-only)
                            _buildRideOptionCard(widget.rideType),
                            const SizedBox(height: 16),

                         
                            const SizedBox(height: 20),
                          ],
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
                              fontSize: 14,
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
                                  Text(
                                    'Direct pay to Driver',
                                    style: TextStyle(
                                            color: Colors.black.withOpacity(0.8),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  backgroundColor: Colors.white,
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
                );
              },
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
              color: _appTheme.brandRed,
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
