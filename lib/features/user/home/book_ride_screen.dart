import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'ride_booking_screen.dart';
import '../../../core/theme/app_theme.dart';

class BookRideScreen extends StatefulWidget {
  final String rideType;

  const BookRideScreen({
    super.key,
    required this.rideType,
  });

  @override
  State<BookRideScreen> createState() => _BookRideScreenState();
}

class _BookRideScreenState extends State<BookRideScreen> {
  final AppTheme _appTheme = AppTheme();
  final TextEditingController _dropController = TextEditingController();
  final FocusNode _dropFocusNode = FocusNode();
  static const String _apiKey = 'AIzaSyC-lm1swnNq-IAekwxiH9vyLwcOc2TNd3E';
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  String? _currentLocationName;
  LatLng? _pickupLatLng;
  LatLng? _dropLatLng;

  @override
  void initState() {
    super.initState();
    _appTheme.addListener(_onThemeChanged);
    _getCurrentLocation();
    _dropController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _appTheme.removeListener(_onThemeChanged);
    _dropController.dispose();
    _dropFocusNode.dispose();
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  void _onSearchChanged() {
    if (_dropController.text.isNotEmpty) {
      _searchPlaces(_dropController.text);
    } else {
      setState(() {
        _searchResults.clear();
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _pickupLatLng = LatLng(position.latitude, position.longitude);

      // Reverse geocode to get address
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _currentLocationName =
              '${place.street}, ${place.locality}, ${place.administrativeArea}';
        });
      }
    } catch (e) {
      print('Error getting current location: $e');
    }
  }

  Future<void> _searchPlaces(String query) async {
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
      String url =
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(query)}&key=$_apiKey';

      if (_pickupLatLng != null) {
        url +=
            '&location=${_pickupLatLng!.latitude},${_pickupLatLng!.longitude}&radius=10000';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          setState(() {
            _searchResults =
                List<Map<String, dynamic>>.from(data['predictions'] ?? []);
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

  Future<void> _selectPlace(Map<String, dynamic> prediction) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final placeId = prediction['place_id'] as String?;
      if (placeId == null) return;

      final url =
          'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$_apiKey';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final result = data['result'];
          final geometry = result['geometry'];
          final location = geometry['location'];
          final lat = location['lat'] as double;
          final lng = location['lng'] as double;
          final name =
              result['name'] as String? ?? prediction['description'] as String? ?? '';

          _dropLatLng = LatLng(lat, lng);
          _dropController.text = name;

          // Navigate to ride booking screen
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RideBookingScreen(
                  pickupLocation: _currentLocationName ?? 'Current Location',
                  dropLocation: name,
                  rideType: widget.rideType,
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error getting place details: $e');
    }

    setState(() {
      _isLoading = false;
      _dropFocusNode.unfocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _appTheme.textDirection,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              _appTheme.rtlEnabled ? Icons.arrow_forward : Icons.arrow_back,
              color: _appTheme.textColor,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Book Ride',
            style: TextStyle(
              color: _appTheme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // Search Input Field
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _appTheme.textGrey.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _dropController,
                  focusNode: _dropFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Where to drop?',
                    hintStyle: TextStyle(color: _appTheme.textGrey),
                    prefixIcon: Icon(
                      Icons.search,
                      color: _appTheme.textGrey,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  style: TextStyle(color: _appTheme.textColor),
                ),
              ),
            ),

            // Search Results or Loading
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _searchResults.isEmpty
                      ? Center(
                          child: Text(
                            'Search for your drop location',
                            style: TextStyle(
                              color: _appTheme.textGrey,
                              fontSize: 14,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final result = _searchResults[index];
                            return ListTile(
                              leading: Icon(
                                Icons.location_on,
                                color: _appTheme.brandRed,
                              ),
                              title: Text(
                                result['description'] as String? ?? '',
                                style: TextStyle(
                                  color: _appTheme.textColor,
                                  fontSize: 14,
                                ),
                              ),
                              onTap: () => _selectPlace(result),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

