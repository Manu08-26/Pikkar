import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'notifications.dart';
import 'promo_code_details_screen.dart';
import 'drop_screen.dart';
import 'map_location_screen.dart';
import 'services_screen.dart';
import 'settings_screen.dart';
import 'history_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final AppTheme _appTheme = AppTheme();
  String _currentLocationName = "Getting location...";
  bool _isLoadingLocation = true;
  bool _hasTriedLocation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _appTheme.addListener(_onThemeChanged);
    _pageController.addListener(() {
      setState(() {
        currentPage = _pageController.page!;
      });
    });
    // Delay location fetch slightly to ensure widget is mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCurrentLocation();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Retry location fetch when dependencies change if still loading
    if ((_currentLocationName == "Loading location..." || 
         _currentLocationName == "Getting location..." ||
         _currentLocationName.isEmpty) && 
        _isLoadingLocation) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted && (_currentLocationName.isEmpty || _isLoadingLocation)) {
          _getCurrentLocation();
        }
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh location when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      _getCurrentLocation();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _appTheme.removeListener(_onThemeChanged);
    _pageController.dispose();
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  Future<void> _getCurrentLocation() async {
    if (!_hasTriedLocation) {
      _hasTriedLocation = true;
    }
    
    try {
      if (mounted) {
        setState(() {
          _isLoadingLocation = true;
          if (_currentLocationName.isEmpty || _currentLocationName == "Tap to set location") {
            _currentLocationName = "Getting location...";
          }
        });
      }

      print('🔍 Starting location fetch...');

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      print('📍 Location service enabled: $serviceEnabled');
      
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _currentLocationName = "Enable location services";
            _isLoadingLocation = false;
          });
        }
        return;
      }

      // Check location permissions (don't request here - already requested after splash)
      LocationPermission permission = await Geolocator.checkPermission();
      print('🔐 Current permission: $permission');
      
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _currentLocationName = "Tap to set location";
            _isLoadingLocation = false;
          });
        }
        return;
      }

      // Try to get last known position first (faster)
      Position? position;
      try {
        print('📍 Trying to get last known position...');
        position = await Geolocator.getLastKnownPosition();
        if (position != null) {
          print('✅ Got last known position: ${position.latitude}, ${position.longitude}');
        }
      } catch (e) {
        print('⚠️ Last known position failed: $e');
      }

      // If no last known position, get current position
      if (position == null) {
        print('📍 Getting current position...');
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium, // Changed from high to medium for faster response
        ).timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            print('⏱️ Location request timed out');
            throw TimeoutException('Location request timed out');
          },
        );
        print('✅ Got current position: ${position.latitude}, ${position.longitude}');
      }

      // Reverse geocode to get address
      print('🌐 Reverse geocoding...');
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⏱️ Geocoding timed out');
          return <Placemark>[];
        },
      );

      print('📍 Placemarks found: ${placemarks.length}');

      if (placemarks.isNotEmpty && mounted) {
        Placemark place = placemarks[0];
        String address = '';
        
        // Build address string - prioritize street, then subLocality, then locality
        if (place.street != null && place.street!.isNotEmpty) {
          address = place.street!;
        } else if (place.subThoroughfare != null && place.subThoroughfare!.isNotEmpty) {
          address = place.subThoroughfare!;
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

        print('✅ Address: $address');

        if (mounted) {
          setState(() {
            _currentLocationName = address.isNotEmpty ? address : "Current Location";
            _isLoadingLocation = false;
          });
        }
      } else if (mounted && position != null) {
        // If geocoding fails, show coordinates as fallback
        print('⚠️ Geocoding failed, showing coordinates');
        setState(() {
          _currentLocationName = "${position!.latitude.toStringAsFixed(4)}, ${position!.longitude.toStringAsFixed(4)}";
          _isLoadingLocation = false;
        });
      } else if (mounted) {
        setState(() {
          _currentLocationName = _currentLocationName.isEmpty ? "Tap to set location" : _currentLocationName;
          _isLoadingLocation = false;
        });
      }
    } catch (e, stackTrace) {
      print('❌ Error getting location: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          // Only set fallback if we don't have a location yet
          if (_currentLocationName.isEmpty || 
              _currentLocationName == "Getting location..." ||
              _currentLocationName == "Loading location...") {
            _currentLocationName = "Tap to set location";
          }
          _isLoadingLocation = false;
        });
      }
    }
  }

  PageController _pageController = PageController(viewportFraction: 0.8);
  double currentPage = 0.0;

  final List<String> images = [
    "assets/carousel1.png",
    "assets/carousel2.png",
    "assets/carousel3.png",
  ];

  @override 
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Directionality(
      textDirection: _appTheme.textDirection,
      child: Scaffold(
        backgroundColor: _appTheme.backgroundColor,

        /// APP BAR
        appBar: AppBar(
          backgroundColor: _appTheme.cardColor,
      elevation: 0,
      toolbarHeight: 80,
      automaticallyImplyLeading: false,
      leading: IconButton(
        icon: Icon(
          Icons.menu,
          color: _appTheme.textColor,
        ),
        onPressed: () {
          // Handle menu tap
        },
      ),
      title: InkWell(
        onTap: () {
          // Refresh location when tapped
          _getCurrentLocation();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const MapLocationScreen(),
            ),
          );
        },
        onLongPress: () {
          // Long press to manually refresh location
          _getCurrentLocation();
        },
        child: IntrinsicHeight(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Always show "Current location" label
              Text(
                "Current location",
                style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFF8E8E8E),
                  fontWeight: FontWeight.normal,
                ),
              ),
              const SizedBox(height: 2),
              // Location name row
              Row(
                children: [
                  Expanded(
                    child: _isLoadingLocation
                        ? Row(
                            children: [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(_appTheme.brandRed),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _currentLocationName.isNotEmpty 
                                      ? _currentLocationName 
                                      : "Getting location...",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: const Color(0xFF121212),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            _currentLocationName.isNotEmpty 
                                ? _currentLocationName 
                                : "Tap to set location",
                            style: TextStyle(
                              fontSize: 16,
                              color: _currentLocationName.isNotEmpty 
                                  ? const Color(0xFF121212)
                                  : const Color(0xFF8E8E8E),
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: const Color(0xFF121212),
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      titleSpacing: 8,
      centerTitle: false,

      /// TOP RIGHT ICONS
      actions: [
        Stack(
          clipBehavior: Clip.none,
          children: [
           
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: _appTheme.brandRed,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    "1",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
      ),

      /// BODY
       body: SingleChildScrollView(
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// PROMOTIONAL HEADER
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    child: Column(
                      children: [
                        Text(
                          "Pocket-Friendly Rides, Always!",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _appTheme.textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "No surge fees, no hidden charges - just low prices every time!",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: _appTheme.textGrey,
                          ),
                        ),
                      
                      ],
                    ),
                  ),

                 
                 
                 
                  const SizedBox(height: 24),

                  /// CHOOSE YOUR RIDE SECTION
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        Text(
                          'Choose Your Ride',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: _appTheme.textColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _rideOption('Bike', 'assets/bike1.png', () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const DropScreen(rideType: 'Bike'),
                                ),
                              );
                            }),
                            _rideOption('Auto', 'assets/auto1.png', () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const DropScreen(rideType: 'Auto'),
                                ),
                              );
                            }),
                              _rideOption('Cab', 'assets/car1.png', () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const DropScreen(rideType: 'Cab'),
                                ),
                              );
                            }),
                            _rideOption('Parcel', 'assets/parcel1.png', () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const DropScreen(rideType: 'Parcel'),
                                ),
                              );
                            }),
                            _rideOption('Truck', 'assets/truck1.png', () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const DropScreen(rideType: 'Truck'),
                                ),
                              );
                            }),
                          ],
                        ),
                        const SizedBox(height: 24),
                        /// TRENDING OFFERS
                        Text(
                          localizations.trendingOffers,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: _appTheme.textColor,
                          ),
                        ),
                        const SizedBox(height: 16),

                        _offerCard(
                          context,
                          title: "Flat 10% OFF",
                          subtitle: "Valid on your next ride",
                          code: "RIDE10",
                        ),
                        _offerCard(
                          context,
                          title: "Flat 15% OFF",
                          subtitle: "Valid till 05 Mar 2026",
                          code: "SAVE15",
                        ),

                        const SizedBox(height: 24),
                        
                        /// BOTTOM CONTENT IMAGE
                        SizedBox(
                          width: double.infinity,
                          child: Image.asset(
                            'assets/Bottom Content.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => SizedBox(),
                          ),
                        ),

                        const SizedBox(height: 40),

                        /// FOOTER
                        Center(
                          child: Column(
                            children: [
                              Text(
                                "Made For India | Rooted in Hyderabad",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: _appTheme.textGrey,
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        /// BOTTOM NAV
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: 0,
          backgroundColor: _appTheme.cardColor,
          selectedItemColor: _appTheme.brandRed,
          unselectedItemColor: _appTheme.textGrey,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            if (index == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ServicesScreen(),
                ),
              );
            } else if (index == 2) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HistoryScreen(),
                ),
              );
            } else if (index == 3) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            }
          },
          items: [
            BottomNavigationBarItem(
                icon: const Icon(Icons.home_outlined), label: localizations.home),
            BottomNavigationBarItem(
                icon: const Icon(Icons.grid_view_outlined), label: localizations.services),
            BottomNavigationBarItem(
                icon: const Icon(Icons.history), label: localizations.history),
            BottomNavigationBarItem(
                icon: const Icon(Icons.settings_outlined), label: localizations.setting),
          ],
        ),
      ),
    );
  }
  Widget _rideOption(String title, String imagePath, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: _appTheme.iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.location_on,
                    color: _appTheme.brandRed,
                    size: 40,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _appTheme.textColor,
            ),
          ),
        ],
      ),
    );
  }

      Widget _arrowButton(IconData icon) {
        final AppTheme _appTheme = AppTheme();
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _appTheme.iconBgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: _appTheme.textColor),
        );
      }

Widget bannerCard(String image) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(image, fit: BoxFit.cover),
      ),
    );
  }
 /// OFFER CARD
Widget _offerCard(
  BuildContext context, {
  required String title,
  required String subtitle,
  required String code,
}) {
  return InkWell(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PromoCodeDetailsScreen(
            code: code,
            title: title,
            subtitle: subtitle,
          ),
        ),
      );
    },
    child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _appTheme.iconBgColor, // Grey background
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _appTheme.dividerColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _appTheme.textColor, // Black text
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: _appTheme.textGrey, // Grey text
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text("Copied to clipboard"),
                      duration: const Duration(seconds: 2),
                      backgroundColor: _appTheme.brandRed,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                },
                child: Icon(
                  Icons.copy,
                  color: _appTheme.brandRed, // Red branding color
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _appTheme.brandRed.withOpacity(0.1), // Light red background
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _appTheme.brandRed.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              code,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _appTheme.brandRed, // Red branding color
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}

/// TOP ICON
class _TopIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopIcon({
    Key? key,
    required this.icon,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}
