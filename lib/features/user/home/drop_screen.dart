import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'ride_booking_screen.dart';
import '../../../core/theme/app_theme.dart';

class DropScreen extends StatefulWidget {
  final String rideType; // Bike, Auto, Parcel, Truck

  const DropScreen({
    super.key,
    required this.rideType,
  });

  @override
  State<DropScreen> createState() => _DropScreenState();
}

class _DropScreenState extends State<DropScreen> {
  final AppTheme _appTheme = AppTheme();
  GoogleMapController? _mapController;
  final TextEditingController _pickupSearchController = TextEditingController();
  final TextEditingController _dropSearchController = TextEditingController();
  List<Map<String, dynamic>> _pickupSearchResults = [];
  List<Map<String, dynamic>> _dropSearchResults = [];
  bool _isSearchingPickup = false;
  bool _isSearchingDrop = false;
  bool _showPickupSearch = false;
  bool _showDropSearch = false;
  Position? _currentLocation;
  LatLng? _pickupLocation;
  LatLng? _selectedLocation;
  String? _pickupLocationName;
  String? _selectedLocationName;
  String _currentLocationName = "Current Location";
  static const String _apiKey = 'AIzaSyAT3wIjV73qVXPAlgkyifnns38GztnbNF4';

  @override
  void initState() {
    super.initState();
    _appTheme.addListener(_onThemeChanged);
    _initializeLocation();
    _pickupSearchController.addListener(() => _onPickupSearchChanged());
    _dropSearchController.addListener(() => _onDropSearchChanged());
  }

