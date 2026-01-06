import 'package:flutter/material.dart';
import '../auth/login_screen.dart';
import '../services/services_screen.dart';
import '../history/history_screen.dart';
import '../common/notifications.dart';
import 'share_app_screen.dart';
import 'rate_rides_screen.dart';
import 'wallet_screen.dart';
import 'saved_addresses_screen.dart';
import 'help_support_screen.dart';
import '../../../core/services/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/app_localizations.dart';
import 'edit_profile_screen.dart';
import 'profile_store.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AppTheme _appTheme = AppTheme();
  String _firstName = '';
  String _lastName = '';
  String _phone = '';
  String _email = '';

  @override
  void initState() {
    super.initState();
    _appTheme.addListener(_onThemeChanged);
    _loadProfile();
  }

  @override
  void dispose() {
    _appTheme.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  Future<void> _loadProfile() async {
    final data = await ProfileStore.load();
    if (!mounted) return;
    setState(() {
      _firstName = data['firstName'] ?? '';
      _lastName = data['lastName'] ?? '';
      _phone = data['phone'] ?? '';
      _email = data['email'] ?? '';
    });
  }

  void _showLogoutDialog() {
    showDialog(
      
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Logout',
          style: TextStyle(color: _appTheme.textColor),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: _appTheme.textGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: _appTheme.textGrey),
            ),
          ),
          TextButton(
            onPressed: () {
              ApiClient.removeToken();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const LoginScreen(),
                ),
                (route) => false,
              );
            },
            child: Text(
              'Logout',
              style: TextStyle(color: _appTheme.brandRed),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final displayName = ('${_firstName.trim()} ${_lastName.trim()}').trim();
    final isGuest = displayName.isEmpty;
    final avatarLetter = (isGuest ? 'G' : displayName[0]).toUpperCase();
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
          ),
          title: Text(
            'Profile',
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
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                );
              },
            ),
          
            const SizedBox(width: 8),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // User Profile Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _appTheme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _appTheme.dividerColor, width: 1),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: _appTheme.brandRed,
                      child: Text(
                        avatarLetter,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isGuest ? localizations.guest : displayName,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: _appTheme.textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _phone.isNotEmpty ? _phone : '+91 -----------',
                            style: TextStyle(
                              fontSize: 14,
                              color: _appTheme.textGrey,
                            ),
                          ),
                          if (_email.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              _email,
                              style: TextStyle(
                                fontSize: 13,
                                color: _appTheme.textGrey,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () {
                              Navigator.push<bool>(
                                context,
                                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                              ).then((saved) {
                                if (saved == true) _loadProfile();
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _appTheme.brandRed.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: _appTheme.brandRed, width: 1),
                              ),
                              child: Text(
                                'Edit Profile',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _appTheme.brandRed,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // My Rides Section
              _buildSectionTitle('My Rides'),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _appTheme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _appTheme.dividerColor, width: 1),
                ),
                child: Column(
                  children: [
                    _buildMenuItem(
                      icon: Icons.history,
                      title: 'Ride History',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HistoryScreen(),
                          ),
                        );
                      },
                    ),
                    Divider(height: 1, color: _appTheme.dividerColor),
                    _buildMenuItem(
                      icon: Icons.star_outline,
                      title: 'Rate Your Rides',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RateRidesScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Payment & Wallet Section
              _buildSectionTitle('Payment & Wallet'),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _appTheme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _appTheme.dividerColor, width: 1),
                ),
                child: Column(
                  children: [
                  
                    Divider(height: 1, color: _appTheme.dividerColor),
                    _buildMenuItem(
                      icon: Icons.payment,
                      title: 'Payment Methods',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WalletScreen(),
                          ),
                        );
                      },
                    ),
                    Divider(height: 1, color: _appTheme.dividerColor),
                    _buildMenuItem(
                      icon: Icons.receipt_long,
                      title: 'Bills & Invoices',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Addresses Section
              _buildSectionTitle('Addresses'),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _appTheme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _appTheme.dividerColor, width: 1),
                ),
                child: Column(
                  children: [
                    _buildMenuItem(
                      icon: Icons.location_on_outlined,
                      title: 'Saved Addresses',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SavedAddressesScreen(),
                          ),
                        );
                      },
                    ),
                   
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Support & Help Section
              _buildSectionTitle('Support & Help'),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _appTheme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _appTheme.dividerColor, width: 1),
                ),
                child: Column(
                  children: [
                    _buildMenuItem(
                      icon: Icons.help_outline,
                      title: 'Help & Support',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HelpSupportScreen(),
                          ),
                        );
                      },
                    ),
                   
                    Divider(height: 1, color: _appTheme.dividerColor),
                    _buildMenuItem(
                      icon: Icons.description_outlined,
                      title: 'Terms & Conditions',
                      onTap: () {},
                    ),
                    Divider(height: 1, color: _appTheme.dividerColor),
                    _buildMenuItem(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Policy',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Settings Section
              _buildSectionTitle('Settings'),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _appTheme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _appTheme.dividerColor, width: 1),
                ),
                child: Column(
                  children: [
                    // _buildMenuItem(
                    //   icon: Icons.settings_outlined,
                    //   title: 'App Settings',
                    //   onTap: () {
                    //     Navigator.push(
                    //       context,
                    //       MaterialPageRoute(
                    //         builder: (_) => const AppSettingsScreen(),
                    //       ),
                    //     );
                    //   },
                    // ),
                    // Divider(height: 1, color: _appTheme.dividerColor),
                    _buildMenuItem(
                      icon: Icons.share_outlined,
                      title: 'Share App',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ShareAppScreen(),
                          ),
                        );
                      },
                    ),
                    Divider(height: 1, color: _appTheme.dividerColor),
                    _buildMenuItem(
                      icon: Icons.info_outline,
                      title: 'About',
                      subtitle: 'Version: 2.0.2',
                      onTap: () {},
                    ),
                    Divider(height: 1, color: _appTheme.dividerColor),
                    _buildMenuItem(
                      icon: Icons.logout,
                      title: 'Logout',
                      onTap: _showLogoutDialog,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Sign Out Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _showLogoutDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _appTheme.brandRed,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNav(context, 3),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: _appTheme.textColor,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _appTheme.iconBgColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: _appTheme.textColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: _appTheme.textColor,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: _appTheme.textGrey,
              ),
            )
          : null,
      trailing: Icon(
        _appTheme.rtlEnabled ? Icons.chevron_left : Icons.chevron_right,
        color: _appTheme.textGrey,
      ),
      onTap: onTap,
    );
  }

  Widget _buildBottomNav(BuildContext context, int currentIndex) {
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
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_outlined),
            activeIcon: Icon(Icons.grid_view),
            label: 'Services',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

