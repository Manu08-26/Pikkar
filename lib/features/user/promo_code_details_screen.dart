import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/app_localizations.dart';

class PromoCodeDetailsScreen extends StatelessWidget {
  final String code;
  final String title;
  final String subtitle;
  final String description;
  final List<String> services;
  final List<String> vehicles;
  final String validTill;

  const PromoCodeDetailsScreen({
    super.key,
    required this.code,
    required this.title,
    required this.subtitle,
    this.description = '',
    this.services = const [],
    this.vehicles = const [],
    this.validTill = '',
  });

  @override
  Widget build(BuildContext context) {
    final appTheme = AppTheme();
    final localizations = AppLocalizations.of(context)!;

    // Default data based on promo code
    final Map<String, Map<String, dynamic>> promoData = {
      'RIDE10': {
        'description': 'Get 10% off on your next ride.',
        'services': ['Cab'],
        'vehicles': ['Bike', 'Auto', 'Car'],
        'validTill': 'Offer valid until 15th March 2026',
      },
      'SAVE15': {
        'description': 'Enjoy 15% off on any ride service.',
        'services': ['Cab'],
        'vehicles': ['Bike', 'Auto', 'Car', 'Prime Car', 'Van', 'Seater SUV', 'Ace Truck', 'Mini Truck', 'Truck', 'Big Truck'],
        'validTill': 'Offer valid until 5th March 2026',
      },
      'SAVE25': {
        'description': 'Get flat 25% off on your ride.',
        'services': ['Cab', 'Intercity'],
        'vehicles': ['Car', 'Prime Car', 'Van', 'Seater SUV'],
        'validTill': 'Offer valid until 15th March 2026',
      },
      'SAVE625': {
        'description': 'Enjoy 15% off on your next ride.',
        'services': ['Cab'],
        'vehicles': ['Bike', 'Auto', 'Car'],
        'validTill': 'Offer valid until 8th March 2026',
      },
    };

    final data = promoData[code] ?? {
      'description': description.isNotEmpty ? description : 'Enjoy great savings on your ride.',
      'services': services.isNotEmpty ? services : ['Cab'],
      'vehicles': vehicles.isNotEmpty ? vehicles : ['Bike', 'Auto', 'Car'],
      'validTill': validTill.isNotEmpty ? validTill : 'Offer valid until 31st December 2026',
    };

    return Directionality(
      textDirection: appTheme.textDirection,
      child: Scaffold(
        backgroundColor: appTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: appTheme.cardColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              appTheme.rtlEnabled ? Icons.arrow_forward : Icons.arrow_back,
              color: appTheme.textColor,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            localizations.promoCodeDetails,
            style: TextStyle(
              color: appTheme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: false,
        ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                decoration: BoxDecoration(
                  color: appTheme.cardColor, // White card background
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Promo Code Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: appTheme.brandRed, // Red branding color
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      code,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Discount Title
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: appTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Discount Description
                  Text(
                    data['description'] as String,
                    style: TextStyle(
                      fontSize: 15,
                      color: appTheme.textGrey,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Divider
                  Divider(color: appTheme.dividerColor, thickness: 1),
                  const SizedBox(height: 24),

                  // Services Section
                  Text(
                    localizations.services,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: appTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (data['services'] as List<String>)
                        .map((service) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: appTheme.iconBgColor, // Grey background
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: appTheme.dividerColor,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                service,
                                style: TextStyle(
                                  color: appTheme.textColor, // Black text
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 24),

                  // Vehicles Section
                  Text(
                    'Vehicles',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: appTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (data['vehicles'] as List<String>)
                        .map((vehicle) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: appTheme.iconBgColor, // Grey background
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: appTheme.dividerColor,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                vehicle,
                                style: TextStyle(
                                  color: appTheme.textColor, // Black text
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 24),

                  // Divider
                  Divider(color: appTheme.dividerColor, thickness: 1),
                  const SizedBox(height: 24),

                  // Validity Section
                  Row(
                    children: [
                      Text(
                        'Valid Till:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: appTheme.textColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          data['validTill'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            color: appTheme.textGrey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                ),
              ),
            ),
          ),

          // Bottom Action Button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: appTheme.cardColor,
              border: Border(
                top: BorderSide(color: appTheme.dividerColor, width: 1),
              ),
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(localizations.copiedToClipboard),
                        duration: const Duration(seconds: 2),
                        backgroundColor: appTheme.brandRed,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appTheme.brandRed, // Red branding color
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.copy,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        code,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}

