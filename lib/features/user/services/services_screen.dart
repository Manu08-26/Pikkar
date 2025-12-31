import 'package:flutter/material.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';
import '../history/history_screen.dart';
import '../home/book_ride_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/app_localizations.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final AppTheme _appTheme = AppTheme();
  String? _selectedService;

  @override
  void initState() {
    super.initState();
    _appTheme.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _appTheme.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
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
          leading: IconButton(
            icon: Icon(
              _appTheme.rtlEnabled ? Icons.arrow_forward : Icons.arrow_back,
              color: _appTheme.textColor,
            ),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const HomeScreen(),
                ),
              );
            },
          ),
          title: Text(
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
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.account_balance_wallet_outlined, color: _appTheme.textColor),
              onPressed: () {},
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Services Grid
              Row(
                children: [
                  Expanded(
                    child: _serviceCard(
                      context,
                      title: 'Cab',
                      description: 'Quick and reliable ride service.',
                      icon: Icons.local_taxi,
                      onTap: () {
                        setState(() {
                          _selectedService = 'Cab';
                        });
                        _showBookRideSheet();
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _serviceCard(
                      context,
                      title: 'Parcel',
                      description: 'Secure and fast deliveries.',
                      icon: Icons.inventory_2,
                      onTap: () {
                        setState(() {
                          _selectedService = 'Parcel';
                        });
                        _showBookRideSheet();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _serviceCard(
                      context,
                      title: 'Freight',
                      description: 'Efficient and reliable goods transport.',
                      icon: Icons.local_shipping,
                      onTap: () {
                        setState(() {
                          _selectedService = 'Freight';
                        });
                        _showBookRideSheet();
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _serviceCard(
                      context,
                      title: 'Ambulance',
                      description: 'Emergency medical transport.',
                      icon: Icons.medical_services,
                      onTap: () {
                        setState(() {
                          _selectedService = 'Ambulance';
                        });
                        _showBookRideSheet();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // More Services Coming Soon
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _appTheme.brandRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _appTheme.brandRed.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _appTheme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'MORE SERVICES',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _appTheme.textColor,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'COMING SOON',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: _appTheme.brandRed,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _appTheme.textColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'STAY TUNED',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _appTheme.cardColor,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'More Services',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _appTheme.brandRed,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Coming soon',
                    style: TextStyle(
                      fontSize: 16,
                      color: _appTheme.textGrey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNav(context, 1),
      ),
    );
  }

  void _showBookRideSheet() {
    if (_selectedService == null) return;

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
                    child: Icon(
                      _getServiceIcon(_selectedService!),
                      color: _appTheme.brandRed,
                      size: 32,
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

  Widget _serviceCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _appTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _appTheme.dividerColor, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon/Image Container
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: _appTheme.iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 64,
                  color: _appTheme.brandRed,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Service Title
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _appTheme.brandRed,
              ),
            ),
            const SizedBox(height: 4),
            // Service Description
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: _appTheme.textGrey,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            // Navigation Arrow
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _appTheme.brandRed,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
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
            icon: const Icon(Icons.settings_outlined),
            label: localizations.setting,
          ),
        ],
      ),
    );
  }
}
