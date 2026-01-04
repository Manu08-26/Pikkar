import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'recent_locations_store.dart';
import 'ride_booking_screen.dart';
import 'parcel_drop_details_screen.dart';
import '../../../core/theme/app_theme.dart';

class DropScreen extends StatefulWidget {
  final String rideType; // Bike, Auto, Parcel, Truck
  /// If true, selecting a drop location will open the Parcel contact/details bottom sheet.
  /// Use this only for the Parcel delivery flow; keep false for normal "Where to drop" flow.
  final bool enableParcelDropDetails;

  const DropScreen({
    super.key,
    required this.rideType,
    this.enableParcelDropDetails = false,
  });

  @override
  State<DropScreen> createState() => _DropScreenState();
}

class _DropScreenState extends State<DropScreen> {
  LatLng? _selectedLatLng;
String _selectedPlaceName = '';
  bool _showAddStopRow = false; // Initially hidden, shown when "Add stops" clicked

  final AppTheme _appTheme = AppTheme();
  GoogleMapController? _mapController;
  final TextEditingController _pickupSearchController = TextEditingController();
  final TextEditingController _dropSearchController = TextEditingController();
  final FocusNode _pickupFocusNode = FocusNode();
  List<Map<String, dynamic>> _pickupSearchResults = [];
  List<Map<String, dynamic>> _dropSearchResults = [];
  bool _pickupUserInteracted = false;
  bool _isSearchingPickup = false;
  bool _isSearchingDrop = false;
  bool _showPickupSearch = false;
  bool _showDropSearch = false;
  Position? _currentLocation;
  LatLng? _pickupLocation;
  LatLng? _selectedLocation;
  String? _pickupLocationName;
  String? _selectedLocationName;
  final List<Map<String, String>> _recentDrops = [];
  String _currentLocationName = "Current Location";
  String _selectedForMe = "For me";
  static const String _apiKey = 'AIzaSyAT3wIjV73qVXPAlgkyifnns38GztnbNF4';

  @override
  void initState() {
    super.initState();
    _appTheme.addListener(_onThemeChanged);
    _initializeLocation();
    _pickupSearchController.addListener(() => _onPickupSearchChanged());
    _dropSearchController.addListener(() => _onDropSearchChanged());
    _loadRecentDrops();
  }

