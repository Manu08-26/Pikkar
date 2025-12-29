import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/app_localizations.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appTheme = AppTheme();
    final localizations = AppLocalizations.of(context)!;
    return Directionality(
      textDirection: appTheme.textDirection,
      child: Scaffold(
        backgroundColor: appTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: appTheme.cardColor,
          title: Text(
            localizations.notifications,
            style: TextStyle(color: appTheme.textColor),
          ),
          leading: IconButton(
            icon: Icon(
              appTheme.rtlEnabled ? Icons.arrow_forward : Icons.arrow_back,
              color: appTheme.textColor,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/notify-image.png',
                height: 180,
              ),
              const SizedBox(height: 16),
              Text(
                localizations.nothingHere,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: appTheme.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Click the Refresh button down below to check again for something amazing.",
                textAlign: TextAlign.center,
                style: TextStyle(color: appTheme.textGrey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // call notification API again
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: appTheme.brandRed,
                ),
                child: Text(
                  localizations.refresh,
                  style: const TextStyle(color: Colors.white),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
