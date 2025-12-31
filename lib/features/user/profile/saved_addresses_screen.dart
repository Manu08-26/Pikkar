import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class SavedAddressesScreen extends StatefulWidget {
  const SavedAddressesScreen({super.key});

  @override
  State<SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen> {
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
    return Directionality(
      textDirection: _appTheme.textDirection,
      child: Scaffold(
        backgroundColor: _appTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: _appTheme.cardColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              _appTheme.rtlEnabled ? Icons.arrow_forward : Icons.arrow_back,
              color: _appTheme.textColor,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Saved Addresses',
            style: TextStyle(
              color: _appTheme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.add, color: _appTheme.brandRed),
              onPressed: () {
                // Add new address
              },
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Home Address
            _buildAddressCard(
              icon: Icons.home,
              title: 'Home',
              address: '123, Main Street, Kondapur, Hyderabad, Telangana 500032',
              isDefault: true,
            ),
            const SizedBox(height: 16),
            // Work Address
            _buildAddressCard(
              icon: Icons.work,
              title: 'Work',
              address: '456, Tech Park, Hitech City, Hyderabad, Telangana 500081',
              isDefault: false,
            ),
            const SizedBox(height: 16),
            // Other Address
            _buildAddressCard(
              icon: Icons.location_on,
              title: 'Lulu Mall',
              address: '20-01-5/B, Kondapur, Hyderabad, Telangana 500032',
              isDefault: false,
            ),
            const SizedBox(height: 16),
            // Add New Address Button
            InkWell(
              onTap: () {
                // Add new address
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _appTheme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _appTheme.brandRed,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, color: _appTheme.brandRed),
                    const SizedBox(width: 8),
                    Text(
                      'Add New Address',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _appTheme.brandRed,
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

  Widget _buildAddressCard({
    required IconData icon,
    required String title,
    required String address,
    required bool isDefault,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _appTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDefault ? _appTheme.brandRed : _appTheme.dividerColor,
          width: isDefault ? 2 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDefault
                  ? _appTheme.brandRed.withOpacity(0.1)
                  : _appTheme.iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isDefault ? _appTheme.brandRed : _appTheme.textColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _appTheme.textColor,
                      ),
                    ),
                    if (isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _appTheme.brandRed,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Default',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  address,
                  style: TextStyle(
                    fontSize: 14,
                    color: _appTheme.textGrey,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton(
            icon: Icon(Icons.more_vert, color: _appTheme.textGrey),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: Text('Edit'),
                onTap: () {},
              ),
              PopupMenuItem(
                child: Text('Set as Default'),
                onTap: () {},
              ),
              PopupMenuItem(
                child: Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