  @override
  void dispose() {
    _appTheme.removeListener(_onThemeChanged);
    _mapController?.dispose();
    _pickupSearchController.dispose();
    _dropSearchController.dispose();
    _pickupFocusNode.dispose();
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  void _loadRecentDrops() {
    _recentDrops
      ..clear()
      ..addAll(RecentLocationsStore.items);
  }

  void _onPickupSearchChanged() {
    if (!_pickupUserInteracted) return;
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
        _updateMapCamera();
        _getCurrentLocationName().then((_) {
          if (mounted) {
            setState(() {
              _pickupLocation = LatLng(_currentLocation!.latitude, _currentLocation!.longitude);
              _pickupLocationName = _currentLocationName;
              if (_pickupSearchController.text.isEmpty) {
                _pickupSearchController.text = _currentLocationName;
              }
            });
          }
        });
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

  Future<void> _setPickupToCurrent() async {
    if (_currentLocation == null) {
      await _initializeLocation();
    }
    if (_currentLocation != null) {
      setState(() {
        _pickupLocation = LatLng(_currentLocation!.latitude, _currentLocation!.longitude);
        _pickupLocationName = _currentLocationName;
        _pickupSearchController.text = _currentLocationName;
        _pickupUserInteracted = true;
        _showPickupSearch = false;
        _showDropSearch = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Unable to fetch current location'),
          backgroundColor: _appTheme.brandRed,
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
        // Calculate distances for drop search results
        List<Map<String, dynamic>> results = (data['predictions'] as List)
            .map((prediction) {
              String fullDescription = prediction['description'];
              // Extract only the place name (first part before comma)
              String placeName = fullDescription.split(',').first.trim();
              return {
                'description': fullDescription,
                'place_name': placeName,
                'place_id': prediction['place_id'],
                'distance': null, // Will be calculated if needed
              };
            })
            .toList();
        
        // Calculate distances for drop results if current location is available
        if (!isPickup && _currentLocation != null) {
          for (var result in results) {
            _calculateDistanceForPlace(result['place_id']).then((distance) {
              if (mounted) {
                setState(() {
                  int index = _dropSearchResults.indexWhere((r) => r['place_id'] == result['place_id']);
                  if (index != -1) {
                    _dropSearchResults[index]['distance'] = distance;
                  }
                });
              }
            });
          }
        }
        
        setState(() {
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

  Future<double?> _calculateDistanceForPlace(String placeId) async {
    if (_currentLocation == null) return null;
    
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$_apiKey',
      );
      final response = await http.get(url);
      final data = json.decode(response.body);

      if (data['status'] == 'OK') {
        final location = data['result']['geometry']['location'];
        double distance = Geolocator.distanceBetween(
          _currentLocation!.latitude,
          _currentLocation!.longitude,
          location['lat'],
          location['lng'],
        );
        return distance / 1000; // Convert to km
      }
    } catch (e) {
      print('Error calculating distance: $e');
    }
    return null;
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
        final resolvedName = data['result']['name'] ?? description;
        final resolvedAddress = data['result']['formatted_address'] ?? description;

        setState(() {
          if (isPickup) {
            _pickupLocation = latLng;
            _pickupLocationName = description;
            _pickupSearchController.text = description;
            _pickupSearchResults = [];
            _showPickupSearch = false;
            _pickupUserInteracted = true;
          } else {
            print('DEBUG: Setting _selectedLocation = $latLng');
            print('DEBUG: Setting _selectedLocationName = $resolvedName');
            _selectedLocation = latLng;
            _selectedLocationName = resolvedName;
            _dropSearchController.text = resolvedName;
            _dropSearchResults = [];
            _showDropSearch = false;
            _addRecentDrop(name: resolvedName, address: resolvedAddress);
          }
        });
        
        if (!isPickup) {
          print('DEBUG: About to call _handleDropSelected');
          print('DEBUG: _selectedLocation = $_selectedLocation');
          print('DEBUG: _pickupLocation = $_pickupLocation');
          _handleDropSelected();
        }

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

  void _selectDropOnMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DropMapLocationScreen(
          apiKey: _apiKey,
          onLocationSelected: (latLng, name) {
            setState(() {
              _selectedLocation = latLng;
              _selectedLocationName = name;
            });
            _addRecentDrop(name: name, address: name);
            
            _addRecentDrop(name: name, address: name);
            _handleDropSelected();
          },
        ),
      ),
    );
  }

  Future<void> _showParcelDropDetailsPopup() async {
    if (_selectedLocationName == null) return;
    
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ParcelDropDetailsScreen(
        serviceType: widget.rideType,
        pickupLocation: _pickupLocationName ?? _currentLocationName,
        dropLocation: _selectedLocationName ?? '',
      ),
    );
  }

  void _goToRideBooking() {
    print('DEBUG: _goToRideBooking called');
    print('DEBUG: _pickupLocation = $_pickupLocation');
    print('DEBUG: _selectedLocation = $_selectedLocation');
    print('DEBUG: _pickupLocationName = $_pickupLocationName');
    print('DEBUG: _selectedLocationName = $_selectedLocationName');
    
    if (_selectedLocationName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a drop location'),
          backgroundColor: _appTheme.brandRed,
        ),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => RideBookingScreen(
          pickupLocation: _pickupLocationName ?? 'Current Location',
          dropLocation: _selectedLocationName!,
          rideType: widget.rideType,
          // pickupLatLng: _pickupLocation,
          // dropLatLng: _selectedLocation,
        ),
      ),
    );
  }

  void _handleDropSelected() {
    if (widget.enableParcelDropDetails &&
        (widget.rideType == 'Parcel' || widget.rideType == 'Delivery')) {
      Future.delayed(const Duration(milliseconds: 300), () async {
        await _showParcelDropDetailsPopup();
        _goToRideBooking();
      });
    } else {
      _goToRideBooking();
    }
  }

  void _addRecentDrop({required String name, required String address}) {
    RecentLocationsStore.add(name, address);
    _loadRecentDrops();
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
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 16),

              // Location Input Card
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
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Pickup Location (editable)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Green icon for pickup
                          Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              color: Colors.green,
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
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _pickupSearchController,
                              focusNode: _pickupFocusNode,
                              decoration: InputDecoration(
                                hintText: 'Pickup location',
                                hintStyle: TextStyle(
                                  color: _appTheme.textGrey,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                isDense: true,
                              ),
                              style: TextStyle(
                                color: _appTheme.textColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                              onTap: () {
                                setState(() {
                                  _pickupUserInteracted = true;
                                  _showPickupSearch = true;
                                  _showDropSearch = false;
                                });
                              },
                            ),
                          ),
                          // Current location icon button
                          IconButton(
                            icon: const Icon(
                              Icons.my_location,
                              color: Colors.black,
                              size: 20,
                            ),
                            onPressed: _setPickupToCurrent,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Add Stop field (black diamond with number 1) - conditionally shown
                      if (_showAddStopRow)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(width: 10),
                            // Black diamond icon with number 1
                            Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.rectangle,
                              ),
                              transform: Matrix4.rotationZ(0.785398), // 45 degrees
                              child: Transform.rotate(
                                angle: -0.785398, // Counter-rotate the text
                                child: const Center(
                                  child: Text(
                                    '1',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                          
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 7),
                                child: TextField(
                                  controller: _dropSearchController,
                                  decoration: InputDecoration(
                                    hintText: 'Add Stop',
                                    hintStyle: TextStyle(
                                      color: _appTheme.textGrey,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                    isDense: true,
                                  ),
                                  style: TextStyle(
                                    color: _appTheme.textColor,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _showDropSearch = true;
                                      _showPickupSearch = false;
                                    });
                                  },
                                ),
                              ),
                            ),
                            // Menu icon
                            IconButton(
                              icon: const Icon(
                                Icons.menu,
                                color: Colors.black,
                                size: 20,
                              ),
                              onPressed: () {
                                // Handle menu action
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 8),
                            // Close icon - removes the entire row
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.black,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _showAddStopRow = false; // Hide the row
                                  _dropSearchController.clear();
                                  _selectedLocation = null;
                                  _selectedLocationName = null;
                                  _showDropSearch = false;
                                });
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      
                      if (_showAddStopRow) const SizedBox(height: 16),
                      
                      // Drop Location (editable)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Orange/Red icon for drop
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: _appTheme.brandRed,
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
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _dropSearchController,
                              decoration: InputDecoration(
                                hintText: 'Drop location',
                                hintStyle: TextStyle(
                                  color: _appTheme.textGrey,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                isDense: true,
                              ),
                              style: TextStyle(
                                color: _appTheme.textColor,
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                              onTap: () {
                                setState(() {
                                  _showDropSearch = true;
                                  _showPickupSearch = false;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Action Buttons (at top, before suggestions)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _selectDropOnMap,
                        icon: Icon(
                          Icons.location_on,
                          color: _appTheme.brandRed,
                          size: 18,
                        ),
                        label: Text(
                          'Select on map',
                          style: TextStyle(
                           color: _appTheme.textColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          side: BorderSide(
                            color: _appTheme.textGrey.withOpacity(0.3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // Show the Add Stop row when button is clicked
                          setState(() {
                            _showAddStopRow = true;
                          });
                        },
                        icon: Icon(
                          Icons.add,
                          color: _appTheme.textColor,
                          size: 18,
                        ),
                        label: Text(
                          'Add stops',
                          style: TextStyle(
                           color: _appTheme.textColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          side: BorderSide(
                            color: _appTheme.textGrey.withOpacity(0.3),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Pickup Search Results (shown after action buttons)
              if (_showPickupSearch && _pickupSearchResults.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _appTheme.dividerColor,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: _pickupSearchResults.asMap().entries.map((entry) {
                        final index = entry.key;
                        final result = entry.value;
                        return Column(
                          children: [
                            InkWell(
                              onTap: () => _getPlaceDetails(
                                result['place_id'],
                                result['description'],
                                true,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: _appTheme.brandRed,
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
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            result['place_name'] ?? result['description'],
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w400,
                                              color: Colors.black,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          // Placeholder distance line for alignment with drop layout
                                          const SizedBox(height: 16),
                                          const SizedBox(height: 2),
                                          Text(
                                            result['description'],
                                            style: TextStyle(
                                              color: _appTheme.textGrey,
                                              fontSize: 12,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: Icon(
                                        Icons.favorite_border,
                                        color: _appTheme.textGrey,
                                        size: 20,
                                      ),
                                      onPressed: () {},
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (index < _pickupSearchResults.length - 1)
                              Divider(
                                height: 1,
                                thickness: 1,
                                color: Colors.grey.shade300,
                                indent: 0,
                                endIndent: 0,
                              ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),

              // Drop Search Results (shown after buttons)
              if (_showDropSearch && _dropSearchResults.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    margin: const EdgeInsets.only(top: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _appTheme.dividerColor,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: _dropSearchResults.asMap().entries.map((entry) {
                        final index = entry.key;
                        final result = entry.value;
                        return Column(
                          children: [
                            InkWell(
                              onTap: () => _getPlaceDetails(
                                result['place_id'],
                                result['description'],
                                false,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Circle icon (black with white center) - centered vertically
                                    Padding(padding: const EdgeInsets.only(top: 6), child: 
                                     Align(
                                      alignment: Alignment.center,
                                      child: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: const BoxDecoration(
                                          color: Colors.black,
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
                                    ),),
                                   
                                    const SizedBox(width: 12),
                                    // Location details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Place name (bold)
                                          Text(
                                            result['place_name'] ?? result['description'],
                                            style: TextStyle(
                                              fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          // Distance
                                          if (result['distance'] != null)
                                            Text(
                                              '${result['distance'].toStringAsFixed(1)} km',
                                              style: TextStyle(
                                                color: _appTheme.textGrey,
                                                fontSize: 13,
                                              ),
                                            )
                                          else
                                            const SizedBox(height: 16),
                                          const SizedBox(height: 2),
                                          // Full address
                                          Text(
                                            result['description'],
                                            style: TextStyle(
                                              color: _appTheme.textGrey,
                                              fontSize: 12,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Heart icon
                                    IconButton(
                                      icon: Icon(
                                        Icons.favorite_border,
                                        color: _appTheme.textGrey,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        // Toggle favorite
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Divider (except for last item)
                            if (index < _dropSearchResults.length - 1)
                              Divider(
                                height: 1,
                                thickness: 1,
                                color: Colors.grey.shade300,
                                indent: 0,
                                endIndent: 0,
                              ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Recent Locations List (real recent selections)
              if (!_showPickupSearch && !_showDropSearch && _recentDrops.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: _recentDrops
                        .map(
                          (item) => _recentLocationItem(
                            item['name'] ?? '',
                            item['address'] ?? '',
                            isFavorited: false,
                            onTap: () {
                              setState(() {
                                _selectedLocationName = item['name'];
                              });
                              if (widget.enableParcelDropDetails &&
                                  (widget.rideType == 'Parcel' || widget.rideType == 'Delivery')) {
                                Future.delayed(const Duration(milliseconds: 300), () async {
                                  await _showParcelDropDetailsPopup();
                                  _goToRideBooking();
                                });
                              } else {
                                _goToRideBooking();
                              }
                            },
                          ),
                        )
                        .toList(),
                  ),
                ),

              const SizedBox(height: 16),
            ],
          ),
        ),
        bottomNavigationBar: null,
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
                     fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
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

// Dashed Line Painter
class DashedLinePainter extends CustomPainter {
  final Color color;

  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    const dashWidth = 4.0;
    const dashSpace = 2.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Map Location Screen for selecting location on map
class DropMapLocationScreen extends StatefulWidget {
  final Function(LatLng, String)? onLocationSelected;
  final String apiKey;

  const DropMapLocationScreen({super.key, this.onLocationSelected, required this.apiKey});

  @override
  State<DropMapLocationScreen> createState() => _DropMapLocationScreenState();
}

class _DropMapLocationScreenState extends State<DropMapLocationScreen> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  String? _selectedLocationName;
  final TextEditingController _mapSearchController = TextEditingController();
  final FocusNode _mapSearchFocus = FocusNode();
  List<Map<String, dynamic>> _mapSearchResults = [];
  bool _isSearchingMap = false;

  Future<void> _searchPlacesOnMap(String query) async {
    if (query.isEmpty) {
      setState(() {
        _mapSearchResults = [];
      });
      return;
    }

    setState(() {
      _isSearchingMap = true;
    });

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(query)}&key=${widget.apiKey}',
      );
      final response = await http.get(url);
      final data = json.decode(response.body);

      if (data['status'] == 'OK') {
        final predictions = List<Map<String, dynamic>>.from(data['predictions']);
        // Enrich with lat/lng by fetching details in parallel
        final List<Map<String, dynamic>> enriched = [];
        for (final p in predictions) {
          final placeId = p['place_id'] as String?;
          if (placeId == null) continue;
          final detail = await _fetchPlaceLatLng(placeId);
          if (detail != null) {
            enriched.add({
              'place_id': placeId,
              'description': p['description'],
              'place_name': p['structured_formatting']?['main_text'],
              'lat': detail['lat'],
              'lng': detail['lng'],
            });
          }
        }
        setState(() {
          _mapSearchResults = enriched;
          _isSearchingMap = false;
        });
      } else {
        setState(() {
          _mapSearchResults = [];
          _isSearchingMap = false;
        });
      }
    } catch (e) {
      setState(() {
        _mapSearchResults = [];
        _isSearchingMap = false;
      });
    }
  }

  Future<Map<String, double>?> _fetchPlaceLatLng(String placeId) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=${widget.apiKey}',
      );
      final response = await http.get(url);
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        final loc = data['result']['geometry']['location'];
        return {'lat': (loc['lat'] as num).toDouble(), 'lng': (loc['lng'] as num).toDouble()};
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        actions: [
          if (_selectedLocation != null)
            TextButton(
              onPressed: () {
                if (widget.onLocationSelected != null &&
                    _selectedLocation != null &&
                    _selectedLocationName != null) {
                  widget.onLocationSelected!(_selectedLocation!, _selectedLocationName!);
                }
                Navigator.pop(context);
              },
              child: const Text('Done'),
            ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
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
                      markerId: const MarkerId('selected'),
                      position: _selectedLocation!,
                    ),
                  }
                : {},
          ),

          // Search box over map
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  child: TextField(
                    controller: _mapSearchController,
                    focusNode: _mapSearchFocus,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search location',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: _searchPlacesOnMap,
                  ),
                ),
                if (_isSearchingMap) const LinearProgressIndicator(minHeight: 2),
                if (_mapSearchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: _mapSearchResults.asMap().entries.map((entry) {
                        final index = entry.key;
                        final result = entry.value;
                        return Column(
                          children: [
                            InkWell(
                              onTap: () {
                                final lat = result['lat'] as double?;
                                final lng = result['lng'] as double?;
                                final name = result['place_name'] ?? result['description'] ?? '';
                                if (lat != null && lng != null) {
                                  setState(() {
                                    _selectedLocation = LatLng(lat, lng);
                                    _selectedLocationName = name;
                                    _mapSearchResults.clear();
                                    _mapSearchController.text = name;
                                  });
                                  _mapController?.animateCamera(
                                    CameraUpdate.newLatLngZoom(LatLng(lat, lng), 15),
                                  );
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.location_on, color: Colors.green, size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            result['place_name'] ?? result['description'] ?? '',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            result['description'] ?? '',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 12,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.favorite_border,
                                        color: Colors.grey.shade500,
                                        size: 20,
                                      ),
                                      onPressed: () {},
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (index < _mapSearchResults.length - 1)
                              Divider(height: 1, color: Colors.grey.shade300),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

