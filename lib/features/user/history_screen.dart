import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'services_screen.dart';
import 'settings_screen.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/app_localizations.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final AppTheme _appTheme = AppTheme();

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
          title: Text(
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
              // No History Message
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
                    Icon(
                      Icons.history,
                      size: 64,
                      color: _appTheme.textGrey,
                    ),
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
                    ),
                  ],
                ),
              ),
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
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
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

