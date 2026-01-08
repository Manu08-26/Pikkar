import 'package:flutter/material.dart';
import '../services/services_screen.dart';
import '../profile/profile_screen.dart';
import '../common/notifications.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/app_localizations.dart';
import 'package:pikkar/core/services/api_service.dart';
import 'package:pikkar/core/models/api_models.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final AppTheme _appTheme = AppTheme();
  bool _loading = false;
  String? _error;
  List<Ride> _rides = [];

  @override
  void initState() {
    super.initState();
    _appTheme.addListener(_onThemeChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRides());
  }

  @override
  void dispose() {
    _appTheme.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  Future<void> _loadRides() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final raw = await PikkarApi.rides.getMyRides();
      final rides = raw
          .whereType<Map<String, dynamic>>()
          .map(Ride.fromJson)
          .toList();
      if (!mounted) return;
      setState(() {
        _rides = rides;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load rides';
        _loading = false;
      });
    }
  }

  String _fmtLocation(Location loc) {
    final name = (loc.name ?? '').trim();
    final addr = (loc.address ?? '').trim();
    if (name.isNotEmpty) return name;
    if (addr.isNotEmpty) return addr;
    return '${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)}';
  }

  Widget _rideCard(Ride ride) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _appTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _appTheme.dividerColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  ride.vehicleType,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _appTheme.textColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _appTheme.brandRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  ride.status,
                  style: TextStyle(
                    color: _appTheme.brandRed,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.circle, size: 10, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _fmtLocation(ride.pickup),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: _appTheme.textGrey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.circle, size: 10, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _fmtLocation(ride.dropoff),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: _appTheme.textGrey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '₹${(ride.fare ?? 0).toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _appTheme.textColor,
                ),
              ),
              const Spacer(),
              Text(
                '${ride.createdAt}',
                style: TextStyle(fontSize: 12, color: _appTheme.textGrey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
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
          ),title: Text(
            localizations.history,
            style: TextStyle(
              color: _appTheme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
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
        body: RefreshIndicator(
          color: _appTheme.brandRed,
          onRefresh: _loadRides,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (_loading)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: LinearProgressIndicator(
                    minHeight: 2,
                    color: _appTheme.brandRed,
                    backgroundColor: Colors.grey.shade200,
                  ),
                ),
              if (_error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _appTheme.brandRed.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _appTheme.brandRed.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: _appTheme.brandRed),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(color: _appTheme.textColor),
                        ),
                      ),
                      TextButton(
                        onPressed: _loadRides,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              if (!_loading && _error == null && _rides.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  decoration: BoxDecoration(
                    color: _appTheme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _appTheme.dividerColor, width: 1),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.history, size: 64, color: _appTheme.textGrey),
                      const SizedBox(height: 16),
                      Text(
                        localizations.noRideHistory,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: _appTheme.textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        localizations.rideHistoryWillAppear,
                        style: TextStyle(
                          fontSize: 14,
                          color: _appTheme.textGrey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              if (_rides.isNotEmpty) ...[
                ..._rides.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _rideCard(r),
                    )),
              ],
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNav(context, 2),
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
            Navigator.popUntil(context, (route) => route.isFirst);
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ServicesScreen()),
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

