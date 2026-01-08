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
import 'package:pikkar/core/models/api_models.dart';
import 'package:pikkar/core/services/api_service.dart';

import 'drop_screen.dart';


class RideBookingScreen extends StatefulWidget {
  final String? pickupLocation;
  final String? dropLocation;
  final String rideType;
  final LatLng? pickupLatLng;
  final LatLng? dropLatLng;

  const RideBookingScreen({
    super.key,
    this.pickupLocation,
    this.dropLocation,
    required this.rideType,
    this.pickupLatLng,
    this.dropLatLng,
  });

  @override
  State<RideBookingScreen> createState() => _RideBookingScreenState();
}

class _RideBookingScreenState extends State<RideBookingScreen> {
  final AppTheme _appTheme = AppTheme();
  GoogleMapController? _mapController;
  late String _selectedRideType; // Bike, Auto, Cab, SUV, Prime Cab
  List<String> _rideTypes = ['Bike', 'Auto', 'Cab', 'SUV'];
  PageController? _rideTypePageController;
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};
  BitmapDescriptor? _bikeMarker;
  BitmapDescriptor? _carMarker;
  BitmapDescriptor? _autoMarker;
  double _mapBottomPadding = 0;
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropController = TextEditingController();
  String? _pickupName;
  String? _dropName;
  static const String _apiKey = 'AIzaSyC-lm1swnNq-IAekwxiH9vyLwcOc2TNd3E';
  Position? _currentLocation;
  LatLng? _pickupLatLng;
  LatLng? _dropLatLng;
  bool _isLoading = false;
  List<Map<String, dynamic>> _searchResults = [];
  // ignore: unused_field
  bool _showPickupSearch = false;
  // ignore: unused_field
  bool _showDropSearch = false;
  FocusNode _pickupFocusNode = FocusNode();
  FocusNode _dropFocusNode = FocusNode();
  bool _loadingVehicleTypes = false;
  Map<String, VehicleType> _apiVehicleByName = {};
  bool _vehicleTypesRequested = false;
  String? _vehicleTypesError;

  @override
  void initState() {
    super.initState();
    _appTheme.addListener(_onThemeChanged);
    _createCustomMarkers();
    _initializeLocation();
    
    // Set selected ride type from widget parameter
    _selectedRideType = _rideTypes.contains(widget.rideType) ? widget.rideType : _rideTypes.first;
    _loadVehicleTypes(); // fetch live pricing from backend
    final initialIndex =
        _rideTypes.indexOf(_selectedRideType).clamp(0, _rideTypes.length - 1);
    _rideTypePageController ??= PageController(
      initialPage: initialIndex,
      viewportFraction: 0.46,
    );
    
    // Set initial text from widget parameters
    _pickupController.text = widget.pickupLocation ?? '';
    _dropController.text = widget.dropLocation ?? '';
    _pickupName = widget.pickupLocation ?? _pickupController.text;
    _dropName = widget.dropLocation ?? _dropController.text;

    // If lat/lng provided, use them directly
    if (widget.pickupLatLng != null) {
      _pickupLatLng = widget.pickupLatLng;
    }
    if (widget.dropLatLng != null) {
      _dropLatLng = widget.dropLatLng;
    }

    if (_pickupLatLng != null && _dropLatLng != null) {
      // We already have coordinates; initialize map immediately
      Future.delayed(const Duration(milliseconds: 200), () {
        _initializeMap();
      });
    } else if (widget.pickupLocation != null && widget.dropLocation != null) {
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

  Future<void> _loadVehicleTypes() async {
    if (_loadingVehicleTypes) return;
    _vehicleTypesRequested = true;
    setState(() => _loadingVehicleTypes = true);
    try {
      final vehicles = await PikkarApi.vehicleTypes.getActive();

      if (!mounted) return;
      setState(() {
        _vehicleTypesError = null;
        _apiVehicleByName = {for (final v in vehicles) v.name: v};
        if (vehicles.isNotEmpty) {
          _rideTypes = vehicles.map((v) => v.name).toList();
        }

        // Prefer the incoming ride type (if present in API list)
        if (_rideTypes.contains(widget.rideType)) {
          _selectedRideType = widget.rideType;
        } else if (!_rideTypes.contains(_selectedRideType)) {
          _selectedRideType = _rideTypes.isNotEmpty ? _rideTypes.first : 'Bike';
        }

        // Recreate controller so the list highlights correct selection
        _rideTypePageController?.dispose();
        _rideTypePageController = null;
        _loadingVehicleTypes = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _vehicleTypesError = 'Unable to load live prices';
        _loadingVehicleTypes = false;
      });
      debugPrint('Vehicle types API error: $e');
    }
  }

  String _assetForRideName(String name) {
    final n = name.toLowerCase();
    if (n.contains('bike')) return 'assets/All Icons Set-Pikkar_Bike.png';
    if (n.contains('auto')) return 'assets/All Icons Set-Pikkar_Auto.png';
    if (n.contains('cab') || n.contains('car') || n.contains('sedan')) {
      return 'assets/All Icons Set-Pikkar_Cab.png';
    }
    if (n.contains('suv')) return 'assets/All Icons Set-Pikkar_Cab.png';
    if (n.contains('parcel')) return 'assets/All Icons Set-Pikkar_Parcel Bike.png';
    return 'assets/All Icons Set-Pikkar_Bike.png';
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

void _onEditPickup() async {
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
        builder: (_) => DropScreen(rideType: widget.rideType),
    ),
  );

  if (result != null && result is Map) {
    setState(() {
      _pickupLatLng = result['latLng'];
      _pickupName = result['name'];
      _pickupController.text = result['name'];
    });
    _redrawRoute();
  }
}

Future<void> _redrawRoute() async {
  if (_pickupLatLng == null || _dropLatLng == null) return;

  setState(() {
    _polylines.clear();
    _markers.clear();
  });

  await _initializeMap(); // THIS is important
}


void _onEditDrop() async {
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
        builder: (_) => DropScreen(rideType: widget.rideType),
    ),
  );

  if (result != null && result is Map) {
    setState(() {
      _dropLatLng = result['latLng'];
      _dropName = result['name'];
      _dropController.text = result['name'];
    });
    _redrawRoute();
  }
}



  // ignore: unused_element
  Widget _locationChip({
    required String label,
    required Color color,
    required VoidCallback onEdit,
  }) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.circle,
                  color: Colors.white,
                  size: 8,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, size: 18, color: Colors.black87),
              onPressed: onEdit,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
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

  Future<void> _initializeMap() async {
    print('DEBUG: _initializeMap called');
    print('DEBUG: _pickupLatLng = $_pickupLatLng');
    print('DEBUG: _dropLatLng = $_dropLatLng');
    
    // Clear existing markers and polylines (we'll call setState after rebuild)
    _markers.clear();
    _polylines.clear();
   

    // Prepare custom label markers
    BitmapDescriptor? pickupLabelIcon;
    BitmapDescriptor? dropLabelIcon;

    if (_pickupLatLng != null) {
      pickupLabelIcon = await _buildLabelMarker(
        _pickupName ?? 'Pickup location',
        Colors.green,
      );
      print('DEBUG: Created pickup marker');
    }

    if (_dropLatLng != null) {
      dropLabelIcon = await _buildLabelMarker(
        _dropName ?? 'Drop location',
        Colors.red,
      );
      print('DEBUG: Created drop marker');
    }

    // Add markers for pickup and drop if they exist
    if (_pickupLatLng != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: _pickupLatLng!,
          icon: pickupLabelIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        anchor: const Offset(0.5, 1.0),

          zIndex: 10,
          onTap: _onEditPickup,
        ),
      );
      print('DEBUG: Added pickup marker to set');
    }

    if (_dropLatLng != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('drop'),
          position: _dropLatLng!,
          icon: dropLabelIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
         anchor: const Offset(0.5, 1.0),

          zIndex: 10,
          onTap: _onEditDrop,
        ),
      );
      print('DEBUG: Added drop marker to set');

      // Draw polyline between pickup and drop
      if (_pickupLatLng != null) {
        print('DEBUG: About to call _drawPolyline');
        await _drawPolyline(_pickupLatLng!, _dropLatLng!);
        print('DEBUG: _drawPolyline completed');
      }
    } else if (_pickupLatLng != null) {
      // If only pickup is set, center on pickup
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_pickupLatLng!, 14.0),
      );
      print('DEBUG: Only pickup set, centered camera');
    }

    // Add vehicle markers if both locations are set
    if (_pickupLatLng != null && _dropLatLng != null) {
      _addVehicleMarkers();
      // Fit both points within view with padding so chips/bottom sheet don't overlap
      Future.delayed(const Duration(milliseconds: 150), () {
        if (!mounted) return;
        setState(() {
          _mapBottomPadding = 420;
        });
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
            120,
          ),
        );
      });
    }

    if (mounted) {
      setState(() {});
    }
  }
  Future<void> _drawPolyline(LatLng pickup, LatLng drop) async {
    print('DEBUG: _drawPolyline called with pickup: $pickup, drop: $drop');
    bool added = false;
    try {
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${pickup.latitude},${pickup.longitude}'
        '&destination=${drop.latitude},${drop.longitude}'
        '&mode=driving'
        '&key=$_apiKey',
      );

      print('DEBUG: Making API call to: ${uri.toString().replaceAll(_apiKey, 'API_KEY')}');
      final response = await http.get(uri);
      print('DEBUG: API response status: ${response.statusCode}');
      
      final data = response.statusCode == 200 ? json.decode(response.body) : null;
      print('DEBUG: API response status field: ${data?['status']}');
      
      if (data != null && data['status'] == 'OK') {
        final routes = data['routes'] as List?;
        print('DEBUG: Routes count: ${routes?.length ?? 0}');
        
        String? overview;
        if (routes != null && routes.isNotEmpty) {
          overview = routes.first['overview_polyline']?['points'] as String?;
        }
        
        final decoded = overview != null ? _decodePolyline(overview) : <LatLng>[];
        print('DEBUG: Decoded points count: ${decoded.length}');

        if (decoded.isNotEmpty && mounted) {
          setState(() {
            _polylines.clear();
            _polylines.add(
              Polyline(
                polylineId: const PolylineId('route'),
                points: decoded,
                color: Colors.black,
                width: 7,
                jointType: JointType.round,
                startCap: Cap.roundCap,
                endCap: Cap.roundCap,
                geodesic: true,
              ),
            );
          });
          added = true;
          print('DEBUG: Added decoded polyline with ${decoded.length} points');
          return; // Success - exit early
        }
      } else if (data != null) {
        print('DEBUG: API error - status: ${data['status']}, message: ${data['error_message'] ?? 'none'}');
      }
    } catch (e) {
      print('DEBUG: Exception in _drawPolyline: $e');
      // ignore and fall back to straight line
    }

    // Fallback: draw straight line if directions failed or returned empty
    if (!added && mounted) {
      print('DEBUG: Adding fallback straight line polyline');
      setState(() {
        _polylines.clear();
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: [pickup, drop],
            color: Colors.black,
            width: 6,
            jointType: JointType.round,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            geodesic: true,
          ),
        );
      });
      print('DEBUG: Fallback polyline added. Total polylines: ${_polylines.length}');
    }
    print('DEBUG: _drawPolyline completed. Total polylines: ${_polylines.length}');
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      poly.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return poly;
  }

  Future<BitmapDescriptor> _buildLabelMarker(String text, Color tagColor) async {
    const double padding = 12;
    const double tagSize = 24;
    const double borderRadius = 12;
    const double maxWidth = 220;

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);

    // Measure text
    final ui.ParagraphBuilder pb = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textDirection: TextDirection.ltr,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    )..pushStyle(ui.TextStyle(color: Colors.black))
     ..addText(text);
    final ui.Paragraph paragraph = pb.build()
      ..layout(const ui.ParagraphConstraints(width: maxWidth));
    final double textWidth = paragraph.maxIntrinsicWidth.clamp(0, maxWidth);
    final double textHeight = paragraph.height;

    final double width = padding * 2 + textWidth + tagSize;
    final double height = padding * 2 + textHeight;

    final RRect bubble = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, width, height),
      const Radius.circular(borderRadius),
    );

    // Bubble
    final Paint bubblePaint = Paint()..color = Colors.white;
    canvas.drawRRect(bubble, bubblePaint);

    // Shadow
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4);
    canvas.drawRRect(bubble.shift(const Offset(0, 2)), shadowPaint);

    // Text
    canvas.drawParagraph(
      paragraph,
      Offset(padding, (height - textHeight) / 2),
    );

    // Tag with pencil
    final Rect tagRect = Rect.fromLTWH(width - tagSize, 0, tagSize, height);
    final RRect tag = RRect.fromRectAndRadius(tagRect, const Radius.circular(borderRadius));
    final Paint tagPaint = Paint()..color = tagColor;
    canvas.drawRRect(tag, tagPaint);

    // Pencil icon (simple line drawing)
    final Paint pencilPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    final double px = width - tagSize / 2;
    final double py = height / 2;
    canvas.drawLine(Offset(px - 6, py + 6), Offset(px + 6, py - 6), pencilPaint);
    canvas.drawLine(Offset(px - 2, py + 6), Offset(px + 6, py - 2), pencilPaint);

    // Pointer triangle
    final Path pointer = Path()
      ..moveTo(width / 2 - 8, height)
      ..lineTo(width / 2 + 8, height)
      ..lineTo(width / 2, height + 12)
      ..close();
    canvas.drawPath(pointer, Paint()..color = Colors.white);
    canvas.drawPath(
      pointer.shift(const Offset(0, 1)),
      Paint()
        ..color = Colors.black.withOpacity(0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    final ui.Image image = await recorder.endRecording().toImage(
          width.ceil(),
          (height + 12).ceil(),
        );
    final ByteData? data = await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List bytes = data!.buffer.asUint8List();
    return BitmapDescriptor.fromBytes(bytes);
  }

  // void _showInfoWindows() {
  //   if (_mapController == null) return;
  //   if (_pickupLatLng != null) {
  //     _mapController!.showMarkerInfoWindow(const MarkerId('pickup'));
  //   }
  //   if (_dropLatLng != null) {
  //     _mapController!.showMarkerInfoWindow(const MarkerId('drop'));
  //   }
  // }

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

  // ignore: unused_element
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

  // ignore: unused_element
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

  // ignore: unused_element
  void _swapLocations() {
    final tempText = _pickupController.text;
    _pickupController.text = _dropController.text;
    _dropController.text = tempText;

    final tempLatLng = _pickupLatLng;
    _pickupLatLng = _dropLatLng;
    _dropLatLng = tempLatLng;

    _initializeMap();
  }

  // ignore: unused_element
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
    setState(() {
      _mapBottomPadding = 420;
    });
   // Future.delayed(const Duration(milliseconds: 150), _showInfoWindows);
  }

  /// Navigate to DropScreen to add a stop location
  // ignore: unused_element
  void _showAddStopSheet() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DropScreen(
          rideType: widget.rideType,
          enableParcelDropDetails: false,
        ),
      ),
    );

    if (result != null && result is Map) {
      final stopLatLng = result['latLng'] as LatLng?;
      final stopName = result['name'] as String?;
      
      if (stopLatLng != null && stopName != null) {
        // Add stop between pickup and drop
        // For now, we'll show a success message
        // You can implement multi-stop routing logic here
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Stop added: $stopName'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        
        // TODO: Implement multi-stop routing
        // You would store stops in a list and update the route polyline
        // to go: pickup -> stop1 -> stop2 -> ... -> drop
      }
    }
  }

  Map<String, dynamic> _getRideDetails(String rideType) {
    final apiVehicle = _apiVehicleByName[rideType];
    final apiPrice = apiVehicle != null ? '₹${apiVehicle.baseFare.toStringAsFixed(0)}' : null;
    final apiSeats = apiVehicle != null
        ? '${apiVehicle.capacity} ${apiVehicle.capacity == 1 ? 'seat' : 'seats'}'
        : null;
    // No demo fallback prices. If API isn't loaded, show placeholders.
    return {
      'image': _assetForRideName(rideType),
      'time': '2 min',
      'passengers': apiSeats ?? '—',
      'price': apiPrice ?? (_loadingVehicleTypes ? '...' : '—'),
      'icon': Icons.directions_car,
    };
  }

  @override
  Widget build(BuildContext context) {
    // Hot-reload safe: initState won't rerun, so ensure we fetch vehicles at least once.
    if (!_vehicleTypesRequested && !_loadingVehicleTypes) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_loadingVehicleTypes) _loadVehicleTypes();
      });
    }

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
              padding: EdgeInsets.only(bottom: _mapBottomPadding),
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
              top: 270,
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
              top: 270,
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

            // Add Stops button (overlay near location button)
            // Positioned(
            //   right: 16,
            //   bottom: 220,
            //   child: ElevatedButton.icon(
            //     onPressed: _showAddStopSheet,
            //     icon: const Icon(Icons.add, color: Colors.black, size: 18),
            //     label: const Text(
            //       'Add stops',
            //       style: TextStyle(
            //         color: Colors.black,
            //         fontWeight: FontWeight.w600,
            //         fontSize: 14,
            //       ),
            //     ),
            //     style: ElevatedButton.styleFrom(
            //       backgroundColor: Colors.white,
            //       elevation: 4,
            //       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            //       shape: RoundedRectangleBorder(
            //         borderRadius: BorderRadius.circular(24),
            //       ),
            //       shadowColor: Colors.black.withOpacity(0.2),
            //     ),
            //   ),
            // ),

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
                height: MediaQuery.of(context).size.height * 0.55,
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
                        child: RefreshIndicator(
                          color: _appTheme.brandRed,
                          onRefresh: _loadVehicleTypes,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
                            child: Column(
                              children: [
                                if (_vehicleTypesError != null)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    margin: const EdgeInsets.only(bottom: 10),
                                    decoration: BoxDecoration(
                                      color: _appTheme.brandRed.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _appTheme.brandRed.withOpacity(0.2),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.error_outline, color: _appTheme.brandRed),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            _vehicleTypesError!,
                                            style: TextStyle(color: _appTheme.textColor),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: _loadVehicleTypes,
                                          child: const Text('Retry'),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (_loadingVehicleTypes)
                                  const Padding(
                                    padding: EdgeInsets.only(bottom: 10),
                                    child: LinearProgressIndicator(minHeight: 2),
                                  ),
                                ..._rideTypes.map((rideType) {
                                  return _buildRideListCard(
                                    rideType,
                                    isSelected: _selectedRideType == rideType,
                                  );
                                }),
                              ],
                            ),
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
                            fontSize: 10,
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
                                        'Pay to Driver',
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
                                height: 60,
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
                                          vehicle: _apiVehicleByName[_selectedRideType],
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

  // ignore: unused_element
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

  Widget _buildRideListCard(String rideType, {required bool isSelected}) {
    final details = _getRideDetails(rideType);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRideType = rideType;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        margin: EdgeInsets.only(
          bottom: isSelected ? 10 : 8,
          left: isSelected ? 0 : 4,
          right: isSelected ? 0 : 4,
        ),
        padding: EdgeInsets.all(isSelected ? 8 : 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: _appTheme.brandRed, width: 1)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.1 : 0.05),
              blurRadius: isSelected ? 10 : 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Red bar indicator on the left (only for selected)
            if (isSelected)
              Container(
                width: 4,
                height: 36,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: _appTheme.brandRed,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            
            // Vehicle Image
            Container(
              width: isSelected ? 64 : 56,
              height: isSelected ? 64 : 56,
              padding: const EdgeInsets.all(6),
              child: Image.asset(
                details['image'] as String,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    details['icon'] as IconData,
                    color: _appTheme.brandRed,
                    size: isSelected ? 36 : 32,
                  );
                },
              ),
            ),
            
            SizedBox(width: isSelected ? 14 : 12),
            
            // Vehicle Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rideType,
                    style: TextStyle(
                      fontSize: isSelected ? 17 : 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${details['time']} · ${details['passengers'] ?? '1 seat'}',
                    style: TextStyle(
                      fontSize: isSelected ? 13 : 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            
            // Price
            Text(
              details['price'] as String,
              style: TextStyle(
                fontSize: isSelected ? 22 : 20,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

}
// import 'dart:typed_data';

// import 'dart:ui' as ui;
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:http/http.dart' as http;
// import 'package:geolocator/geolocator.dart';
// import '../../../core/theme/app_theme.dart';
// import 'finding_driver_screen.dart';


// class RideBookingScreen extends StatefulWidget {
//   final String? pickupLocation;
//   final String? dropLocation;
//   final String rideType;

//   const RideBookingScreen({
//     super.key,
//     this.pickupLocation,
//     this.dropLocation,
//     required this.rideType,
//   });

//   @override
//   State<RideBookingScreen> createState() => _RideBookingScreenState();
// }

// class _RideBookingScreenState extends State<RideBookingScreen> {
//   final AppTheme _appTheme = AppTheme();
//   GoogleMapController? _mapController;
//   late String _selectedRideType; // Bike, Auto, Cab, SUV, Prime Cab
//   final List<String> _rideTypes = ['Bike', 'Auto', 'Cab', 'SUV'];
//   PageController? _rideTypePageController;
//   final Set<Polyline> _polylines = {};
//   final Set<Marker> _markers = {};
//   BitmapDescriptor? _bikeMarker;
//   BitmapDescriptor? _carMarker;
//   BitmapDescriptor? _autoMarker;
//   final TextEditingController _pickupController = TextEditingController();
//   final TextEditingController _dropController = TextEditingController();
//   static const String _apiKey = 'AIzaSyC-lm1swnNq-IAekwxiH9vyLwcOc2TNd3E';
//   Position? _currentLocation;
//   LatLng? _pickupLatLng;
//   LatLng? _dropLatLng;
//   bool _isLoading = false;
//   List<Map<String, dynamic>> _searchResults = [];
//   bool _showPickupSearch = false;
//   bool _showDropSearch = false;
//   FocusNode _pickupFocusNode = FocusNode();
//   FocusNode _dropFocusNode = FocusNode();

//   @override
//   void initState() {
//     super.initState();
//     _appTheme.addListener(_onThemeChanged);
//     _createCustomMarkers();
//     _initializeLocation();
    
//     // Set selected ride type from widget parameter
//     _selectedRideType = widget.rideType;

//     if (!_rideTypes.contains(_selectedRideType)) {
//       _rideTypes.insert(0, _selectedRideType);
//     }
//     final initialIndex =
//         _rideTypes.indexOf(_selectedRideType).clamp(0, _rideTypes.length - 1);
//     _rideTypePageController ??= PageController(
//       initialPage: initialIndex,
//       viewportFraction: 0.46,
//     );
    
//     // Set initial text from widget parameters
//     _pickupController.text = widget.pickupLocation ?? '';
//     _dropController.text = widget.dropLocation ?? '';
    
//     // Geocode locations if provided
//     if (widget.pickupLocation != null && widget.dropLocation != null) {
//       _geocodeLocations();
//     } else {
//       // Initialize map after a short delay to ensure locations are set
//       Future.delayed(const Duration(milliseconds: 500), () {
//         _initializeMap();
//       });
//     }
//   }

//   @override
//   void dispose() {
//     _appTheme.removeListener(_onThemeChanged);
//     _mapController?.dispose();
//     _rideTypePageController?.dispose();
//     _pickupController.dispose();
//     _dropController.dispose();
//     _pickupFocusNode.dispose();
//     _dropFocusNode.dispose();
//     super.dispose();
//   }

//   void _onThemeChanged() {
//     setState(() {});
//   }

//   Future<void> _initializeLocation() async {
//     bool serviceEnabled;
//     LocationPermission permission;

//     serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       return;
//     }

//     permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         return;
//       }
//     }

//     if (permission == LocationPermission.deniedForever) {
//       return;
//     }

//     _currentLocation = await Geolocator.getCurrentPosition();
//     if (_currentLocation != null) {
//       _pickupLatLng = LatLng(_currentLocation!.latitude, _currentLocation!.longitude);
//       if (mounted) {
//         setState(() {});
//         _updateMapToCurrentLocation();
//       }
//     }
//   }

//   void _updateMapToCurrentLocation() {
//     if (_currentLocation != null && _mapController != null) {
//       _mapController?.animateCamera(
//         CameraUpdate.newLatLng(
//           LatLng(_currentLocation!.latitude, _currentLocation!.longitude),
//         ),
//       );
//     }
//   }

//   Future<void> _createCustomMarkers() async {
//     // Create custom bike marker
//     _bikeMarker = await _createMarkerFromAsset('assets/bike1.png', 60);
    
//     // Create custom car marker
//     _carMarker = await _createMarkerFromAsset('assets/car1.png', 60);
    
//     // Create custom auto marker
//     _autoMarker = await _createMarkerFromAsset('assets/auto1.png', 60);
    
//     // Update map after markers are created
//     if (mounted) {
//       setState(() {});
//     }
//   }

//   Future<BitmapDescriptor> _createMarkerFromAsset(String assetPath, int size) async {
//     try {
//       final ui.Image image = await _loadImageFromAsset(assetPath);
//       final ByteData? data = await image.toByteData(format: ui.ImageByteFormat.png);
//       final Uint8List bytes = data!.buffer.asUint8List();
//       return BitmapDescriptor.fromBytes(bytes);
//     } catch (e) {
//       // Fallback to default marker if image not found
//       return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
//     }
//   }

//   Future<ui.Image> _loadImageFromAsset(String assetPath) async {
//     final ByteData data = await DefaultAssetBundle.of(context).load(assetPath);
//     final ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
//     final ui.FrameInfo frameInfo = await codec.getNextFrame();
//     return frameInfo.image;
//   }

//   void _initializeMap() {
//     // Clear existing markers and polylines
//     _markers.clear();
//     _polylines.clear();

//     // Add markers for pickup and drop if they exist
//     if (_pickupLatLng != null) {
//       _markers.add(
//         Marker(
//           markerId: const MarkerId('pickup'),
//           position: _pickupLatLng!,
//           icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
//           infoWindow: const InfoWindow(title: 'Pickup Location'),
//         ),
//       );
//     }

//     if (_dropLatLng != null) {
//       _markers.add(
//         Marker(
//           markerId: const MarkerId('drop'),
//           position: _dropLatLng!,
//           icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
//           infoWindow: const InfoWindow(title: 'Drop Location'),
//         ),
//       );

//       // Draw polyline between pickup and drop
//       if (_pickupLatLng != null) {
//         _drawPolyline(_pickupLatLng!, _dropLatLng!);
//       }
//     } else if (_pickupLatLng != null) {
//       // If only pickup is set, center on pickup
//       _mapController?.animateCamera(
//         CameraUpdate.newLatLngZoom(_pickupLatLng!, 14.0),
//       );
//     }

//     // Add vehicle markers if both locations are set
//     if (_pickupLatLng != null && _dropLatLng != null) {
//       _addVehicleMarkers();
//     }
//   }

//   void _drawPolyline(LatLng pickup, LatLng drop) {
//     // Create a simple straight line for demonstration
//     // In real app, use Google Directions API to get actual route
//     _polylines.clear();
//     _polylines.add(
//       Polyline(
//         polylineId: const PolylineId('route'),
//         points: [pickup, drop],
//         color: Colors.black,
//         width: 5,
//         patterns: [],
//       ),
//     );
//   }

//   Future<void> _geocodeLocations() async {
//     if (widget.pickupLocation != null && widget.dropLocation != null) {
//       try {
//         // Geocode pickup location
//         final pickupUrl = Uri.parse(
//           'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(widget.pickupLocation!)}&key=$_apiKey',
//         );
//         final pickupResponse = await http.get(pickupUrl);
//         final pickupData = json.decode(pickupResponse.body);
        
//         if (pickupData['status'] == 'OK' && pickupData['results'].isNotEmpty) {
//           final location = pickupData['results'][0]['geometry']['location'];
//           _pickupLatLng = LatLng(location['lat'], location['lng']);
//         }

//         // Geocode drop location
//         final dropUrl = Uri.parse(
//           'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(widget.dropLocation!)}&key=$_apiKey',
//         );
//         final dropResponse = await http.get(dropUrl);
//         final dropData = json.decode(dropResponse.body);
        
//         if (dropData['status'] == 'OK' && dropData['results'].isNotEmpty) {
//           final location = dropData['results'][0]['geometry']['location'];
//           _dropLatLng = LatLng(location['lat'], location['lng']);
//         }

//         if (mounted) {
//           setState(() {});
//           _initializeMap();
          
//           // Move camera to show both locations
//           if (_pickupLatLng != null && _dropLatLng != null) {
//             Future.delayed(const Duration(milliseconds: 500), () {
//               _mapController?.animateCamera(
//                 CameraUpdate.newLatLngBounds(
//                   LatLngBounds(
//                     southwest: LatLng(
//                       _pickupLatLng!.latitude < _dropLatLng!.latitude ? _pickupLatLng!.latitude : _dropLatLng!.latitude,
//                       _pickupLatLng!.longitude < _dropLatLng!.longitude ? _pickupLatLng!.longitude : _dropLatLng!.longitude,
//                     ),
//                     northeast: LatLng(
//                       _pickupLatLng!.latitude > _dropLatLng!.latitude ? _pickupLatLng!.latitude : _dropLatLng!.latitude,
//                       _pickupLatLng!.longitude > _dropLatLng!.longitude ? _pickupLatLng!.longitude : _dropLatLng!.longitude,
//                     ),
//                   ),
//                   100,
//                 ),
//               );
//             });
//           }
//         }
//       } catch (e) {
//         print('Error geocoding locations: $e');
//         // Fallback to current location if geocoding fails
//         if (_currentLocation != null) {
//           _pickupLatLng = LatLng(_currentLocation!.latitude, _currentLocation!.longitude);
//           _initializeMap();
//         }
//       }
//     }
//   }

//   void _addVehicleMarkers() {
//     if (_pickupLatLng == null || _dropLatLng == null) return;

//     // Calculate midpoint
//     double midLat = (_pickupLatLng!.latitude + _dropLatLng!.latitude) / 2;
//     double midLng = (_pickupLatLng!.longitude + _dropLatLng!.longitude) / 2;

//     // Add bike markers around the route
//     final List<LatLng> bikeLocations = [
//       LatLng(midLat - 0.002, midLng - 0.002),
//       LatLng(midLat + 0.002, midLng - 0.002),
//       LatLng(midLat - 0.002, midLng + 0.002),
//       LatLng(midLat + 0.002, midLng + 0.002),
//     ];

//     // Add car markers
//     final List<LatLng> carLocations = [
//       LatLng(midLat - 0.003, midLng),
//       LatLng(midLat + 0.003, midLng),
//       LatLng(midLat, midLng - 0.003),
//     ];

//     // Add auto markers
//     final List<LatLng> autoLocations = [
//       LatLng(midLat - 0.001, midLng - 0.001),
//       LatLng(midLat + 0.001, midLng + 0.001),
//       LatLng(midLat - 0.001, midLng + 0.001),
//     ];

//     // Add bike markers
//     for (int i = 0; i < bikeLocations.length; i++) {
//       _markers.add(
//         Marker(
//           markerId: MarkerId('bike_$i'),
//           position: bikeLocations[i],
//           icon: _bikeMarker ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
//           anchor: const Offset(0.5, 0.5),
//           flat: true,
//           rotation: 45.0 + (i * 30.0),
//         ),
//       );
//     }

//     // Add car markers
//     for (int i = 0; i < carLocations.length; i++) {
//       _markers.add(
//         Marker(
//           markerId: MarkerId('car_$i'),
//           position: carLocations[i],
//           icon: _carMarker ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
//           anchor: const Offset(0.5, 0.5),
//           flat: true,
//           rotation: 60.0 + (i * 25.0),
//         ),
//       );
//     }

//     // Add auto markers
//     for (int i = 0; i < autoLocations.length; i++) {
//       _markers.add(
//         Marker(
//           markerId: MarkerId('auto_$i'),
//           position: autoLocations[i],
//           icon: _autoMarker ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
//           anchor: const Offset(0.5, 0.5),
//           flat: true,
//           rotation: 50.0 + (i * 35.0),
//         ),
//       );
//     }
//   }

//   Future<void> _searchPlaces(String query, bool isPickup) async {
//     if (query.isEmpty) {
//       setState(() {
//         _searchResults.clear();
//       });
//       return;
//     }

//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       String url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(query)}&key=$_apiKey';
      
//       if (_currentLocation != null) {
//         url += '&location=${_currentLocation!.latitude},${_currentLocation!.longitude}&radius=10000';
//       }
      
//       final response = await http.get(Uri.parse(url));
      
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         if (data['status'] == 'OK') {
//           setState(() {
//             _searchResults = List<Map<String, dynamic>>.from(data['predictions'] ?? []);
//             _isLoading = false;
//           });
//         } else {
//           setState(() {
//             _searchResults = [];
//             _isLoading = false;
//           });
//         }
//       } else {
//         setState(() {
//           _searchResults = [];
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       setState(() {
//         _searchResults = [];
//         _isLoading = false;
//       });
//       print('Error searching places: $e');
//     }
//   }

//   Future<void> _selectPlace(Map<String, dynamic> prediction, bool isPickup) async {
//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       final placeId = prediction['place_id'] as String?;
//       if (placeId == null) return;
      
//       final url = 'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$_apiKey';
//       final response = await http.get(Uri.parse(url));
      
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         if (data['status'] == 'OK') {
//           final result = data['result'];
//           final geometry = result['geometry'];
//           final location = geometry['location'];
//           final lat = location['lat'] as double;
//           final lng = location['lng'] as double;
//           final name = result['name'] as String? ?? prediction['description'] as String? ?? '';
          
//           if (isPickup) {
//             _pickupLatLng = LatLng(lat, lng);
//             _pickupController.text = name;
//             _showPickupSearch = false;
//           } else {
//             _dropLatLng = LatLng(lat, lng);
//             _dropController.text = name;
//             _showDropSearch = false;
//           }
          
//           // Clear search results
//           _searchResults.clear();
          
//           // Update map
//           _initializeMap();
          
//           // Move camera to show both locations
//           if (_pickupLatLng != null && _dropLatLng != null) {
//             _mapController?.animateCamera(
//               CameraUpdate.newLatLngBounds(
//                 LatLngBounds(
//                   southwest: LatLng(
//                     _pickupLatLng!.latitude < _dropLatLng!.latitude ? _pickupLatLng!.latitude : _dropLatLng!.latitude,
//                     _pickupLatLng!.longitude < _dropLatLng!.longitude ? _pickupLatLng!.longitude : _dropLatLng!.longitude,
//                   ),
//                   northeast: LatLng(
//                     _pickupLatLng!.latitude > _dropLatLng!.latitude ? _pickupLatLng!.latitude : _dropLatLng!.latitude,
//                     _pickupLatLng!.longitude > _dropLatLng!.longitude ? _pickupLatLng!.longitude : _dropLatLng!.longitude,
//                   ),
//                 ),
//                 100,
//               ),
//             );
//           } else if (_pickupLatLng != null) {
//             _mapController?.animateCamera(
//               CameraUpdate.newLatLngZoom(_pickupLatLng!, 14.0),
//             );
//           }
//         }
//       }
//     } catch (e) {
//       print('Error getting place details: $e');
//     }

//     setState(() {
//       _isLoading = false;
//       _pickupFocusNode.unfocus();
//       _dropFocusNode.unfocus();
//     });
//   }

//   void _swapLocations() {
//     final tempText = _pickupController.text;
//     _pickupController.text = _dropController.text;
//     _dropController.text = tempText;

//     final tempLatLng = _pickupLatLng;
//     _pickupLatLng = _dropLatLng;
//     _dropLatLng = tempLatLng;

//     _initializeMap();
//   }

//   void _useCurrentLocation() async {
//     if (_currentLocation != null) {
//       setState(() {
//         _pickupLatLng = LatLng(_currentLocation!.latitude, _currentLocation!.longitude);
//         _pickupController.text = 'Current Location';
//         _showPickupSearch = false;
//       });
      
//       // Reverse geocode to get address
//       try {
//         final url = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=${_currentLocation!.latitude},${_currentLocation!.longitude}&key=$_apiKey';
//         final response = await http.get(Uri.parse(url));
        
//         if (response.statusCode == 200) {
//           final data = json.decode(response.body);
//           if (data['status'] == 'OK' && data['results'].isNotEmpty) {
//             final address = data['results'][0]['formatted_address'] as String?;
//             if (address != null && address.isNotEmpty) {
//               _pickupController.text = address;
//             }
//           }
//         }
//       } catch (e) {
//         print('Error reverse geocoding: $e');
//       }
      
//       _initializeMap();
//       _pickupFocusNode.unfocus();
//     }
//   }

//   void _onMapCreated(GoogleMapController controller) {
//     _mapController = controller;
//     // Initial camera position
//     if (_pickupLatLng != null) {
//       _mapController?.animateCamera(
//         CameraUpdate.newLatLngZoom(_pickupLatLng!, 14.0),
//       );
//     }
//   }

//   Map<String, dynamic> _getRideDetails(String rideType) {
//     switch (rideType) {
//       case 'Bike':
//         return {
//           'image': 'assets/All Icons Set-Pikkar_Bike.png',
//           'time': '2 min',
//           'passengers': '1 seat',
//           'price': '₹65',
//           'icon': Icons.two_wheeler,
//           'tagline': 'Ride Easy. Book Fast.',
//         };
//       case 'Auto':
//         return {
//           'image': 'assets/All Icons Set-Pikkar_Auto.png',
//           'time': '2 min',
//           'passengers': '3 seats',
//           'price': '₹90',
//           'icon': Icons.airport_shuttle,
//         };
//       case 'Cab':
//         return {
//           'image': 'assets/All Icons Set-Pikkar_Cab.png',
//           'time': '2 min',
//           'passengers': '4 seats',
//           'price': '₹180',
//           'icon': Icons.directions_car,
//         };
//       case 'SUV':
//         return {
//           'image': 'assets/All Icons Set-Pikkar_Parcel Bike.png',
//           'time': '2 min',
//           'passengers': '5 seats',
//           'price': '₹245',
//           'icon': Icons.directions_car,
//         };
//       default:
//         return {
//           'image': 'assets/All Icons Set-Pikkar_Bike.png',
//           'time': '2 min',
//           'passengers': '1 seat',
//           'price': '₹65',
//           'icon': Icons.two_wheeler,
//         };
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Hot-reload safe: when new fields are added, initState doesn't rerun.
//     _rideTypePageController ??= PageController(
//       initialPage: _rideTypes.indexOf(_selectedRideType).clamp(0, _rideTypes.length - 1),
//       viewportFraction: 0.46,
//     );

//     return Directionality(
//       textDirection: _appTheme.textDirection,
//       child: Scaffold(
//         backgroundColor: _appTheme.backgroundColor,
//         body: Stack(
//           children: [
//             // Map View with all features enabled
//             GoogleMap(
//               onMapCreated: _onMapCreated,
//               initialCameraPosition: const CameraPosition(
//                 target: LatLng(17.4175, 78.4934),
//                 zoom: 14.0,
//               ),
//               markers: _markers,
//               polylines: _polylines,
//               myLocationEnabled: true,
//               myLocationButtonEnabled: false,
//               mapType: MapType.normal,
//               zoomControlsEnabled: false,
//               compassEnabled: true,
//               buildingsEnabled: true,
//               trafficEnabled: false,
//               mapToolbarEnabled: false,
//               rotateGesturesEnabled: true,
//               scrollGesturesEnabled: true,
//               tiltGesturesEnabled: true,
//               zoomGesturesEnabled: true,
//             ),

//             // Navigation Buttons
//             Positioned(
//               top: 340,
//               left: 16,
//               child: Container(
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   shape: BoxShape.circle,
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.1),
//                       blurRadius: 4,
//                       offset: const Offset(0, 2),
//                     ),
//                   ],
//                 ),
//                 child: IconButton(
//                   icon: Icon(
//                     _appTheme.rtlEnabled ? Icons.arrow_forward : Icons.arrow_back,
//                     color: Colors.black,
//                   ),
//                   onPressed: () => Navigator.pop(context),
//                 ),
//               ),
//             ),
//             Positioned(
//               top: 340,
//               right: 16,
//               child: Container(
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   shape: BoxShape.circle,
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.1),
//                       blurRadius: 4,
//                       offset: const Offset(0, 2),
//                     ),
//                   ],
//                 ),
//                 child: IconButton(
//                   icon: Icon(Icons.my_location, color: Colors.black),
//                   onPressed: _updateMapToCurrentLocation,
//                 ),
//               ),
//             ),

//             // Loading Overlay
//             if (_isLoading)
//               Positioned.fill(
//                 child: Container(
//                   color: Colors.black.withOpacity(0.3),
//                   child: const Center(
//                     child: CircularProgressIndicator(),
//                   ),
//                 ),
//               ),

//             // Ride Options Panel (always visible) - fixed layout, no overflow
//             // Fixed Bottom Sheet (not draggable)
//             Positioned(
//               left: 0,
//               right: 0,
//               bottom: 0,
//               child: Container(
//                 height: MediaQuery.of(context).size.height * 0.55,
//                 decoration: BoxDecoration(
//                   color: Colors.grey.shade100,
//                   borderRadius: const BorderRadius.only(
//                     topLeft: Radius.circular(20),
//                     topRight: Radius.circular(20),
//                   ),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.1),
//                       blurRadius: 10,
//                       offset: const Offset(0, -2),
//                     ),
//                   ],
//                 ),
//                 child: SafeArea(
//                   top: false,
//                   child: Column(
//                     children: [
//                       // Drag Handle (non-functional, just visual)
//                       Container(
//                         margin: const EdgeInsets.symmetric(vertical: 12),
//                         width: 40,
//                         height: 4,
//                         decoration: BoxDecoration(
//                           color: _appTheme.textGrey,
//                           borderRadius: BorderRadius.circular(2),
//                         ),
//                       ),

//                       // Carousel content (scrollable)
//                       Expanded(
//                         child: SingleChildScrollView(
//                           padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
//                           child: Column(
//                             children: _rideTypes.map((rideType) {
//                               return _buildRideListCard(
//                                 rideType,
//                                 isSelected: _selectedRideType == rideType,
//                               );
//                             }).toList(),
//                           ),
//                         ),
//                       ),

//                       // Promotional Banner (fixed)
//                       Container(
//                         width: double.infinity,
//                         height: 32,
//                         padding: const EdgeInsets.symmetric(horizontal: 12),
//                         color: Colors.green,
//                         alignment: Alignment.center,
//                         child: const Text(
//                           '"Transparent fares and zero hidden charges - only on Pikkar."',
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 12,
//                             fontWeight: FontWeight.w500,
//                           ),
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                           textAlign: TextAlign.center,
//                         ),
//                       ),

//                       // Payment + Book Ride (fixed)
//                       Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//                         color: Colors.white,
//                         child: SafeArea(
//                           top: false,
//                           child: Row(
//                             children: [
//                               Expanded(
//                                 child: Row(
//                                   crossAxisAlignment: CrossAxisAlignment.center,
//                                   children: [
//                                     const Text(
//                                       'Cash',
//                                       style: TextStyle(
//                                         color: Colors.black,
//                                         fontWeight: FontWeight.w400,
//                                         fontSize: 12,
//                                       ),
//                                     ),
//                                     const SizedBox(width: 12),
//                                     Container(
//                                       width: 1,
//                                       height: 26,
//                                       color: Colors.black.withOpacity(0.28),
//                                     ),
//                                     const SizedBox(width: 12),
//                                     Flexible(
//                                       child: Text(
//                                         'Pay to Driver',
//                                         style: TextStyle(
//                                           color: Colors.black.withOpacity(0.8),
//                                           fontWeight: FontWeight.w500,
//                                           fontSize: 12,
//                                         ),
//                                         maxLines: 1,
//                                         overflow: TextOverflow.ellipsis,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                               const SizedBox(width: 14),
//                               SizedBox(
//                                 height: 60,
//                                 width: 150,
//                                 child: ElevatedButton(
//                                   onPressed: () {
//                                     Navigator.push(
//                                       context,
//                                       MaterialPageRoute(
//                                         builder: (_) => FindingDriverScreen(
//                                           pickupLocation:
//                                               widget.pickupLocation ?? 'Pickup Location',
//                                           dropLocation:
//                                               widget.dropLocation ?? 'Drop Location',
//                                           rideType: _selectedRideType,
//                                           pickupLatLng: _pickupLatLng,
//                                           dropLatLng: _dropLatLng,
//                                         ),
//                                       ),
//                                     );
//                                   },
//                                   style: ElevatedButton.styleFrom(
//                                     backgroundColor: _appTheme.brandRed,
//                                     padding: const EdgeInsets.symmetric(horizontal: 20),
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(40),
//                                     ),
//                                     elevation: 0,
//                                   ),
//                                   child: const Text(
//                                     'Book Ride',
//                                     style: TextStyle(
//                                       color: Colors.white,
//                                       fontSize: 18,
//                                       fontWeight: FontWeight.w600,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
          
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildRideCarouselCard(String rideType, {required bool isSelected}) {
//     final details = _getRideDetails(rideType);
//     final size = isSelected ? 150.0 : 130.0;

//     return GestureDetector(
//       onTap: () {
//         final index = _rideTypes.indexOf(rideType);
//         if (index == -1) return;
//         _rideTypePageController?.animateToPage(
//           index,
//           duration: const Duration(milliseconds: 250),
//           curve: Curves.easeOut,
//         );
//         setState(() {
//           _selectedRideType = rideType;
//         });
//       },
//       child: Container(
//         width: size,
//         height: size,
//         margin: const EdgeInsets.symmetric(horizontal: 8),
//         child: AspectRatio(
//           aspectRatio: 1.0, // Force 1:1 ratio (perfect square)
//           child: AnimatedContainer(
//             duration: const Duration(milliseconds: 200),
//             curve: Curves.easeOut,
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(4),
//               border: Border.all(
//                 color: Colors.black.withOpacity(0.2),
//                 width: 1.5,
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(isSelected ? 0.20 : 0.08),
//                   blurRadius: isSelected ? 12 : 8,
//                   offset: const Offset(0, 4),
//                 ),
//               ],
//             ),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 SizedBox(
//                   width: isSelected ? 60 : 50,
//                   height: isSelected ? 60 : 50,
//                   child: Image.asset(
//                     details['image'] as String,
//                     fit: BoxFit.contain,
//                     errorBuilder: (context, error, stackTrace) {
//                       return Icon(
//                         details['icon'] as IconData,
//                         color: _appTheme.brandRed,
//                         size: isSelected ? 40 : 35,
//                       );
//                     },
//                   ),
//                 ),
//                 SizedBox(height: isSelected ? 8 : 6),
//                 Text(
//                   rideType,
//                   style: TextStyle(
//                     fontSize: isSelected ? 14 : 13,
//                     fontWeight: FontWeight.w500,
//                     color: Colors.black.withOpacity(0.9),
//                   ),
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//                 const SizedBox(height: 4),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   crossAxisAlignment: CrossAxisAlignment.baseline,
//                   textBaseline: TextBaseline.alphabetic,
//                   children: [
//                     Text(
//                       details['price'] as String,
//                       style: TextStyle(
//                         fontSize: isSelected ? 20 : 18,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.black,
//                       ),
//                     ),
//                     const SizedBox(width: 6),
//                     Text(
//                       '${details['time']}',
//                       style: TextStyle(
//                         color: _appTheme.textGrey,
//                         fontSize: isSelected ? 13 : 11,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildRideListCard(String rideType, {required bool isSelected}) {
//     final details = _getRideDetails(rideType);

//     return GestureDetector(
//       onTap: () {
//         setState(() {
//           _selectedRideType = rideType;
//         });
//       },
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         curve: Curves.easeOut,
//         margin: EdgeInsets.only(
//           bottom: isSelected ? 10 : 8,
//           left: isSelected ? 0 : 4,
//           right: isSelected ? 0 : 4,
//         ),
//         padding: EdgeInsets.all(isSelected ? 8 : 6),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(12),
//           border: isSelected
//               ? Border.all(color: _appTheme.brandRed, width: 1)
//               : null,
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(isSelected ? 0.1 : 0.05),
//               blurRadius: isSelected ? 10 : 6,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Row(
//           children: [
//             // Red bar indicator on the left (only for selected)
//             if (isSelected)
//               Container(
//                 width: 4,
//                 height: 36,
//                 margin: const EdgeInsets.only(right: 12),
//                 decoration: BoxDecoration(
//                   color: _appTheme.brandRed,
//                   borderRadius: BorderRadius.circular(2),
//                 ),
//               ),
            
//             // Vehicle Image
//             Container(
//               width: isSelected ? 64 : 56,
//               height: isSelected ? 64 : 56,
//               padding: const EdgeInsets.all(6),
//               child: Image.asset(
//                 details['image'] as String,
//                 fit: BoxFit.contain,
//                 errorBuilder: (context, error, stackTrace) {
//                   return Icon(
//                     details['icon'] as IconData,
//                     color: _appTheme.brandRed,
//                     size: isSelected ? 36 : 32,
//                   );
//                 },
//               ),
//             ),
            
//             SizedBox(width: isSelected ? 14 : 12),
            
//             // Vehicle Details
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     rideType,
//                     style: TextStyle(
//                       fontSize: isSelected ? 17 : 16,
//                       fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
//                       color: Colors.black,
//                     ),
//                   ),
//                   const SizedBox(height: 3),
//                   Text(
//                     '${details['time']} · ${details['passengers'] ?? '1 seat'}',
//                     style: TextStyle(
//                       fontSize: isSelected ? 13 : 12,
//                       color: Colors.grey.shade600,
//                       fontWeight: FontWeight.w400,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
            
//             // Price
//             Text(
//               details['price'] as String,
//               style: TextStyle(
//                 fontSize: isSelected ? 22 : 20,
//                 fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      
//                 color: Colors.black,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

// }