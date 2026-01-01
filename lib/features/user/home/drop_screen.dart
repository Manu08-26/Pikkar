import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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
  String _selectedForMe = "For me";
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
        _updateMapCamera();
        _getCurrentLocationName().then((_) {
          if (mounted) {
            setState(() {
              _pickupLocation = LatLng(_currentLocation!.latitude, _currentLocation!.longitude);
              _pickupLocationName = _currentLocationName;
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
            
            // For Parcel/Delivery, show contact details popup
            if (widget.enableParcelDropDetails &&
                (widget.rideType == 'Parcel' || widget.rideType == 'Delivery')) {
              Future.delayed(const Duration(milliseconds: 300), () {
                _showParcelDropDetailsPopup();
              });
            }
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
            
            // For Parcel/Delivery, show contact details popup
            if (widget.enableParcelDropDetails &&
                (widget.rideType == 'Parcel' || widget.rideType == 'Delivery')) {
              Future.delayed(const Duration(milliseconds: 300), () {
                _showParcelDropDetailsPopup();
              });
            }
          },
        ),
      ),
    );
  }

  void _showParcelDropDetailsPopup() {
    if (_selectedLocationName == null) return;
    
    showModalBottomSheet(
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
                      // Pickup Location
                      InkWell(
                        onTap: () {
                          setState(() {
                            _showPickupSearch = true;
                            _showDropSearch = false;
                          });
                        },
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Green icon for pickup
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _pickupLocationName ?? _currentLocationName,
                                    style: TextStyle(
                                      color: _appTheme.textColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Pickup Search Results (shown below the card)
                      if (_showPickupSearch && _pickupSearchResults.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _appTheme.dividerColor,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: _pickupSearchResults.map((result) {
                              return InkWell(
                                onTap: () => _getPlaceDetails(
                                  result['place_id'],
                                  result['description'],
                                  true,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        color: _appTheme.brandRed,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          result['place_name'] ?? result['description'],
                                          style: TextStyle(
                                           color: _appTheme.textColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      const SizedBox(height: 16),
                      // Drop Location
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Red icon for drop with white dot
                          Container(
                            width: 16,
                            height: 16,
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
                                hintStyle: TextStyle(color: _appTheme.textColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 16,),
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
                          // Add stops functionality
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Add stops feature coming soon'),
                              backgroundColor: _appTheme.brandRed,
                            ),
                          );
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
                                    // Circ
                                    //le icon (red with white center) - centered vertically
                                    Padding(padding: const EdgeInsets.only(top: 6), child: 
                                     Align(
                                      alignment: Alignment.center,
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
                          // For Parcel/Delivery, show contact details popup
                          if (widget.enableParcelDropDetails &&
                              (widget.rideType == 'Parcel' || widget.rideType == 'Delivery')) {
                            Future.delayed(const Duration(milliseconds: 300), () {
                              _showParcelDropDetailsPopup();
                            });
                          }
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
                          // For Parcel/Delivery, show contact details popup
                          if (widget.enableParcelDropDetails &&
                              (widget.rideType == 'Parcel' || widget.rideType == 'Delivery')) {
                            Future.delayed(const Duration(milliseconds: 300), () {
                              _showParcelDropDetailsPopup();
                            });
                          }
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
                          // For Parcel/Delivery, show contact details popup
                          if (widget.enableParcelDropDetails &&
                              (widget.rideType == 'Parcel' || widget.rideType == 'Delivery')) {
                            Future.delayed(const Duration(milliseconds: 300), () {
                              _showParcelDropDetailsPopup();
                            });
                          }
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
                          // For Parcel/Delivery, show contact details popup
                          if (widget.enableParcelDropDetails &&
                              (widget.rideType == 'Parcel' || widget.rideType == 'Delivery')) {
                            Future.delayed(const Duration(milliseconds: 300), () {
                              _showParcelDropDetailsPopup();
                            });
                          }
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

