import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../common/notifications.dart';
import '../common/promo_code_details_screen.dart';
import 'drop_screen.dart';
import 'book_ride_screen.dart';
import 'map_location_screen.dart';
import 'parcel_delivery_screen.dart';
import '../services/services_screen.dart';
import '../profile/profile_screen.dart';
import '../history/history_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/app_localizations.dart';
import 'ride_booking_screen.dart';

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
  bool _isFetchingLocation = false; // Prevent concurrent requests
  int _retryCount = 0;
  static const int _maxRetries = 3;
  String? _selectedDeliveryService; // Track selected delivery service

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
    // Start auto-sliding carousel for quotes after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startCarouselTimer();
      }
    });
    // Delay location fetch slightly to ensure widget is mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isFetchingLocation) {
    _getCurrentLocation();
      }
    });
  }

  void _startCarouselTimer() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_quotePageController.hasClients) {
        final currentPage = _quotePageController.page?.round() ?? 0;
        final nextPage = (currentPage + 1) % 3; // 3 quotes total
        _quotePageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Retry location fetch when dependencies change if still loading
    if ((_currentLocationName == "Loading location..." || 
         _currentLocationName == "Getting location..." ||
         _currentLocationName.isEmpty) && 
        _isLoadingLocation &&
        !_isFetchingLocation &&
        _retryCount < _maxRetries) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted && !_isFetchingLocation && (_currentLocationName.isEmpty || _isLoadingLocation)) {
          _getCurrentLocation();
        }
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh location when app comes to foreground
    if (state == AppLifecycleState.resumed && mounted && !_isFetchingLocation) {
      // Reset retry count when app resumes
      _retryCount = 0;
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && !_isFetchingLocation) {
          _getCurrentLocation();
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _appTheme.removeListener(_onThemeChanged);
    _pageController.dispose();
    _quotePageController.dispose();
    _carouselTimer?.cancel();
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  Future<void> _getCurrentLocation() async {
    // Prevent concurrent requests
    if (_isFetchingLocation) {
      print('⏸️ Location fetch already in progress, skipping...');
      return;
    }

    // Check retry limit
    if (_retryCount >= _maxRetries) {
      print('⛔ Max retries reached, not fetching location');
      if (mounted) {
        setState(() {
          if (_currentLocationName.isEmpty || 
              _currentLocationName == "Getting location..." ||
              _currentLocationName == "Tap to set location") {
            _currentLocationName = "Unable to get location";
          }
          _isLoadingLocation = false;
        });
      }
      return;
    }

    _isFetchingLocation = true;
    if (!_hasTriedLocation) {
      _hasTriedLocation = true;
    }
    
    try {
      if (mounted) {
        setState(() {
          _isLoadingLocation = true;
          if (_currentLocationName.isEmpty || 
              _currentLocationName == "Tap to set location" ||
              _currentLocationName == "Unable to get location") {
            _currentLocationName = "Getting location...";
          }
        });
      }

      print('🔍 Starting location fetch... (Attempt ${_retryCount + 1}/$_maxRetries)');

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      print('📍 Location service enabled: $serviceEnabled');
      
      if (!serviceEnabled) {
        if (mounted) {
        setState(() {
            _currentLocationName = "Enable location services";
          _isLoadingLocation = false;
            _isFetchingLocation = false;
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
            _isFetchingLocation = false;
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
        try {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 20), // Increased timeout
          ).timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              print('⏱️ Location request timed out');
              throw TimeoutException('Location request timed out');
            },
          );
          print('✅ Got current position: ${position.latitude}, ${position.longitude}');
        } catch (e) {
          print('⚠️ getCurrentPosition failed: $e');
          // If current position fails, try with lower accuracy
          try {
            position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.low,
              timeLimit: const Duration(seconds: 15),
            ).timeout(
              const Duration(seconds: 15),
            );
            print('✅ Got current position (low accuracy): ${position.latitude}, ${position.longitude}');
          } catch (e2) {
            print('❌ Low accuracy position also failed: $e2');
            rethrow;
          }
        }
      }

      // Reverse geocode to get address
      print('🌐 Reverse geocoding...');
      List<Placemark> placemarks = [];
      try {
        placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
        ).timeout(
          const Duration(seconds: 15), // Increased timeout
          onTimeout: () {
            print('⏱️ Geocoding timed out');
            return <Placemark>[];
          },
        );
        print('📍 Placemarks found: ${placemarks.length}');
      } catch (e) {
        print('⚠️ Geocoding error: $e');
        placemarks = [];
      }

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
            _isFetchingLocation = false;
            _retryCount = 0; // Reset retry count on success
          });
          print('🔄 setState called with location: $_currentLocationName');
        }
      } else if (mounted && position != null) {
        // If geocoding fails, show coordinates as fallback
        print('⚠️ Geocoding failed, showing coordinates');
        setState(() {
          _currentLocationName = "${position!.latitude.toStringAsFixed(4)}, ${position!.longitude.toStringAsFixed(4)}";
          _isLoadingLocation = false;
          _isFetchingLocation = false;
          _retryCount = 0; // Reset retry count on success
        });
      } else if (mounted) {
        setState(() {
          _currentLocationName = _currentLocationName.isEmpty ? "Tap to set location" : _currentLocationName;
          _isLoadingLocation = false;
          _isFetchingLocation = false;
        });
      }
    } catch (e, stackTrace) {
      print('❌ Error getting location: $e');
      print('Stack trace: $stackTrace');
      
      _retryCount++;
      _isFetchingLocation = false;
      
      if (mounted) {
        if (_retryCount < _maxRetries) {
          // Retry after a delay
          print('🔄 Retrying location fetch in 2 seconds... (${_retryCount}/$_maxRetries)');
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted && !_isFetchingLocation) {
              _getCurrentLocation();
            }
          });
          setState(() {
            _isLoadingLocation = true;
            _currentLocationName = "Retrying...";
        });
      } else {
          // Max retries reached
        setState(() {
            // Only set fallback if we don't have a location yet
            if (_currentLocationName.isEmpty || 
                _currentLocationName == "Getting location..." ||
                _currentLocationName == "Loading location..." ||
                _currentLocationName == "Retrying...") {
              _currentLocationName = "Tap to set location";
            }
          _isLoadingLocation = false;
          });
        }
      }
    }
  }

  PageController _pageController = PageController(viewportFraction: 0.8);
  final PageController _quotePageController = PageController();
  double currentPage = 0.0;
  Timer? _carouselTimer;

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

      appBar: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            toolbarHeight: 80,
            automaticallyImplyLeading: false,
            surfaceTintColor: Colors.transparent,
            // leading: IconButton(
            //   icon: Icon(
            //     Icons.menu,
            //     color: _appTheme.textColor,
            //   ),
            //   onPressed: () {
            //     // Handle menu tap
            //   },
            // ),
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
              child: Builder(
                builder: (context) {
                  print('🎨 Building AppBar title. Location: "$_currentLocationName", Loading: $_isLoadingLocation');
                  return Padding(
                    padding: const EdgeInsets.all(12),
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
                          fontFamily: 'Alata',
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Location name row
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.5,
                            child: _isLoadingLocation
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
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
                                            fontWeight: FontWeight.w500,
                                            fontFamily: 'Alata',
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
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Alata',
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
                  );
                },
              ),
            ),
            titleSpacing: 8,
            centerTitle: false,

      /// TOP RIGHT ICONS
      actions: [
        // Notification icon with red dot
        Stack(
          children: [
            IconButton(
              icon: Icon(
                Icons.notifications_outlined,
                color: _appTheme.textColor,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                );
              },
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _appTheme.brandRed,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
          ),
        ),
      /// BODY
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
           
            /// HEADER - QUOTES CAROUSEL
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 25),
              child: Column(
                
                children: [
                  SizedBox(
                    height: 100,
                    child: PageView(
                      controller: _quotePageController,
                      children: [
                        // Quote 1
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Pocket-Friendly Rides, Always!",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Akatab',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "No surge fees, no hidden charges - just low prices every time!",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                fontFamily: 'Akatab',
                              ),
                            ),
                          ],
                        ),
                        // Quote 2
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Fast & Reliable Service",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Get to your destination quickly and safely with our trusted drivers!",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                fontFamily: 'Akatab',
                              ),
                            ),
                          ],
                        ),
                        // Quote 3
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "24/7 Available",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Book a ride anytime, anywhere - we're always here for you!",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                fontFamily: 'Akatab',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Carousel dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      return AnimatedBuilder(
                        animation: _quotePageController,
                        builder: (context, child) {
                          final currentPage = _quotePageController.hasClients
                              ? (_quotePageController.page ?? 0).round()
                              : 0;
                          return Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: currentPage == index
                                  ? _appTheme.brandRed
                                  : Colors.grey.shade300,
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),

            // const SizedBox(height: 24),

            /// DELIVERY SERVICES
            Container(
              color: Colors.white,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Delivery Services',
                    style: TextStyle(fontSize: 14, 
                    fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        
                        _rideOption('Parcel', 'assets/All Icons Set-Pikkar_Parcel Bike.png', () {
                          print('🔵 Parcel tapped!');
                          try {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) {
                                  print('🔵 Building ParcelDeliveryScreen');
                                  return const ParcelDeliveryScreen(
                                    serviceType: 'Parcel',
                                  );
                                },
                              ),
                            ).then((_) {
                              print('🔵 Navigation completed');
                          setState(() {
                                _selectedDeliveryService = null;
                              });
                            }).catchError((error) {
                              print('❌ Navigation error: $error');
                          });
                          } catch (e, stackTrace) {
                            print('❌ Error navigating: $e');
                            print('Stack trace: $stackTrace');
                          }
                        }, isSelected: _selectedDeliveryService == 'Parcel'),
                        const SizedBox(width: 20),
                        _rideOption('Delivery', 'assets/All Icons Set-Pikkar_Tempo.png', () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ParcelDeliveryScreen(
                                serviceType: 'Delivery',
                              ),
                            ),
                          ).then((_) {
                          setState(() {
                              _selectedDeliveryService = null;
                            });
                          });
                        }, isSelected: _selectedDeliveryService == 'Delivery'),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ServicesScreen(),
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                alignment: Alignment.center,
                                
                                child: const Text(
                                  'See all',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const SizedBox(height: 20), // Spacing to align with other options
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// BOOK RIDE SECTION
                  const Text(
                    'Book Ride',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Search Bar
                  InkWell(
                    onTap: () {
                      // Navigate to RideBookingScreen when search is tapped
                      final rideType = _selectedDeliveryService ?? 'Parcel';
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DropScreen(rideType: rideType),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search,
                            color:_appTheme.textColor,
                            fontWeight: FontWeight.w500,
                            
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Where to drop?',
                            style: TextStyle(
                              color: _appTheme.textColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Suggested Locations
                  _buildSuggestedLocation(
                    context,
                    name: 'Lulu Mall',
                    address: '20-01-5/B, Kondapur, Hyderabad, Telangana, 50002',
                    isFavorite: true,
                    isRecent: false,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BookRideScreen(
                            rideType: 'Parcel',
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildSuggestedLocation(
                    context,
                    name: 'Hotel Grand Sitara',
                    address: '20-01-5/B, Kondapur, Hyderabad, Telangana, 50002',
                    isFavorite: false,
                    isRecent: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BookRideScreen(
                            rideType: 'Parcel',
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildSuggestedLocation(
                    context,
                    name: 'GVK Mall',
                    address: '20-01-5/B, Kondapur, Hyderabad, Telangana, 50002',
                    isFavorite: false,
                    isRecent: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BookRideScreen(
                            rideType: 'Parcel',
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  /// TRENDING OFFERS
                  Text(
                    'Trending Offers',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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

                  /// BANNER
                  Image.asset(
                    'assets/Bottom Content.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(),
                  ),

                  const SizedBox(height: 40),

                  /// FOOTER
                  Center(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/flag_india.png',
                              width: 16,
                              height: 16,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox(width: 16, height: 16),
                            ),
                            const SizedBox(width: 6),
                            const Text("Made in India"),
                            const SizedBox(width: 8),
                            const Text("|"),
                            const SizedBox(width: 8),
                            const Text("Rooted in"),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                            Image.asset(
                              'assets/charminar.png',
                              width: 20,
                              height: 18,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox(width: 20, height: 18),
                            ),
                                Transform.translate(
                                  offset: const Offset(-3, 0),
                                  child: const Text("yderabad"),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      /// BOTTOM NAV
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: _appTheme.brandRed,
        unselectedItemColor: _appTheme.textGrey,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ServicesScreen()),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            );
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            label: localizations.home,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.grid_view_outlined),
            label: localizations.services,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.history),
            label: localizations.history,
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    ),
  );
}

  Widget _rideOption(String title, String imagePath, VoidCallback onTap, {bool isSelected = false}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        print('🔵 Tapped: $title');
        onTap();
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
      borderRadius: BorderRadius.circular(12),
            child: Column(
            mainAxisSize: MainAxisSize.min,
              children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected 
                    ? _appTheme.brandRed 
                    : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: _appTheme.brandRed.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  isAntiAlias: true,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.location_on,
                      color: _appTheme.brandRed,
                      size: 50,
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
                  color: Colors.black,
                  ),
                ),
              ],
          ),
        ),
            ),
          );
        }

  Widget _buildSuggestedLocation(
    BuildContext context, {
    required String name,
    required String address,
    required bool isFavorite,
    required bool isRecent,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Clock icon for recent locations
            if (isRecent)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.access_time,
                  size: 18,
                  color: Colors.grey.shade600,
                ),
              ),
            // Location icon if not recent
            if (!isRecent)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.location_on,
                  size: 18,
                  color: _appTheme.brandRed,
                ),
              ),
            // Location details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Heart icon
            Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? _appTheme.brandRed : Colors.grey.shade400,
              size: 20,
            ),
          ],
        ),
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
       color: Colors.white, // Grey background
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
                        fontWeight: FontWeight.w500,
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

  /// EARNING BANNER
  Widget _buildEarningBanner() {
    return Container(
      width: double.infinity,
      height: 200,
      margin: const EdgeInsets.only(left: 1, right: 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFFEEF1F4), // Light grey background
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Green diagonal section on the right with vector
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: ClipPath(
              clipper: DiagonalClipper(),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.42,
                child: Stack(
                  children: [
                    // Vector background (green diagonal)
                    Positioned.fill(
                      child: Image.asset(
                        'assets/home_bottom_vector.png',
                        fit: BoxFit.cover,
                        alignment: Alignment.centerRight,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: const Color(0xFF4CAF50),
                        ),
                      ),
                    ),
                    // Bike illustration - positioned on the left side of green section
                    Positioned(
                      left: 20,
                      bottom: 20,
                      child: Image.asset(
                        'assets/home_bottom_bike.png',
                        height: 120,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const SizedBox(),
                      ),
                    ),
                    // Auto illustration - positioned on the right side of green section
                    Positioned(
                      right: 0,
                      bottom: 15,
                      child: Image.asset(
                        'assets/home_bottom_auto.png',
                        height: 130,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const SizedBox(),
                      ),
                    ),
                    // T&C Apply text
                    Positioned(
                      right: 12,
                      bottom: 8,
                      child: Text(
                        'T&C Apply',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Text content on the left
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.58,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Main heading - line 1
                  Text(
                    'Start Earning Today',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _appTheme.textColor,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Main heading - line 2
                  Text(
                    'and Earn ₹250/-',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _appTheme.textColor,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Main heading - line 3
                  Text(
                    'Joining Bonus',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _appTheme.textColor,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Main heading - line 4
                  Text(
                    'Instantly!',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _appTheme.textColor,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Subtitle box
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _appTheme.textGrey.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Switch to Pikkar and keep\n100% of your income - No\ncommission, No worries! for\nlifetime',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Diagonal Clipper for green section
class DiagonalClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    // Start from top-left of the diagonal section
    path.moveTo(size.width * 0.4, 0);
    // Line to top-right
    path.lineTo(size.width, 0);
    // Line to bottom-right
    path.lineTo(size.width, size.height);
    // Diagonal line back to bottom-left of diagonal section
    path.lineTo(size.width * 0.2, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
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
