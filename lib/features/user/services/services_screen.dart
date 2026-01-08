import 'package:flutter/material.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';
import '../history/history_screen.dart';
import '../home/book_ride_screen.dart';
import '../common/notifications.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/app_localizations.dart';
import 'package:pikkar/core/services/api_service.dart';
import 'package:pikkar/core/models/api_models.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final AppTheme _appTheme = AppTheme();
  String? _selectedService;
  final PageController _promoController = PageController(viewportFraction: 0.92);
  int _promoIndex = 0;
  bool _loadingServices = false;
  List<_ServiceTileModel> _apiTiles = [];

  static const _promoAssets = <String>[
    'assets/carousel1.png',
    'assets/carousel2.png',
    'assets/carousel3.png',
  ];

  static const _fallbackTiles = <_ServiceTileModel>[
    // Ride
    _ServiceTileModel(
      title: 'Bike',
      subtitle: 'Quick rides',
      assetPath: 'assets/bike1.png',
      rideType: 'Bike',
      group: _ServiceGroup.ride,
    ),
    _ServiceTileModel(
      title: 'Auto',
      subtitle: 'Everyday commute',
      assetPath: 'assets/auto1.png',
      rideType: 'Auto',
      group: _ServiceGroup.ride,
    ),
    _ServiceTileModel(
      title: 'Cab',
      subtitle: 'Comfort rides',
      assetPath: 'assets/All Icons Set-Pikkar_Cab.png',
      rideType: 'Cab',
      group: _ServiceGroup.ride,
    ),
    // Delivery / Logistics
    _ServiceTileModel(
      title: 'Parcel',
      subtitle: 'Send packages',
      assetPath: 'assets/All Icons Set-Pikkar_Parcel Bike.png',
      rideType: 'Parcel',
      group: _ServiceGroup.delivery,
    ),
    _ServiceTileModel(
      title: 'Freight',
      subtitle: 'Move goods',
      assetPath: 'assets/All Icons Set-Pikkar_Tempo.png',
      rideType: 'Truck',
      group: _ServiceGroup.delivery,
    ),
    _ServiceTileModel(
      title: 'Ambulance',
      subtitle: 'Emergency',
      assetPath: 'assets/notify-image.png',
      rideType: 'Ambulance',
      group: _ServiceGroup.delivery,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _appTheme.addListener(_onThemeChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadServices());
  }

  @override
  void dispose() {
    _appTheme.removeListener(_onThemeChanged);
    _promoController.dispose();
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  String _assetForServiceName(String name) {
    final n = name.toLowerCase();
    if (n.contains('bike')) return 'assets/bike1.png';
    if (n.contains('auto')) return 'assets/auto1.png';
    if (n.contains('cab') || n.contains('car')) return 'assets/All Icons Set-Pikkar_Cab.png';
    if (n.contains('parcel')) return 'assets/All Icons Set-Pikkar_Parcel Bike.png';
    if (n.contains('truck') || n.contains('tempo') || n.contains('freight')) {
      return 'assets/All Icons Set-Pikkar_Tempo.png';
    }
    return 'assets/logo_red.png';
  }

  Future<void> _loadServices() async {
    if (_loadingServices) return;
    setState(() => _loadingServices = true);
    try {
      final results = await Future.wait([
        PikkarApi.vehicleTypes.getActive(),
        PikkarApi.parcelVehicles.getActive(),
      ]);

      final rideVehicles = results[0] as List<VehicleType>;
      final parcelRaw = results[1] as List<dynamic>;

      final rideTiles = rideVehicles.where((v) => v.isActive).map((v) {
        return _ServiceTileModel(
          title: v.name,
          subtitle: 'From ₹${v.baseFare.toStringAsFixed(0)}',
          assetPath: _assetForServiceName(v.name),
          rideType: v.name,
          group: _ServiceGroup.ride,
        );
      }).toList();

      final deliveryTiles = parcelRaw
          .whereType<Map<String, dynamic>>()
          .map((m) {
            final name = (m['name'] ?? m['title'] ?? 'Parcel').toString();
            return _ServiceTileModel(
              title: name,
              subtitle: 'Delivery service',
              assetPath: _assetForServiceName(name),
              rideType: name,
              group: _ServiceGroup.delivery,
            );
          })
          .toList();

      if (!mounted) return;
      setState(() {
        _apiTiles = [...rideTiles, ...deliveryTiles];
        _loadingServices = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingServices = false);
      debugPrint('Services API error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Directionality(
      textDirection: _appTheme.textDirection,
      child: Scaffold(
        backgroundColor: _appTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: _appTheme.cardColor,
          elevation: 0,
          automaticallyImplyLeading: false,
          leadingWidth: 56,
        leading: IconButton(
            icon: Icon(
              _appTheme.rtlEnabled ? Icons.arrow_forward : Icons.arrow_back,
              color: _appTheme.textColor,
            ),
            onPressed: () => Navigator.pop(context),
          ), title: Text(
            localizations.services,
            style: TextStyle(
              color: _appTheme.textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.notifications_outlined, color: _appTheme.textColor),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                );
              },
            ),
            // IconButton(
            //   icon: Icon(Icons.account_balance_wallet_outlined, color: _appTheme.textColor),
            //   onPressed: () {},
            // ),
            const SizedBox(width: 8),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'What are you looking for?',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: _appTheme.textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Pick a service to get started',
                            style: TextStyle(
                              fontSize: 13,
                              color: _appTheme.textGrey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _appTheme.cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _appTheme.dividerColor, width: 1),
                      ),
                      child: Icon(Icons.search, color: _appTheme.textGrey, size: 20),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Promo carousel (Rapido-like top banner)
              SizedBox(
                height: 150,
                child: PageView.builder(
                  controller: _promoController,
                  itemCount: _promoAssets.length,
                  onPageChanged: (i) => setState(() => _promoIndex = i),
                  itemBuilder: (context, index) => _promoCard(_promoAssets[index]),
                ),
              ),
              const SizedBox(height: 8),
              _promoDots(),
              const SizedBox(height: 18),

              // Ride section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _sectionHeader(title: 'Ride', subtitle: 'Fast pickups nearby'),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _servicesGrid(_ServiceGroup.ride),
              ),

              const SizedBox(height: 18),

              // Delivery section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _sectionHeader(title: 'Delivery', subtitle: 'Send anything safely'),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _servicesGrid(_ServiceGroup.delivery),
              ),

              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _comingSoonCard(),
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNav(context, 1),
      ),
    );
  }

  void _showBookRideSheet() {
    if (_selectedService == null) return;
    final base = _apiTiles.isNotEmpty ? _apiTiles : _fallbackTiles;
    final tile = base
        .where((t) => t.title == _selectedService || t.rideType == _selectedService)
        .cast<_ServiceTileModel?>()
        .firstWhere((_) => true, orElse: () => null);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: _appTheme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _appTheme.textGrey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Selected service info
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _appTheme.brandRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SizedBox(
                      width: 38,
                      height: 38,
                      child: (tile?.assetPath != null)
                          ? Image.asset(tile!.assetPath, fit: BoxFit.contain)
                          : Icon(_getServiceIcon(_selectedService!), color: _appTheme.brandRed, size: 32),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedService!,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _appTheme.textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getServiceDescription(_selectedService!),
                          style: TextStyle(
                            fontSize: 14,
                            color: _appTheme.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Book Ride button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close bottom sheet
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookRideScreen(
                          rideType: _getRideType(_selectedService!),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _appTheme.brandRed,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Book Ride',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getServiceIcon(String service) {
    switch (service) {
      case 'Cab':
        return Icons.local_taxi;
      case 'Parcel':
        return Icons.inventory_2;
      case 'Freight':
        return Icons.local_shipping;
      case 'Ambulance':
        return Icons.medical_services;
      default:
        return Icons.directions_car;
    }
  }

  String _getServiceDescription(String service) {
    switch (service) {
      case 'Cab':
        return 'Quick and reliable ride service.';
      case 'Parcel':
        return 'Secure and fast deliveries.';
      case 'Freight':
        return 'Efficient and reliable goods transport.';
      case 'Ambulance':
        return 'Emergency medical transport.';
      default:
        return '';
    }
  }

  String _getRideType(String service) {
    // Map service names to ride types used in BookRideScreen
    switch (service) {
      case 'Bike':
        return 'Bike';
      case 'Auto':
        return 'Auto';
      case 'Cab':
        return 'Cab';
      case 'Parcel':
        return 'Parcel';
      case 'Freight':
        return 'Truck'; // Freight uses Truck ride type
      case 'Ambulance':
        return 'Ambulance';
      default:
        return service;
    }
  }

  Widget _servicesGrid(_ServiceGroup group) {
    final base = _apiTiles.isNotEmpty ? _apiTiles : _fallbackTiles;
    final tiles = base.where((t) => t.group == group).toList();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tiles.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.18,
      ),
      itemBuilder: (context, index) => _serviceTile(tiles[index]),
    );
  }

  Widget _serviceTile(_ServiceTileModel tile) {
    return Material(
      color: _appTheme.cardColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          setState(() {
            // keep existing sheet logic (selectedService is the display title)
            _selectedService = tile.title;
          });
          _showBookRideSheet();
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _appTheme.dividerColor, width: 1),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      tile.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _appTheme.textColor,
                      ),
                    ),
                  ),
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: _appTheme.brandRed.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: _appTheme.brandRed,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                tile.subtitle,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _appTheme.textGrey,
                ),
              ),
              const Spacer(),
              Align(
                alignment: Alignment.bottomRight,
                child: SizedBox(
                  width: 86,
                  height: 56,
                  child: Image.asset(
                    tile.assetPath,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader({required String title, required String subtitle}) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _appTheme.textColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _appTheme.textGrey,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            foregroundColor: _appTheme.brandRed,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
          child: const Text('See all'),
        ),
      ],
    );
  }

  Widget _promoCard(String assetPath) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Container(
        decoration: BoxDecoration(
          color: _appTheme.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _appTheme.dividerColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(assetPath, fit: BoxFit.cover),
            Positioned(
              left: 14,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Special offers',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _promoDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _promoAssets.length,
        (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: i == _promoIndex ? 18 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: i == _promoIndex ? _appTheme.brandRed : _appTheme.textGrey.withOpacity(0.35),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }

  Widget _comingSoonCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _appTheme.brandRed.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _appTheme.brandRed.withOpacity(0.18), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _appTheme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _appTheme.dividerColor, width: 1),
            ),
            child: Icon(Icons.grid_view_rounded, color: _appTheme.brandRed),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'More services coming soon',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _appTheme.textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'We’re adding new options — stay tuned.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _appTheme.textGrey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _appTheme.brandRed,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'Notify me',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, int currentIndex) {
    final localizations = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: _appTheme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: _appTheme.cardColor,
        selectedItemColor: _appTheme.brandRed,
        unselectedItemColor: _appTheme.textGrey,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
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
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

enum _ServiceGroup { ride, delivery }

class _ServiceTileModel {
  final String title;
  final String subtitle;
  final String assetPath;
  final String rideType;
  final _ServiceGroup group;

  const _ServiceTileModel({
    required this.title,
    required this.subtitle,
    required this.assetPath,
    required this.rideType,
    required this.group,
  });
}

//******************************** Previous Code ********************************

// import 'package:flutter/material.dart';
// import '../home/home_screen.dart';
// import '../profile/profile_screen.dart';
// import '../history/history_screen.dart';
// import '../home/book_ride_screen.dart';
// import '../../../core/theme/app_theme.dart';
// import '../../../core/localization/app_localizations.dart';

// class ServicesScreen extends StatefulWidget {
//   const ServicesScreen({super.key});

//   @override
//   State<ServicesScreen> createState() => _ServicesScreenState();
// }

// class _ServicesScreenState extends State<ServicesScreen> {
//   final AppTheme _appTheme = AppTheme();
//   String? _selectedService;

//   @override
//   void initState() {
//     super.initState();
//     _appTheme.addListener(_onThemeChanged);
//   }

//   @override
//   void dispose() {
//     _appTheme.removeListener(_onThemeChanged);
//     super.dispose();
//   }

//   void _onThemeChanged() {
//     setState(() {});
//   }

//   @override
//   Widget build(BuildContext context) {
//     final localizations = AppLocalizations.of(context)!;
//     return Directionality(
//       textDirection: _appTheme.textDirection,
//       child: Scaffold(
//         backgroundColor: _appTheme.backgroundColor,
//         appBar: AppBar(
//           backgroundColor: _appTheme.cardColor,
//           elevation: 0,
//           automaticallyImplyLeading: false,
//           leadingWidth: 56,
//         leading: IconButton(
//             icon: Icon(
//               _appTheme.rtlEnabled ? Icons.arrow_forward : Icons.arrow_back,
//               color: _appTheme.textColor,
//             ),
//             onPressed: () => Navigator.pop(context),
//           ), title: Text(
//             localizations.services,
//             style: TextStyle(
//               color: _appTheme.textColor,
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           actions: [
//             IconButton(
//               icon: Icon(Icons.notifications_outlined, color: _appTheme.textColor),
//               onPressed: () {},
//             ),
//             IconButton(
//               icon: Icon(Icons.account_balance_wallet_outlined, color: _appTheme.textColor),
//               onPressed: () {},
//             ),
//             const SizedBox(width: 8),
//           ],
//         ),
//         body: SingleChildScrollView(
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Services Grid
//               Row(
//                 children: [
//                   Expanded(
//                     child: _serviceCard(
//                       context,
//                       title: 'Cab',
//                       description: 'Quick and reliable ride service.',
//                       icon: Icons.local_taxi,
//                       onTap: () {
//                         setState(() {
//                           _selectedService = 'Cab';
//                         });
//                         _showBookRideSheet();
//                       },
//                     ),
//                   ),
//                   const SizedBox(width: 16),
//                   Expanded(
//                     child: _serviceCard(
//                       context,
//                       title: 'Parcel',
//                       description: 'Secure and fast deliveries.',
//                       icon: Icons.inventory_2,
//                       onTap: () {
//                         setState(() {
//                           _selectedService = 'Parcel';
//                         });
//                         _showBookRideSheet();
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 16),
//               Row(
//                 children: [
//                   Expanded(
//                     child: _serviceCard(
//                       context,
//                       title: 'Freight',
//                       description: 'Efficient and reliable goods transport.',
//                       icon: Icons.local_shipping,
//                       onTap: () {
//                         setState(() {
//                           _selectedService = 'Freight';
//                         });
//                         _showBookRideSheet();
//                       },
//                     ),
//                   ),
//                   const SizedBox(width: 16),
//                   Expanded(
//                     child: _serviceCard(
//                       context,
//                       title: 'Ambulance',
//                       description: 'Emergency medical transport.',
//                       icon: Icons.medical_services,
//                       onTap: () {
//                         setState(() {
//                           _selectedService = 'Ambulance';
//                         });
//                         _showBookRideSheet();
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 16),
//               // More Services Coming Soon
//               Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.all(24),
//                 decoration: BoxDecoration(
//                   color: _appTheme.brandRed.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(16),
//                   border: Border.all(
//                     color: _appTheme.brandRed.withOpacity(0.3),
//                     width: 1,
//                   ),
//                 ),
//                 child: Column(
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                       decoration: BoxDecoration(
//                         color: _appTheme.cardColor,
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                       child: Text(
//                         'MORE SERVICES',
//                         style: TextStyle(
//                           fontSize: 10,
//                           fontWeight: FontWeight.bold,
//                           color: _appTheme.textColor,
//                           letterSpacing: 1.5,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 20),
//                     Text(
//                       'COMING SOON',
//                       style: TextStyle(
//                         fontSize: 32,
//                         fontWeight: FontWeight.bold,
//                         color: _appTheme.brandRed,
//                         letterSpacing: 1,
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                       decoration: BoxDecoration(
//                         color: _appTheme.textColor,
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                       child: Text(
//                         'STAY TUNED',
//                         style: TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.bold,
//                           color: _appTheme.cardColor,
//                           letterSpacing: 1,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 16),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text(
//                     'More Services',
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                       color: _appTheme.brandRed,
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   Text(
//                     'Coming soon',
//                     style: TextStyle(
//                       fontSize: 16,
//                       color: _appTheme.textGrey,
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//         bottomNavigationBar: _buildBottomNav(context, 1),
//       ),
//     );
//   }

//   void _showBookRideSheet() {
//     if (_selectedService == null) return;

//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) => Container(
//         decoration: BoxDecoration(
//           color: _appTheme.cardColor,
//           borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
//         ),
//         padding: const EdgeInsets.all(24),
//         child: SafeArea(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Handle bar
//               Center(
//                 child: Container(
//                   width: 40,
//                   height: 4,
//                   decoration: BoxDecoration(
//                     color: _appTheme.textGrey.withOpacity(0.3),
//                     borderRadius: BorderRadius.circular(2),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 24),
//               // Selected service info
//               Row(
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.all(12),
//                     decoration: BoxDecoration(
//                       color: _appTheme.brandRed.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Icon(
//                       _getServiceIcon(_selectedService!),
//                       color: _appTheme.brandRed,
//                       size: 32,
//                     ),
//                   ),
//                   const SizedBox(width: 16),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           _selectedService!,
//                           style: TextStyle(
//                             fontSize: 20,
//                             fontWeight: FontWeight.bold,
//                             color: _appTheme.textColor,
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                         Text(
//                           _getServiceDescription(_selectedService!),
//                           style: TextStyle(
//                             fontSize: 14,
//                             color: _appTheme.textGrey,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 32),
//               // Book Ride button
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: () {
//                     Navigator.pop(context); // Close bottom sheet
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => BookRideScreen(
//                           rideType: _getRideType(_selectedService!),
//                         ),
//                       ),
//                     );
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: _appTheme.brandRed,
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     elevation: 0,
//                   ),
//                   child: const Text(
//                     'Book Ride',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 16),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   IconData _getServiceIcon(String service) {
//     switch (service) {
//       case 'Cab':
//         return Icons.local_taxi;
//       case 'Parcel':
//         return Icons.inventory_2;
//       case 'Freight':
//         return Icons.local_shipping;
//       case 'Ambulance':
//         return Icons.medical_services;
//       default:
//         return Icons.directions_car;
//     }
//   }

//   String _getServiceDescription(String service) {
//     switch (service) {
//       case 'Cab':
//         return 'Quick and reliable ride service.';
//       case 'Parcel':
//         return 'Secure and fast deliveries.';
//       case 'Freight':
//         return 'Efficient and reliable goods transport.';
//       case 'Ambulance':
//         return 'Emergency medical transport.';
//       default:
//         return '';
//     }
//   }

//   String _getRideType(String service) {
//     // Map service names to ride types used in BookRideScreen
//     switch (service) {
//       case 'Cab':
//         return 'Cab';
//       case 'Parcel':
//         return 'Parcel';
//       case 'Freight':
//         return 'Truck'; // Freight uses Truck ride type
//       case 'Ambulance':
//         return 'Ambulance';
//       default:
//         return service;
//     }
//   }

//   Widget _serviceCard(
//     BuildContext context, {
//     required String title,
//     required String description,
//     required IconData icon,
//     required VoidCallback onTap,
//   }) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(16),
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: _appTheme.cardColor,
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(color: _appTheme.dividerColor, width: 1),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Icon/Image Container
//             Container(
//               height: 120,
//               width: double.infinity,
//               decoration: BoxDecoration(
//                 color: _appTheme.iconBgColor,
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Center(
//                 child: Icon(
//                   icon,
//                   size: 64,
//                   color: _appTheme.brandRed,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 12),
//             // Service Title
//             Text(
//               title,
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w600,
//                 color: _appTheme.brandRed,
//               ),
//             ),
//             const SizedBox(height: 4),
//             // Service Description
//             Text(
//               description,
//               style: TextStyle(
//                 fontSize: 12,
//                 color: _appTheme.textGrey,
//                 height: 1.4,
//               ),
//             ),
//             const SizedBox(height: 12),
//             // Navigation Arrow
//             Align(
//               alignment: Alignment.centerRight,
//               child: Container(
//                 width: 32,
//                 height: 32,
//                 decoration: BoxDecoration(
//                   color: _appTheme.brandRed,
//                   shape: BoxShape.circle,
//                 ),
//                 child: Icon(
//                   Icons.arrow_forward_ios,
//                   size: 16,
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildBottomNav(BuildContext context, int currentIndex) {
//     final localizations = AppLocalizations.of(context)!;
//     return Container(
//       decoration: BoxDecoration(
//         color: _appTheme.cardColor,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, -2),
//           ),
//         ],
//       ),
//       child: BottomNavigationBar(
//         currentIndex: currentIndex,
//         type: BottomNavigationBarType.fixed,
//         backgroundColor: _appTheme.cardColor,
//         selectedItemColor: _appTheme.brandRed,
//         unselectedItemColor: _appTheme.textGrey,
//         onTap: (index) {
//           if (index == 0) {
//             Navigator.pushReplacement(
//               context,
//               MaterialPageRoute(builder: (_) => const HomeScreen()),
//             );
//           } else if (index == 2) {
//             Navigator.push(
//               context,
//               MaterialPageRoute(builder: (_) => const HistoryScreen()),
//             );
//           } else if (index == 3) {
//             Navigator.push(
//               context,
//               MaterialPageRoute(builder: (_) => const ProfileScreen()),
//             );
//           }
//         },
//         items: [
//           BottomNavigationBarItem(
//             icon: const Icon(Icons.home_outlined),
//             label: localizations.home,
//           ),
//           BottomNavigationBarItem(
//             icon: const Icon(Icons.grid_view_outlined),
//             label: localizations.services,
//           ),
//           BottomNavigationBarItem(
//             icon: const Icon(Icons.history),
//             label: localizations.history,
//           ),
//           BottomNavigationBarItem(
//             icon: const Icon(Icons.settings_outlined),
//             label: localizations.setting,
//           ),
//         ],
//       ),
//     );
//   }
// }
