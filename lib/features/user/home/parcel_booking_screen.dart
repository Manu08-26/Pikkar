import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/app_theme.dart';
import 'finding_driver_screen.dart';
import '../../../core/utils/responsive.dart';

class ParcelBookingScreen extends StatefulWidget {
  final String serviceType;
  final String pickupLocation;
  final String dropLocation;
  final String contactName;
  final String contactPhone;
  final String houseNo;
  final String? favoriteTag;

  const ParcelBookingScreen({
    super.key,
    required this.serviceType,
    required this.pickupLocation,
    required this.dropLocation,
    required this.contactName,
    required this.contactPhone,
    required this.houseNo,
    this.favoriteTag,
  });

  @override
  State<ParcelBookingScreen> createState() => _ParcelBookingScreenState();
}

class _ParcelBookingScreenState extends State<ParcelBookingScreen> {
  final AppTheme _appTheme = AppTheme();
  GoogleMapController? _mapController;
  LatLng? _pickupLatLng;
  LatLng? _dropLatLng;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  String _selectedService = 'Parcel';
  String _selectedPayment = 'Cash';

  @override
  void initState() {
    super.initState();
    _appTheme.addListener(_onThemeChanged);
    _initializeMap();
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

  Future<void> _initializeMap() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      _pickupLatLng = LatLng(position.latitude, position.longitude);
      
      // For demo, set drop location slightly away
      _dropLatLng = LatLng(
        position.latitude + 0.01,
        position.longitude + 0.01,
      );

      _createMarkers();
      _createRoute();
      
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(
                _pickupLatLng!.latitude < _dropLatLng!.latitude
                    ? _pickupLatLng!.latitude
                    : _dropLatLng!.latitude,
                _pickupLatLng!.longitude < _dropLatLng!.longitude
                    ? _pickupLatLng!.longitude
                    : _dropLatLng!.longitude,
              ),
              northeast: LatLng(
                _pickupLatLng!.latitude > _dropLatLng!.latitude
                    ? _pickupLatLng!.latitude
                    : _dropLatLng!.latitude,
                _pickupLatLng!.longitude > _dropLatLng!.longitude
                    ? _pickupLatLng!.longitude
                    : _dropLatLng!.longitude,
              ),
            ),
            100,
          ),
        );
      }
    } catch (e) {
      // Handle error
    }
  }

  void _createMarkers() {
    setState(() {
      _markers = {
        if (_pickupLatLng != null)
          Marker(
            markerId: const MarkerId('pickup'),
            position: _pickupLatLng!,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            infoWindow: InfoWindow(
              title: 'Pickup Location',
              snippet: widget.pickupLocation,
            ),
          ),
        if (_dropLatLng != null)
          Marker(
            markerId: const MarkerId('drop'),
            position: _dropLatLng!,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(
              title: 'Drop Location',
              snippet: widget.dropLocation,
            ),
          ),
      };
    });
  }

  void _createRoute() {
    if (_pickupLatLng != null && _dropLatLng != null) {
      setState(() {
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: [_pickupLatLng!, _dropLatLng!],
            color: Colors.black,
            width: 4,
          ),
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _appTheme.textDirection,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // Map
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _pickupLatLng ?? const LatLng(17.3850, 78.4867),
                zoom: 14,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
                _initializeMap();
              },
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
            ),

            // Bottom sheet - Fixed (Not Draggable)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: Responsive.hp(context, 50),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Container(
                      width: Responsive.spacing(context, 40),
                      height: Responsive.spacing(context, 4),
                      margin: EdgeInsets.symmetric(vertical: Responsive.spacing(context, 12)),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    Expanded(
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.symmetric(horizontal: Responsive.padding(context, 16)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                              // Service options
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildServiceOption(
                                      'Parcel',
                                      'Send upto 10 kgs',
                                      '₹88',
                                      'assets/All Icons Set-Pikkar_Parcel Bike.png',
                                      isSelected: _selectedService == 'Parcel',
                                      onTap: () {
                                        setState(() {
                                          _selectedService = 'Parcel';
                                        });
                                      },
                                    ),
                                  ),
                                  SizedBox(width: Responsive.spacing(context, 12)),
                                  Expanded(
                                    child: _buildServiceOption(
                                      'Parcel - 3 wheeler',
                                      '',
                                      '₹188',
                                      'assets/All Icons Set-Pikkar_Tempo.png',
                                      isSelected: _selectedService == 'Parcel - 3 wheeler',
                                      onTap: () {
                                        setState(() {
                                          _selectedService = 'Parcel - 3 wheeler';
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: Responsive.spacing(context, 20)),

                              // Payment and Offers
                              Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () {},
                                      child: Container(
                                        padding: EdgeInsets.symmetric(vertical: Responsive.padding(context, 12)),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.money,
                                              size: Responsive.iconSize(context, 20),
                                              color: Colors.grey,
                                            ),
                                            SizedBox(width: Responsive.spacing(context, 8)),
                                            Text(
                                              'Cash',
                                              style: TextStyle(fontSize: Responsive.fontSize(context, 14)),
                                            ),
                                            const Spacer(),
                                            Icon(
                                              Icons.chevron_right,
                                              size: Responsive.iconSize(context, 20),
                                              color: Colors.grey,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: Responsive.spacing(context, 16)),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () {},
                                      child: Container(
                                        padding: EdgeInsets.symmetric(vertical: Responsive.padding(context, 12)),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.percent,
                                              size: Responsive.iconSize(context, 20),
                                              color: Colors.grey,
                                            ),
                                            SizedBox(width: Responsive.spacing(context, 8)),
                                            Text(
                                              '% Offers',
                                              style: TextStyle(fontSize: Responsive.fontSize(context, 14)),
                                            ),
                                            const Spacer(),
                                            Icon(
                                              Icons.chevron_right,
                                              size: Responsive.iconSize(context, 20),
                                              color: Colors.grey,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: Responsive.spacing(context, 16)),

                              // PAY AT and Pickup/Drop toggle
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        vertical: Responsive.padding(context, 12),
                                        horizontal: Responsive.padding(context, 16),
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey.shade300),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.account_balance_wallet,
                                            size: Responsive.iconSize(context, 18),
                                            color: Colors.grey,
                                          ),
                                          SizedBox(width: Responsive.spacing(context, 8)),
                                          Text(
                                            'PAY AT',
                                            style: TextStyle(fontSize: Responsive.fontSize(context, 14)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: Responsive.spacing(context, 12)),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            padding: EdgeInsets.symmetric(vertical: Responsive.padding(context, 12)),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE53935), // Red color
                                              borderRadius: const BorderRadius.horizontal(
                                                left: Radius.circular(8),
                                              ),
                                            ),
                                            child: Center(
                                              child: Text(
                                                'Pickup',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: Responsive.fontSize(context, 14),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Container(
                                            padding: EdgeInsets.symmetric(vertical: Responsive.padding(context, 12)),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade200,
                                              borderRadius: const BorderRadius.horizontal(
                                                right: Radius.circular(8),
                                              ),
                                            ),
                                            child: Center(
                                              child: Text(
                                                'Drop',
                                                style: TextStyle(
                                                  color: Colors.grey.shade700,
                                                  fontSize: Responsive.fontSize(context, 14),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                            SizedBox(height: Responsive.spacing(context, 20)),
                          ],
                        ),
                      ),
                    ),

                    // Book Parcel button
                    Container(
                      padding: EdgeInsets.all(Responsive.padding(context, 16)),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FindingDriverScreen(
                                  pickupLocation: widget.pickupLocation,
                                  dropLocation: widget.dropLocation,
                                  rideType: _selectedService,
                                  pickupLatLng: _pickupLatLng,
                                  dropLatLng: _dropLatLng,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE53935), // Red color
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: Responsive.padding(context, 16)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Book Parcel',
                            style: TextStyle(
                              fontSize: Responsive.fontSize(context, 16),
                              fontWeight: FontWeight.bold,
                            ),
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
    );
  }

  Widget _buildServiceOption(
    String title,
    String subtitle,
    String price,
    String imagePath, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.red : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Image.asset(
              imagePath,
              width: 60,
              height: 60,
              errorBuilder: (_, __, ___) => const Icon(Icons.inventory_2, size: 60),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.black : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 8),
            Text(
              price,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.black : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

