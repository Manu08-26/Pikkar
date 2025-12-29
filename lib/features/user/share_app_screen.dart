import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/app_localizations.dart';

class ShareAppScreen extends StatefulWidget {
  const ShareAppScreen({super.key});

  @override
  State<ShareAppScreen> createState() => _ShareAppScreenState();
}

class _ShareAppScreenState extends State<ShareAppScreen> {
  final AppTheme _appTheme = AppTheme();
  final String shareLink = "https://play.google.com/store/apps/details?id=com.taxidouser&hl=en-IN";

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
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _appTheme.iconBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _appTheme.rtlEnabled ? Icons.arrow_forward : Icons.arrow_back,
                color: _appTheme.textColor,
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            localizations.shareApp,
            style: TextStyle(
              color: _appTheme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // Sharing Link Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.sharingLink,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _appTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _appTheme.iconBgColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _appTheme.dividerColor,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            shareLink,
                            style: TextStyle(
                              fontSize: 14,
                              color: _appTheme.textColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: shareLink));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(localizations.copiedToClipboard),
                                duration: const Duration(seconds: 2),
                                backgroundColor: _appTheme.brandRed,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _appTheme.brandRed.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.copy,
                              color: _appTheme.brandRed,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Sharing Options
            Expanded(
              child: Container(
                color: _appTheme.cardColor,
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: 30,
                  itemBuilder: (context, index) {
                    return _buildShareOption(context, index);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption(BuildContext context, int index) {
    final List<Map<String, dynamic>> shareOptions = [
      // Contacts with WhatsApp
      {'name': 'Airtel Finance', 'icon': Icons.person, 'color': Colors.blue, 'hasWhatsApp': true},
      {'name': 'Objectwin', 'icon': Icons.person, 'color': Colors.green, 'hasWhatsApp': true},
      {'name': '+91 96769 59539', 'icon': Icons.phone, 'color': Colors.amber, 'hasWhatsApp': true},
      {'name': 'Vishal @abhyaas', 'icon': Icons.person, 'color': Colors.grey, 'hasWhatsApp': false},
      {'name': 'Rohit_45', 'icon': Icons.person, 'color': Colors.grey, 'hasWhatsApp': false},
      // Apps
      {'name': 'Quick Share', 'icon': Icons.share, 'color': Colors.blue, 'hasWhatsApp': false},
      {'name': 'WhatsApp', 'icon': Icons.chat, 'color': const Color(0xFF25D366), 'hasWhatsApp': false},
      {'name': 'Instagram', 'icon': Icons.camera_alt, 'color': Colors.purple, 'hasWhatsApp': false},
      {'name': 'Chrome', 'icon': Icons.language, 'color': Colors.blue, 'hasWhatsApp': false},
      {'name': 'Messages', 'icon': Icons.message, 'color': Colors.blue, 'hasWhatsApp': false},
      {'name': 'Amazon', 'icon': Icons.shopping_cart, 'color': Colors.orange, 'hasWhatsApp': false},
      {'name': 'Android', 'icon': Icons.security, 'color': Colors.green, 'hasWhatsApp': false},
      {'name': 'Bluetooth', 'icon': Icons.bluetooth, 'color': Colors.blue, 'hasWhatsApp': false},
      {'name': 'Bookmark', 'icon': Icons.bookmark, 'color': Colors.blue, 'hasWhatsApp': false},
      {'name': 'Drive', 'icon': Icons.folder, 'color': Colors.green, 'hasWhatsApp': false},
      {'name': 'EasyShare', 'icon': Icons.share, 'color': Colors.blue, 'hasWhatsApp': false},
      {'name': 'Facebook', 'icon': Icons.facebook, 'color': Colors.blue, 'hasWhatsApp': false},
      {'name': 'Files', 'icon': Icons.folder, 'color': Colors.blue, 'hasWhatsApp': false},
      {'name': 'Gemini', 'icon': Icons.star, 'color': Colors.purple, 'hasWhatsApp': false},
      {'name': 'Gmail', 'icon': Icons.email, 'color': Colors.red, 'hasWhatsApp': false},
      {'name': 'Downloader', 'icon': Icons.download, 'color': Colors.purple, 'hasWhatsApp': false},
      {'name': 'iQOOshare', 'icon': Icons.share, 'color': Colors.blue, 'hasWhatsApp': false},
      {'name': 'Keep Notes', 'icon': Icons.note, 'color': Colors.yellow, 'hasWhatsApp': false},
      {'name': 'LinkedIn', 'icon': Icons.business, 'color': Colors.blue, 'hasWhatsApp': false},
      {'name': 'Twitter', 'icon': Icons.alternate_email, 'color': Colors.blue, 'hasWhatsApp': false},
      {'name': 'Telegram', 'icon': Icons.send, 'color': Colors.blue, 'hasWhatsApp': false},
      {'name': 'More', 'icon': Icons.more_horiz, 'color': Colors.grey, 'hasWhatsApp': false},
      {'name': 'More', 'icon': Icons.more_horiz, 'color': Colors.grey, 'hasWhatsApp': false},
      {'name': 'More', 'icon': Icons.more_horiz, 'color': Colors.grey, 'hasWhatsApp': false},
    ];

    if (index >= shareOptions.length) {
      return const SizedBox();
    }

    final option = shareOptions[index];
    final name = option['name'] as String;
    final icon = option['icon'] as IconData;
    final color = option['color'] as Color;
    final hasWhatsApp = option['hasWhatsApp'] as bool;

    return InkWell(
      onTap: () {
        // Handle share option tap
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sharing via $name'),
            duration: const Duration(seconds: 1),
            backgroundColor: _appTheme.brandRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              if (hasWhatsApp)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _appTheme.cardColor,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.chat,
                      color: Colors.white,
                      size: 10,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: TextStyle(
              fontSize: 11,
              color: _appTheme.textColor,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
