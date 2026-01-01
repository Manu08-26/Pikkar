// import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/app_theme.dart';
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
  final List<String> _rideTypes = ['Bike', 'Auto', 'Cab', 'SUV'];
  PageController? _rideTypePageController;
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

    if (!_rideTypes.contains(_selectedRideType)) {
      _rideTypes.insert(0, _selectedRideType);
    }
    final initialIndex =
        _rideTypes.indexOf(_selectedRideType).clamp(0, _rideTypes.length - 1);
    _rideTypePageController ??= PageController(
      initialPage: initialIndex,
      viewportFraction: 0.46,
    );
    
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
    _rideTypePageController?.dispose();
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
          'image': 'assets/All Icons Set-Pikkar_Bike.png',
          'time': '2 Min',
         
          'price': '₹65',
          'icon': Icons.two_wheeler,
          'tagline': 'Ride Easy. Book Fast.',
        };
      case 'Auto':
        return {
          'image': 'assets/All Icons Set-Pikkar_Auto.png',
          'time': '2 Min',
         
          'price': '₹90',
          'icon': Icons.airport_shuttle,
        };
      case 'Cab':
        return {
          'image': 'assets/All Icons Set-Pikkar_Cab.png',
          'time': '2 Min',
         
          'price': '₹180',
          'icon': Icons.directions_car,
        };
      case 'SUV':
        return {
          'image': 'assets/All Icons Set-Pikkar_Parcel Bike.png',
          'time': '2 Min',
        
          'price': '₹245',
          'icon': Icons.directions_car,
        };
      default:
        return {
          'image': 'assets/All Icons Set-Pikkar_Parcel Bike.png',
          'time': '2 Min',
         
          'price': '₹65',
          'icon': Icons.two_wheeler,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    // Hot-reload safe: when new fields are added, initState doesn't rerun.
    _rideTypePageController ??= PageController(
      initialPage: _rideTypes.indexOf(_selectedRideType).clamp(0, _rideTypes.length - 1),
      viewportFraction: 0.46,
    );

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
              top: 340,
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
              top: 340,
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

            // Ride Options Panel (always visible) - fixed layout, no overflow
            // Fixed Bottom Sheet (not draggable)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.48,
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
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      // Drag Handle (non-functional, just visual)
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: _appTheme.textGrey,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      // Carousel content (scrollable)
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
                          child: Column(
                            children: [
                              SizedBox(
                                height: MediaQuery.of(context).size.height * 0.22,
                                child: PageView.builder(
                                  controller: _rideTypePageController,
                                  itemCount: _rideTypes.length,
                                  padEnds: true,
                                  clipBehavior: Clip.none,
                                  physics: const BouncingScrollPhysics(),
                                  onPageChanged: (index) {
                                    setState(() {
                                      _selectedRideType = _rideTypes[index];
                                    });
                                  },
                                  itemBuilder: (context, index) {
                                    final rideType = _rideTypes[index];
                                    return AnimatedBuilder(
                                      animation: _rideTypePageController!,
                                      builder: (context, child) {
                                        final ctrl = _rideTypePageController!;
                                        final currentPage = ctrl.hasClients
                                            ? (ctrl.page ?? ctrl.initialPage.toDouble())
                                            : ctrl.initialPage.toDouble();

                                        final distance = (currentPage - index).abs();
                                        final scale =
                                            (1.02 - (distance * 0.20)).clamp(0.82, 1.02);
                                        final opacity =
                                            (1.0 - (distance * 0.45)).clamp(0.55, 1.0);

                                        return Transform.scale(
                                          scale: scale,
                                          child: Opacity(opacity: opacity, child: child),
                                        );
                                      },
                                      child: _buildRideCarouselCard(
                                        rideType,
                                        isSelected: _selectedRideType == rideType,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Promotional Banner (fixed)
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

                      // Payment + Book Ride (fixed)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        color: Colors.white,
                        child: SafeArea(
                          top: false,
                          child: Row(
                            children: [
                              Expanded(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Cash',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w400,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      width: 1,
                                      height: 26,
                                      color: Colors.black.withOpacity(0.28),
                                    ),
                                    const SizedBox(width: 12),
                                    Flexible(
                                      child: Text(
                                        'Direct pay to Driver',
                                        style: TextStyle(
                                          color: Colors.black.withOpacity(0.8),
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              SizedBox(
                                height: 40,
                                width: 150,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => FindingDriverScreen(
                                          pickupLocation:
                                              widget.pickupLocation ?? 'Pickup Location',
                                          dropLocation:
                                              widget.dropLocation ?? 'Drop Location',
                                          rideType: _selectedRideType,
                                          pickupLatLng: _pickupLatLng,
                                          dropLatLng: _dropLatLng,
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _appTheme.brandRed,
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(40),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Text(
                                    'Book Ride',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
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
                ),
              ),
            ),
          
          ],
        ),
      ),
    );
  }

  Widget _buildRideCarouselCard(String rideType, {required bool isSelected}) {
    final details = _getRideDetails(rideType);
    final size = isSelected ? 150.0 : 130.0;

    return GestureDetector(
      onTap: () {
        final index = _rideTypes.indexOf(rideType);
        if (index == -1) return;
        _rideTypePageController?.animateToPage(
          index,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
        setState(() {
          _selectedRideType = rideType;
        });
      },
      child: Container(
        width: size,
        height: size,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: AspectRatio(
          aspectRatio: 1.0, // Force 1:1 ratio (perfect square)
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: Colors.black.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isSelected ? 0.20 : 0.08),
                  blurRadius: isSelected ? 12 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: isSelected ? 60 : 50,
                  height: isSelected ? 60 : 50,
                  child: Image.asset(
                    details['image'] as String,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        details['icon'] as IconData,
                        color: _appTheme.brandRed,
                        size: isSelected ? 40 : 35,
                      );
                    },
                  ),
                ),
                SizedBox(height: isSelected ? 8 : 6),
                Text(
                  rideType,
                  style: TextStyle(
                    fontSize: isSelected ? 14 : 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black.withOpacity(0.9),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      details['price'] as String,
                      style: TextStyle(
                        fontSize: isSelected ? 20 : 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${details['time']}',
                      style: TextStyle(
                        color: _appTheme.textGrey,
                        fontSize: isSelected ? 13 : 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}