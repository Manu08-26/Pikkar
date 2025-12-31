import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'drop_screen.dart';
import '../../../core/theme/app_theme.dart';

class ParcelDeliveryScreen extends StatefulWidget {
  final String serviceType; // 'Parcel' or 'Delivery'

  const ParcelDeliveryScreen({
    super.key,
    required this.serviceType,
  });

  @override
  State<ParcelDeliveryScreen> createState() => _ParcelDeliveryScreenState();
}

class _ParcelDeliveryScreenState extends State<ParcelDeliveryScreen> {
  final AppTheme _appTheme = AppTheme();
  final TextEditingController _dropSearchController = TextEditingController();
  String _currentLocationName = "Getting location...";
  String? _pickupContactName;
  String? _pickupContactPhone;
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _appTheme.addListener(_onThemeChanged);
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _appTheme.removeListener(_onThemeChanged);
    _dropSearchController.dispose();
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        _isLoadingLocation = true;
      });

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _currentLocationName = "Enable location services";
          _isLoadingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() {
          _currentLocationName = "Tap to set location";
          _isLoadingLocation = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = '';
        
        if (place.street != null && place.street!.isNotEmpty) {
          address = place.street!;
        }
        if (place.thoroughfare != null && place.thoroughfare!.isNotEmpty) {
          if (address.isNotEmpty) {
            address += ', ${place.thoroughfare!}';
          } else {
            address = place.thoroughfare!;
          }
        }
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          if (address.isNotEmpty) {
            address += ', ${place.subLocality!}';
          } else {
            address = place.subLocality!;
          }
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          if (address.isEmpty) {
            address = place.locality!;
          } else if (!address.contains(place.locality!)) {
            address += ', ${place.locality!}';
          }
        }

        setState(() {
          _currentLocationName = address.isNotEmpty ? address : "Current Location";
          _isLoadingLocation = false;
        });
      } else {
        setState(() {
          _currentLocationName = "Current Location";
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      setState(() {
        _currentLocationName = "Tap to set location";
        _isLoadingLocation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _appTheme.textDirection,
      child: Scaffold(
        backgroundColor: Colors.white, // Light blue background
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                color: const Color(0xFFE8F4F8),
                child: Column(
                  children: [
                    const Text(
                      'Doorstep pickup and delivery',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF333333),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '= PARCEL',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Illustrations row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Image.asset(
                          'assets/All Icons Set-Pikkar_Parcel Bike.png',
                          width: 60,
                          height: 60,
                          errorBuilder: (_, __, ___) => const Icon(Icons.two_wheeler, size: 60),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/parcel1.png',
                              width: 40,
                              height: 40,
                              errorBuilder: (_, __, ___) => const Icon(Icons.inventory_2, size: 40),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.lunch_dining, size: 40, color: Colors.grey),
                            const SizedBox(width: 8),
                            const Icon(Icons.inventory_2, size: 40, color: Colors.brown),
                          ],
                        ),
                        Image.asset(
                          'assets/All Icons Set-Pikkar_Tempo.png',
                          width: 60,
                          height: 60,
                          errorBuilder: (_, __, ___) => const Icon(Icons.local_shipping, size: 60),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Pickup Location Card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.location_on, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Pickup from current location',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _currentLocationName,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18, color: Colors.grey),
                          onPressed: () {
                            // Edit pickup location
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            // Switch pickup/drop
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Switch',
                            style: TextStyle(color: _appTheme.brandRed),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Drop Location Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _appTheme.brandRed,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.location_on, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Drop to',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DropScreen(
                              rideType: widget.serviceType,
                              enableParcelDropDetails: true,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: _appTheme.brandRed, width: 1.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search, color: _appTheme.brandRed, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              'Search drop address',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Legal Disclaimers
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          children: [
                            const TextSpan(text: 'Read about '),
                            TextSpan(
                              text: 'prohibited items',
                              style: TextStyle(
                                color: _appTheme.brandRed,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          children: [
                            const TextSpan(text: 'By continuing, you agree to our '),
                            TextSpan(
                              text: 'T&Cs',
                              style: TextStyle(
                                color: _appTheme.brandRed,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

