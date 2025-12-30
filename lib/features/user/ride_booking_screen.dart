// import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/app_localizations.dart';
import 'finding_driver_screen.dart';


class RideBookingScreen extends StatefulWidget {
  final String? pickupLocation;
  final String? dropLocation;
  final String rideType;

  const RideBookingScreen({
    super.key,
    this.pickupLocation,
    this.dropLocation,
    required this.rideType,
  });

  @override
  State<RideBookingScreen> createState() => _RideBookingScreenState();
}

class _RideBookingScreenState extends State<RideBookingScreen> {
  final AppTheme _appTheme = AppTheme();
  GoogleMapController? _mapController;
  late String _selectedRideType; // Bike, Auto, Cab, SUV, Prime Cab
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};
  BitmapDescriptor? _bikeMarker;
  BitmapDescriptor? _carMarker;
  BitmapDescriptor? _autoMarker;
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropController = TextEditingController();
  static const String _apiKey = 'AIzaSyC-lm1swnNq-IAekwxiH9vyLwcOc2TNd3E';
  Position? _currentLocation;
  LatLng? _pickupLatLng;
  LatLng? _dropLatLng;
  bool _isLoading = false;
  List<Map<String, dynamic>> _searchResults = [];
  bool _showPickupSearch = false;
  bool _showDropSearch = false;
  FocusNode _pickupFocusNode = FocusNode();
  FocusNode _dropFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _appTheme.addListener(_onThemeChanged);
    _createCustomMarkers();
    _initializeLocation();
    
    // Set selected ride type from widget parameter
    _selectedRideType = widget.rideType;
    
    // Set initial text from widget parameters
    _pickupController.text = widget.pickupLocation ?? '';
    _dropController.text = widget.dropLocation ?? '';
    
    // Geocode locations if provided
    if (widget.pickupLocation != null && widget.dropLocation != null) {
      _geocodeLocations();
    } else {
      // Initialize map after a short delay to ensure locations are set
      Future.delayed(const Duration(milliseconds: 500), () {
        _initializeMap();
      });
    }
  }

  @override
  void dispose() {
    _appTheme.removeListener(_onThemeChanged);
    _mapController?.dispose();
    _pickupController.dispose();
    _dropController.dispose();
    _pickupFocusNode.dispose();
    _dropFocusNode.dispose();
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  Future<void> _initializeLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    _currentLocation = await Geolocator.getCurrentPosition();
    if (_currentLocation != null) {
      _pickupLatLng = LatLng(_currentLocation!.latitude, _currentLocation!.longitude);
      if (mounted) {
        setState(() {});
        _updateMapToCurrentLocation();
      }
    }
  }

  void _updateMapToCurrentLocation() {
    if (_currentLocation != null && _mapController != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(_currentLocation!.latitude, _currentLocation!.longitude),
        ),
      );
    }
  }

  Future<void> _createCustomMarkers() async {
    // Create custom bike marker
    _bikeMarker = await _createMarkerFromAsset('assets/bike1.png', 60);
    
    // Create custom car marker
    _carMarker = await _createMarkerFromAsset('assets/car1.png', 60);
    
    // Create custom auto marker
    _autoMarker = await _createMarkerFromAsset('assets/auto1.png', 60);
    
    // Update map after markers are created
    if (mounted) {
      setState(() {});
    }
  }

  Future<BitmapDescriptor> _createMarkerFromAsset(String assetPath, int size) async {
    try {
      final ui.Image image = await _loadImageFromAsset(assetPath);
      final ByteData? data = await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List bytes = data!.buffer.asUint8List();
      return BitmapDescriptor.fromBytes(bytes);
    } catch (e) {
      // Fallback to default marker if image not found
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
  }

  Future<ui.Image> _loadImageFromAsset(String assetPath) async {
    final ByteData data = await DefaultAssetBundle.of(context).load(assetPath);
    final ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    return frameInfo.image;
  }

  void _initializeMap() {
    // Clear existing markers and polylines
    _markers.clear();
    _polylines.clear();

    // Add markers for pickup and drop if they exist
    if (_pickupLatLng != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: _pickupLatLng!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Pickup Location'),
        ),
      );
    }

    if (_dropLatLng != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('drop'),
          position: _dropLatLng!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Drop Location'),
        ),
      );

      // Draw polyline between pickup and drop
      if (_pickupLatLng != null) {
        _drawPolyline(_pickupLatLng!, _dropLatLng!);
      }
    } else if (_pickupLatLng != null) {
      // If only pickup is set, center on pickup
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_pickupLatLng!, 14.0),
      );
    }

    // Add vehicle markers if both locations are set
    if (_pickupLatLng != null && _dropLatLng != null) {
      _addVehicleMarkers();
    }
  }

  void _drawPolyline(LatLng pickup, LatLng drop) {
    // Create a simple straight line for demonstration
    // In real app, use Google Directions API to get actual route
    _polylines.clear();
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('route'),
        points: [pickup, drop],
        color: Colors.black,
        width: 5,
        patterns: [],
      ),
    );
  }

  Future<void> _geocodeLocations() async {
    if (widget.pickupLocation != null && widget.dropLocation != null) {
      try {
        // Geocode pickup location
        final pickupUrl = Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(widget.pickupLocation!)}&key=$_apiKey',
        );
        final pickupResponse = await http.get(pickupUrl);
        final pickupData = json.decode(pickupResponse.body);
        
        if (pickupData['status'] == 'OK' && pickupData['results'].isNotEmpty) {
          final location = pickupData['results'][0]['geometry']['location'];
          _pickupLatLng = LatLng(location['lat'], location['lng']);
        }

        // Geocode drop location
        final dropUrl = Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(widget.dropLocation!)}&key=$_apiKey',
        );
        final dropResponse = await http.get(dropUrl);
        final dropData = json.decode(dropResponse.body);
        
        if (dropData['status'] == 'OK' && dropData['results'].isNotEmpty) {
          final location = dropData['results'][0]['geometry']['location'];
          _dropLatLng = LatLng(location['lat'], location['lng']);
        }

        if (mounted) {
          setState(() {});
          _initializeMap();
          
          // Move camera to show both locations
          if (_pickupLatLng != null && _dropLatLng != null) {
            Future.delayed(const Duration(milliseconds: 500), () {
              _mapController?.animateCamera(
                CameraUpdate.newLatLngBounds(
                  LatLngBounds(
                    southwest: LatLng(
                      _pickupLatLng!.latitude < _dropLatLng!.latitude ? _pickupLatLng!.latitude : _dropLatLng!.latitude,
                      _pickupLatLng!.longitude < _dropLatLng!.longitude ? _pickupLatLng!.longitude : _dropLatLng!.longitude,
                    ),
                    northeast: LatLng(
                      _pickupLatLng!.latitude > _dropLatLng!.latitude ? _pickupLatLng!.latitude : _dropLatLng!.latitude,
                      _pickupLatLng!.longitude > _dropLatLng!.longitude ? _pickupLatLng!.longitude : _dropLatLng!.longitude,
                    ),
                  ),
                  100,
                ),
              );
            });
          }
        }
      } catch (e) {
        print('Error geocoding locations: $e');
        // Fallback to current location if geocoding fails
        if (_currentLocation != null) {
          _pickupLatLng = LatLng(_currentLocation!.latitude, _currentLocation!.longitude);
          _initializeMap();
        }
      }
    }
  }

  void _addVehicleMarkers() {
    if (_pickupLatLng == null || _dropLatLng == null) return;

    // Calculate midpoint
    double midLat = (_pickupLatLng!.latitude + _dropLatLng!.latitude) / 2;
    double midLng = (_pickupLatLng!.longitude + _dropLatLng!.longitude) / 2;

    // Add bike markers around the route
    final List<LatLng> bikeLocations = [
      LatLng(midLat - 0.002, midLng - 0.002),
      LatLng(midLat + 0.002, midLng - 0.002),
      LatLng(midLat - 0.002, midLng + 0.002),
      LatLng(midLat + 0.002, midLng + 0.002),
    ];

    // Add car markers
    final List<LatLng> carLocations = [
      LatLng(midLat - 0.003, midLng),
      LatLng(midLat + 0.003, midLng),
      LatLng(midLat, midLng - 0.003),
    ];

    // Add auto markers
    final List<LatLng> autoLocations = [
      LatLng(midLat - 0.001, midLng - 0.001),
      LatLng(midLat + 0.001, midLng + 0.001),
      LatLng(midLat - 0.001, midLng + 0.001),
    ];

    // Add bike markers
    for (int i = 0; i < bikeLocations.length; i++) {
      _markers.add(
        Marker(
          markerId: MarkerId('bike_$i'),
          position: bikeLocations[i],
          icon: _bikeMarker ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          anchor: const Offset(0.5, 0.5),
          flat: true,
          rotation: 45.0 + (i * 30.0),
        ),
      );
    }

    // Add car markers
    for (int i = 0; i < carLocations.length; i++) {
      _markers.add(
        Marker(
          markerId: MarkerId('car_$i'),
          position: carLocations[i],
          icon: _carMarker ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          anchor: const Offset(0.5, 0.5),
          flat: true,
          rotation: 60.0 + (i * 25.0),
        ),
      );
    }

    // Add auto markers
    for (int i = 0; i < autoLocations.length; i++) {
      _markers.add(
        Marker(
          markerId: MarkerId('auto_$i'),
          position: autoLocations[i],
          icon: _autoMarker ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
          anchor: const Offset(0.5, 0.5),
          flat: true,
          rotation: 50.0 + (i * 35.0),
        ),
      );
    }
  }

  Future<void> _searchPlaces(String query, bool isPickup) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(query)}&key=$_apiKey';
      
      if (_currentLocation != null) {
        url += '&location=${_currentLocation!.latitude},${_currentLocation!.longitude}&radius=10000';
      }
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          setState(() {
            _searchResults = List<Map<String, dynamic>>.from(data['predictions'] ?? []);
            _isLoading = false;
          });
        } else {
          setState(() {
            _searchResults = [];
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _searchResults = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
      print('Error searching places: $e');
    }
  }

  Future<void> _selectPlace(Map<String, dynamic> prediction, bool isPickup) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final placeId = prediction['place_id'] as String?;
      if (placeId == null) return;
      
      final url = 'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$_apiKey';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final result = data['result'];
          final geometry = result['geometry'];
          final location = geometry['location'];
          final lat = location['lat'] as double;
          final lng = location['lng'] as double;
          final name = result['name'] as String? ?? prediction['description'] as String? ?? '';
          
          if (isPickup) {
            _pickupLatLng = LatLng(lat, lng);
            _pickupController.text = name;
            _showPickupSearch = false;
          } else {
            _dropLatLng = LatLng(lat, lng);
            _dropController.text = name;
            _showDropSearch = false;
          }
          
          // Clear search results
          _searchResults.clear();
          
          // Update map
          _initializeMap();
          
          // Move camera to show both locations
          if (_pickupLatLng != null && _dropLatLng != null) {
            _mapController?.animateCamera(
              CameraUpdate.newLatLngBounds(
                LatLngBounds(
                  southwest: LatLng(
                    _pickupLatLng!.latitude < _dropLatLng!.latitude ? _pickupLatLng!.latitude : _dropLatLng!.latitude,
                    _pickupLatLng!.longitude < _dropLatLng!.longitude ? _pickupLatLng!.longitude : _dropLatLng!.longitude,
                  ),
                  northeast: LatLng(
                    _pickupLatLng!.latitude > _dropLatLng!.latitude ? _pickupLatLng!.latitude : _dropLatLng!.latitude,
                    _pickupLatLng!.longitude > _dropLatLng!.longitude ? _pickupLatLng!.longitude : _dropLatLng!.longitude,
                  ),
                ),
                100,
              ),
            );
          } else if (_pickupLatLng != null) {
            _mapController?.animateCamera(
              CameraUpdate.newLatLngZoom(_pickupLatLng!, 14.0),
            );
          }
        }
      }
    } catch (e) {
      print('Error getting place details: $e');
    }

    setState(() {
      _isLoading = false;
      _pickupFocusNode.unfocus();
      _dropFocusNode.unfocus();
    });
  }

  void _swapLocations() {
    final tempText = _pickupController.text;
    _pickupController.text = _dropController.text;
    _dropController.text = tempText;

    final tempLatLng = _pickupLatLng;
    _pickupLatLng = _dropLatLng;
    _dropLatLng = tempLatLng;

    _initializeMap();
  }

  void _useCurrentLocation() async {
    if (_currentLocation != null) {
      setState(() {
        _pickupLatLng = LatLng(_currentLocation!.latitude, _currentLocation!.longitude);
        _pickupController.text = 'Current Location';
        _showPickupSearch = false;
      });
      
      // Reverse geocode to get address
      try {
        final url = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=${_currentLocation!.latitude},${_currentLocation!.longitude}&key=$_apiKey';
        final response = await http.get(Uri.parse(url));
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'OK' && data['results'].isNotEmpty) {
            final address = data['results'][0]['formatted_address'] as String?;
            if (address != null && address.isNotEmpty) {
              _pickupController.text = address;
            }
          }
        }
      } catch (e) {
        print('Error reverse geocoding: $e');
      }
      
      _initializeMap();
      _pickupFocusNode.unfocus();
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    // Initial camera position
    if (_pickupLatLng != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_pickupLatLng!, 14.0),
      );
    }
  }

  Map<String, dynamic> _getRideDetails(String rideType) {
    switch (rideType) {
      case 'Bike':
        return {
          'image': 'assets/bike1.png',
          'time': '2 Min',
          'passengers': '1',
          'price': '₹65',
          'icon': Icons.two_wheeler,
          'tagline': 'Ride Easy. Book Fast.',
        };
      case 'Auto':
        return {
          'image': 'assets/auto1.png',
          'time': '2 Min',
          'passengers': '3',
          'price': '₹90',
          'icon': Icons.airport_shuttle,
        };
      case 'Cab':
        return {
          'image': 'assets/car1.png',
          'time': '2 Min',
          'passengers': '4',
          'price': '₹180',
          'icon': Icons.directions_car,
        };
      case 'SUV':
        return {
          'image': 'assets/car1.png',
          'time': '2 Min',
          'passengers': '5',
          'price': '₹245',
          'icon': Icons.directions_car,
        };
      default:
        return {
          'image': 'assets/bike1.png',
          'time': '2 Min',
          'passengers': '1',
          'price': '₹65',
          'icon': Icons.two_wheeler,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Directionality(
      textDirection: _appTheme.textDirection,
      child: Scaffold(
        backgroundColor: _appTheme.backgroundColor,
        body: Stack(
          children: [
            // Map View with all features enabled
            GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: const CameraPosition(
                target: LatLng(17.4175, 78.4934),
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

            // Navigation Buttons
            Positioned(
              top: 260,
              left: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    _appTheme.rtlEnabled ? Icons.arrow_forward : Icons.arrow_back,
                    color: Colors.black,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            Positioned(
              top: 260,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(Icons.my_location, color: Colors.black),
                  onPressed: _updateMapToCurrentLocation,
                ),
              ),
            ),

            // Loading Overlay
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),

            // Ride Options Panel (always visible)
            DraggableScrollableSheet(
                initialChildSize: 0.62,
                minChildSize: 0.4,
                maxChildSize: 0.85,
                builder: (context, scrollController) {
                  return Container(
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

                        // Ride Options List
                        Expanded(
                          child: ListView(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            children: [
                              _buildRideOption('Bike'),
                              const SizedBox(height: 12),
                              _buildRideOption('Auto'),
                              const SizedBox(height: 12),
                              _buildRideOption('Cab'),
                              const SizedBox(height: 12),
                              _buildRideOption('SUV'),
                              const SizedBox(height: 20),

                              // Promotional Banner
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Transparent fares and zero hidden charges - only on Pikkar.',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),

                              const SizedBox(height: 20),
                            ],
                          ),
                        ),

                        // Payment Method and Book Ride Button in same row
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
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _appTheme.textColor,
                                      ),
                                    ),
                                    Text(
                                      ' | ',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: _appTheme.textGrey,
                                      ),
                                    ),
                                    Text(
                                      'Direct pay to Driver',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: _appTheme.textColor,
                                      ),
                                    ),
                                  ],
                                ),
                                // Book Ride Button (Right)
                                ElevatedButton(
                                  onPressed: () {
                                    // Navigate to Finding Driver screen
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => FindingDriverScreen(
                                          pickupLocation: widget.pickupLocation ?? 'Pickup Location',
                                          dropLocation: widget.dropLocation ?? 'Drop Location',
                                          rideType: _selectedRideType,
                                          pickupLatLng: _pickupLatLng,
                                          dropLatLng: _dropLatLng,
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _appTheme.brandRed,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    'Book Ride',
                                    style: const TextStyle(
                                      color: Colors.white,
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
    );
  }

  Widget _buildRideOption(String rideType) {
    final details = _getRideDetails(rideType);
    final isSelected = _selectedRideType == rideType;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedRideType = rideType;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                ]
              : null,
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
                  details['image'] as String,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      details['icon'] as IconData,
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
                    '${details['time']} | ${details['passengers']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: _appTheme.textGrey,
                    ),
                  ),
                  if (details['tagline'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      details['tagline'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        color: _appTheme.textGrey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Price
            Text(
              details['price'] as String,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _appTheme.brandRed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}