  @override
  void dispose() {
    _appTheme.removeListener(_onThemeChanged);
    _mapController?.dispose();
    _pickupSearchController.dispose();
    _dropSearchController.dispose();
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  void _onPickupSearchChanged() {
    if (_pickupSearchController.text.isNotEmpty) {
      setState(() {
        _showPickupSearch = true;
        _showDropSearch = false;
      });
      _searchPlaces(_pickupSearchController.text, true);
    } else {
      setState(() {
        _pickupSearchResults = [];
        _showPickupSearch = false;
      });
    }
  }

  void _onDropSearchChanged() {
    if (_dropSearchController.text.isNotEmpty) {
      setState(() {
        _showDropSearch = true;
        _showPickupSearch = false;
      });
      _searchPlaces(_dropSearchController.text, false);
    } else {
      setState(() {
        _dropSearchResults = [];
        _showDropSearch = false;
      });
    }
  }

  Future<void> _initializeLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      _currentLocation = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (_currentLocation != null && mounted) {
        setState(() {
          _pickupLocation = LatLng(_currentLocation!.latitude, _currentLocation!.longitude);
          _pickupLocationName = _currentLocationName;
        });
        _updateMapCamera();
        _getCurrentLocationName();
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  void _updateMapCamera() {
    if (_mapController != null && _currentLocation != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentLocation!.latitude, _currentLocation!.longitude),
          14.0,
        ),
      );
    }
  }

  Future<void> _getCurrentLocationName() async {
    if (_currentLocation != null) {
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          _currentLocation!.latitude,
          _currentLocation!.longitude,
        );
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          String address = '';
          if (place.street != null && place.street!.isNotEmpty) {
            address = place.street!;
          }
          if (place.subLocality != null && place.subLocality!.isNotEmpty) {
            if (address.isNotEmpty) {
              address += ', ${place.subLocality!}';
            } else {
              address = place.subLocality!;
            }
          }
          if (mounted) {
            setState(() {
              _currentLocationName = address.isNotEmpty ? address : "Current Location";
            });
          }
        }
      } catch (e) {
        print('Error getting location name: $e');
      }
    }
  }

  Future<void> _searchPlaces(String query, bool isPickup) async {
    if (query.isEmpty) {
      setState(() {
        if (isPickup) {
          _pickupSearchResults = [];
        } else {
          _dropSearchResults = [];
        }
      });
      return;
    }

    setState(() {
      if (isPickup) {
        _isSearchingPickup = true;
      } else {
        _isSearchingDrop = true;
      }
    });

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&key=$_apiKey&components=country:in',
      );
      final response = await http.get(url);
      final data = json.decode(response.body);

      if (data['status'] == 'OK' && mounted) {
        setState(() {
          final results = (data['predictions'] as List)
              .map((prediction) => {
                    'description': prediction['description'],
                    'place_id': prediction['place_id'],
                  })
              .toList();
          if (isPickup) {
            _pickupSearchResults = results;
            _isSearchingPickup = false;
          } else {
            _dropSearchResults = results;
            _isSearchingDrop = false;
          }
        });
      } else {
        setState(() {
          if (isPickup) {
            _isSearchingPickup = false;
          } else {
            _isSearchingDrop = false;
          }
        });
      }
    } catch (e) {
      setState(() {
        if (isPickup) {
          _isSearchingPickup = false;
        } else {
          _isSearchingDrop = false;
        }
      });
    }
  }

  Future<void> _getPlaceDetails(String placeId, String description, bool isPickup) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$_apiKey',
      );
      final response = await http.get(url);
      final data = json.decode(response.body);

      if (data['status'] == 'OK' && mounted) {
        final location = data['result']['geometry']['location'];
        final latLng = LatLng(location['lat'], location['lng']);

        setState(() {
          if (isPickup) {
            _pickupLocation = latLng;
            _pickupLocationName = description;
            _pickupSearchController.text = description;
            _pickupSearchResults = [];
            _showPickupSearch = false;
          } else {
            _selectedLocation = latLng;
            _selectedLocationName = description;
            _dropSearchController.text = description;
            _dropSearchResults = [];
            _showDropSearch = false;
          }
        });

        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(latLng, 15.0),
          );
        }
      }
    } catch (e) {
      print('Error getting place details: $e');
    }
  }

  void _selectPickupOnMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DropMapLocationScreen(
          onLocationSelected: (latLng, name) {
            setState(() {
              _pickupLocation = latLng;
              _pickupLocationName = name;
            });
          },
        ),
      ),
    );
  }

  void _selectDropOnMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DropMapLocationScreen(
          onLocationSelected: (latLng, name) {
            setState(() {
              _selectedLocation = latLng;
              _selectedLocationName = name;
            });
          },
        ),
      ),
    );
  }

  void _proceed() {
    if (_selectedLocationName != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RideBookingScreen(
            pickupLocation: _pickupLocationName ?? 'Current Location',
            dropLocation: _selectedLocationName!,
            rideType: widget.rideType,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a drop location'),
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
            'Drop',
            style: TextStyle(
              color: _appTheme.textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: false,
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _appTheme.textGrey.withOpacity(0.3),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(50),
              ),
              child: TextButton.icon(
                onPressed: _selectDropOnMap,
                icon: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _appTheme.brandRed,
                  ),
                ),
                label: Text(
                  'Select on map',
                  style: TextStyle(
                    color: _appTheme.textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 16),

              // Pickup and Drop Search Results Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _appTheme.dividerColor,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Pickup Search Bar
                      Container(
                        decoration: BoxDecoration(
                          color: _appTheme.iconBgColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: TextField(
                          controller: _pickupSearchController,
                          decoration: InputDecoration(
                            hintText: 'Search for pickup location',
                            hintStyle: TextStyle(color: _appTheme.textGrey),
                            prefixIcon: Icon(Icons.location_on, color: _appTheme.brandRed, size: 20),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          style: TextStyle(color: _appTheme.textColor),
                          onTap: () {
                            setState(() {
                              _showPickupSearch = true;
                              _showDropSearch = false;
                            });
                          },
                        ),
                      ),
                      // Pickup Search Results (top)
                      if (_showPickupSearch && _pickupSearchResults.isNotEmpty)
                        ..._pickupSearchResults.asMap().entries.map((entry) {
                          final index = entry.key;
                          final result = entry.value;
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _suggestedLocationItem(
                                result['description'],
                                isSelected: false,
                                onTap: () => _getPlaceDetails(
                                  result['place_id'],
                                  result['description'],
                                  true,
                                ),
                              ),
                              if (index < _pickupSearchResults.length - 1 || (_showDropSearch && _dropSearchResults.isNotEmpty))
                                Divider(height: 1, color: _appTheme.dividerColor),
                            ],
                          );
                        }).toList(),
                      // Divider between pickup and drop if both have results
                      if (_showPickupSearch && _pickupSearchResults.isNotEmpty && _showDropSearch && _dropSearchResults.isNotEmpty)
                        Divider(height: 1, color: _appTheme.dividerColor),
                      // Drop Search Bar
                      Container(
                        decoration: BoxDecoration(
                          color: _appTheme.iconBgColor,
                          borderRadius: _showPickupSearch && _pickupSearchResults.isNotEmpty
                              ? BorderRadius.zero
                              : const BorderRadius.only(
                                  bottomLeft: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                        ),
                        child: TextField(
                          controller: _dropSearchController,
                          decoration: InputDecoration(
                            hintText: 'Search for drop location',
                            hintStyle: TextStyle(color: _appTheme.textGrey),
                            prefixIcon: Icon(Icons.location_on, color: Colors.green, size: 20),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          style: TextStyle(color: _appTheme.textColor),
                          onTap: () {
                            setState(() {
                              _showDropSearch = true;
                              _showPickupSearch = false;
                            });
                          },
                        ),
                      ),
                      // Drop Search Results (bottom)
                      if (_showDropSearch && _dropSearchResults.isNotEmpty)
                        ..._dropSearchResults.asMap().entries.map((entry) {
                          final index = entry.key;
                          final result = entry.value;
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _suggestedLocationItem(
                                result['description'],
                                isSelected: false,
                                onTap: () => _getPlaceDetails(
                                  result['place_id'],
                                  result['description'],
                                  false,
                                ),
                              ),
                              if (index < _dropSearchResults.length - 1)
                                Divider(height: 1, color: _appTheme.dividerColor),
                            ],
                          );
                        }).toList(),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Recent Locations List
              if (!_showPickupSearch && !_showDropSearch)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // Recent Locations
                      _recentLocationItem(
                        'Lulu Mall',
                        '20-01-5/B, Kondapur, Hyderabad, Telangana, 50002',
                        isFavorited: true,
                        onTap: () {
                          setState(() {
                            _selectedLocationName =
                                'Lulu Mall, Kondapur, Hyderabad, Telangana';
                          });
                        },
                      ),
                      _recentLocationItem(
                        'Hotal Grand Sitara',
                        '20-01-5/B, Kondapur, Hyderabad, Telangana, 50002',
                        isFavorited: false,
                        onTap: () {
                          setState(() {
                            _selectedLocationName =
                                'Hotel Grand Sitara, Banjara Hills, Hyderabad, Telangana';
                          });
                        },
                      ),
                      _recentLocationItem(
                        'GVK Mall',
                        '20-01-5/B, Kondapur, Hyderabad, Telangana, 50002',
                        isFavorited: false,
                        onTap: () {
                          setState(() {
                            _selectedLocationName = 'GVK Mall, Banjara Hills, Hyderabad';
                          });
                        },
                      ),
                      _recentLocationItem(
                        'Metro Convention Classic',
                        '20-01-5/B, Kondapur, Hyderabad, Telangana, 50002',
                        isFavorited: false,
                        onTap: () {
                          setState(() {
                            _selectedLocationName =
                                'Metro Convention Classic, Hyderabad';
                          });
                        },
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 100), // Space for proceed button
            ],
          ),
        ),
        bottomNavigationBar: _selectedLocationName != null
            ? Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: _appTheme.dividerColor, width: 1),
                  ),
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _proceed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _appTheme.brandRed,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Proceed',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _suggestedLocationItem(String location, {bool isSelected = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.green : _appTheme.brandRed,
                  width: 2,
                ),
                color: isSelected ? Colors.green : Colors.transparent,
              ),
              child: isSelected
                  ? null
                  : Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _appTheme.brandRed,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                location,
                style: TextStyle(
                  color: _appTheme.textColor,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recentLocationItem(String name, String address, {bool isFavorited = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: _appTheme.dividerColor,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time,
              color: _appTheme.textGrey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: _appTheme.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address,
                    style: TextStyle(
                      color: _appTheme.textGrey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                isFavorited ? Icons.favorite : Icons.favorite_border,
                color: isFavorited ? _appTheme.brandRed : _appTheme.textGrey,
                size: 20,
              ),
              onPressed: () {
                // Toggle favorite
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Map Location Screen for selecting location on map
class DropMapLocationScreen extends StatefulWidget {
  final Function(LatLng, String)? onLocationSelected;

  const DropMapLocationScreen({super.key, this.onLocationSelected});

  @override
  State<DropMapLocationScreen> createState() => _DropMapLocationScreenState();
}

class _DropMapLocationScreenState extends State<DropMapLocationScreen> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  String? _selectedLocationName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Location'),
        actions: [
          if (_selectedLocation != null)
            TextButton(
              onPressed: () {
                if (widget.onLocationSelected != null && _selectedLocation != null && _selectedLocationName != null) {
                  widget.onLocationSelected!(_selectedLocation!, _selectedLocationName!);
                }
                Navigator.pop(context);
              },
              child: Text('Done'),
            ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(17.3850, 78.4867), // Hyderabad
          zoom: 14,
        ),
        onMapCreated: (controller) {
          _mapController = controller;
        },
        onTap: (latLng) {
          setState(() {
            _selectedLocation = latLng;
            _selectedLocationName = '${latLng.latitude}, ${latLng.longitude}';
          });
        },
        markers: _selectedLocation != null
            ? {
                Marker(
                  markerId: MarkerId('selected'),
                  position: _selectedLocation!,
                ),
              }
            : {},
      ),
    );
  }
}

