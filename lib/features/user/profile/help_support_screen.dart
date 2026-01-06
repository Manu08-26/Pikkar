import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
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
            'Help & Support',
            style: TextStyle(
              color: _appTheme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Contact Options
              Container(
                decoration: BoxDecoration(
                  color: _appTheme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _appTheme.dividerColor, width: 1),
                ),
                child: Column(
                  children: [
                    _buildContactOption(
                      icon: Icons.phone,
                      title: 'Call Us',
                      subtitle: '+91 1800-123-4567',
                      onTap: () {},
                    ),
                    Divider(height: 1, color: _appTheme.dividerColor),
                    _buildContactOption(
                      icon: Icons.email,
                      title: 'Email Us',
                      subtitle: 'support@pikkar.com',
                      onTap: () {},
                    ),
                    Divider(height: 1, color: _appTheme.dividerColor),
                    _buildContactOption(
                      icon: Icons.chat_bubble_outline,
                      title: 'Live Chat',
                      subtitle: 'Available 24/7',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // FAQ Section
              _buildSectionTitle('Frequently Asked Questions'),
              const SizedBox(height: 12),
              _buildFAQItem(
                question: 'How do I book a ride?',
                answer:
                    'Open the app, select your pickup and drop locations, choose your ride type, and click "Book Ride".',
              ),
              const SizedBox(height: 12),
              _buildFAQItem(
                question: 'How do I cancel a ride?',
                answer:
                    'You can cancel a ride by clicking the "Cancel Ride" button and selecting a reason for cancellation.',
              ),
              const SizedBox(height: 12),
              _buildFAQItem(
                question: 'What payment methods are accepted?',
                answer:
                    'We accept cash payments directly to the driver. Wallet and other payment methods coming soon.',
              ),
              const SizedBox(height: 12),
              _buildFAQItem(
                question: 'How do I rate my ride?',
                answer:
                    'After completing a ride, go to "Rate Your Rides" in your profile to rate and review your past rides.',
              ),
              const SizedBox(height: 24),

              // Report Issue
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Report issue
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
                    'Report an Issue',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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

  Widget _buildContactOption({
    required IconData icon,
    required String title,
    required String subtitle,
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
        child: Icon(icon, color:Colors.black, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: _appTheme.textColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: _appTheme.textGrey,
        ),
      ),
      trailing: Icon(
        _appTheme.rtlEnabled ? Icons.chevron_left : Icons.chevron_right,
        color: _appTheme.textGrey,
      ),
      onTap: onTap,
    );
  }

  Widget _buildFAQItem({
    required String question,
    required String answer,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _appTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _appTheme.dividerColor, width: 1),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _appTheme.textColor,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              answer,
              style: TextStyle(
                fontSize: 14,
                color: _appTheme.textGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

