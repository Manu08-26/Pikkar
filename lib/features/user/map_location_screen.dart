import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/app_localizations.dart';

class MapLocationScreen extends StatefulWidget {
  const MapLocationScreen({super.key});

  @override
  State<MapLocationScreen> createState() => _MapLocationScreenState();
}

class _MapLocationScreenState extends State<MapLocationScreen> {
  final AppTheme _appTheme = AppTheme();
  GoogleMapController? _mapController;
  Position? _currentPosition;
  String _address = "Loading location...";
  bool _isLoading = true;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _appTheme.addListener(_onThemeChanged);
    _getCurrentLocation();
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

  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        _isLoading = true;
        _address = "Getting location...";
      });

      // Check location service status
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _address = "Please enable location services";
          _isLoading = false;
        });
        // Show dialog to enable location
        _showLocationServiceDialog();
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _address = "Location permission denied";
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _address = "Location permission permanently denied. Please enable in settings.";
          _isLoading = false;
        });
        return;
      }

      // Get last known position first (faster)
      Position? lastPosition = await Geolocator.getLastKnownPosition();
      if (lastPosition != null) {
        _updateLocation(lastPosition);
      }

      // Get current position with better accuracy
      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
        ).timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            // If timeout, use last known position if available
            if (lastPosition != null) {
              return lastPosition!;
            }
            throw TimeoutException('Location request timed out');
          },
        );
      } on TimeoutException {
        // If timeout and we have last known position, use it
        if (lastPosition != null) {
          position = lastPosition;
        } else {
          rethrow;
        }
      }

      _updateLocation(position);
    } catch (e) {
      setState(() {
        _address = "Error: ${e.toString()}";
        _isLoading = false;
      });
      // Try to use last known position as fallback
      try {
        Position? lastPosition = await Geolocator.getLastKnownPosition();
        if (lastPosition != null) {
          _updateLocation(lastPosition);
        }
      } catch (_) {
        // Ignore fallback errors
      }
    }
  }

  Future<void> _updateLocation(Position position) async {
    try {
      // Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(const Duration(seconds: 5));

      String address = "";
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        List<String> addressParts = [];
        if (place.street != null && place.street!.isNotEmpty) {
          addressParts.add(place.street!);
        }
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          addressParts.add(place.subLocality!);
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          addressParts.add(place.locality!);
        }
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
          addressParts.add(place.administrativeArea!);
        }
        if (place.country != null && place.country!.isNotEmpty) {
          addressParts.add(place.country!);
        }
        address = addressParts.join(", ");
      }

      setState(() {
        _currentPosition = position;
        _address = address.isNotEmpty 
            ? address 
            : "${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}";
        _isLoading = false;
        _markers = {
          Marker(
            markerId: const MarkerId('current_location'),
            position: LatLng(position.latitude, position.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(
              title: 'Current Location',
              snippet: _address,
            ),
          ),
        };
      });

      // Move camera to current location
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            16.0,
          ),
        );
      }
    } catch (e) {
      // If geocoding fails, still show coordinates
      setState(() {
        _currentPosition = position;
        _address = "${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}";
        _isLoading = false;
        _markers = {
          Marker(
            markerId: const MarkerId('current_location'),
            position: LatLng(position.latitude, position.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(
              title: 'Current Location',
              snippet: _address,
            ),
          ),
        };
      });

      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            16.0,
          ),
        );
      }
    }
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Services Disabled'),
        content: const Text('Please enable location services in your device settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Geolocator.openLocationSettings();
              Navigator.pop(context);
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_currentPosition != null) {
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          16.0,
        ),
      );
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
            // Google Map View
            _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: _appTheme.brandRed,
                    ),
                  )
                : GoogleMap(
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: CameraPosition(
                      target: _currentPosition != null
                          ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                          : const LatLng(17.3850, 78.4867), // Default to Hyderabad
                      zoom: 16.0,
                    ),
                    markers: _markers,
                    polylines: _polylines,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    mapType: MapType.normal,
                    zoomControlsEnabled: true,
                    compassEnabled: true,
                    buildingsEnabled: true,
                    trafficEnabled: false,
                    mapToolbarEnabled: false,
                    rotateGesturesEnabled: true,
                    scrollGesturesEnabled: true,
                    tiltGesturesEnabled: true,
                    zoomGesturesEnabled: true,
                  ),

            // Back Button
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: _appTheme.cardColor,
                    borderRadius: BorderRadius.circular(8),
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
                      color: _appTheme.textColor,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),

            // Location Details Card
            Positioned(
              top: 80,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _appTheme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _appTheme.brandRed,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.location_on,
                        color: _appTheme.brandRed,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _address,
                        style: TextStyle(
                          fontSize: 14,
                          color: _appTheme.textColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // My Location Button
            Positioned(
              bottom: 200,
              right: 16,
              child: FloatingActionButton(
                mini: true,
                backgroundColor: _appTheme.cardColor,
                onPressed: () {
                  if (_currentPosition != null) {
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLngZoom(
                        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                        16.0,
                      ),
                    );
                  } else {
                    _getCurrentLocation();
                  }
                },
                child: Icon(
                  Icons.my_location,
                  color: _appTheme.brandRed,
                ),
              ),
            ),

            // Confirm Location Button
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _appTheme.cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _appTheme.brandRed,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        localizations.confirmLocation,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
