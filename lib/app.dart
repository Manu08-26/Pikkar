import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'core/localization/app_localizations.dart';

class RapidoApp extends StatefulWidget {
  const RapidoApp({super.key});

  @override
  State<RapidoApp> createState() => _RapidoAppState();
}

class _RapidoAppState extends State<RapidoApp> {
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
    final locale = Locale(_appTheme.getLanguageCode());
    
    return Directionality(
      textDirection: _appTheme.textDirection,
      child: MaterialApp(
        title: 'Pikkar',
        debugShowCheckedModeBanner: false,
        locale: locale,
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          AppLocalizationsDelegate(_appTheme),
        ],
        supportedLocales: const [
          Locale('en', ''),
          Locale('es', ''),
          Locale('fr', ''),
          Locale('ar', ''),
        ],
        theme: ThemeData(
          primaryColor: Colors.black,
          scaffoldBackgroundColor: _appTheme.backgroundColor,
        ),
        initialRoute: AppRoutes.splash,
        routes: AppRoutes.routes,
      ),
    );
  }
}
