import 'package:flutter/material.dart';

class AppTheme extends ChangeNotifier {
  static final AppTheme _instance = AppTheme._internal();
  factory AppTheme() => _instance;
  AppTheme._internal();

  bool _themeEnabled = false;
  bool _rtlEnabled = false;
  String _selectedLanguage = 'English';

  bool get themeEnabled => _themeEnabled;
  bool get rtlEnabled => _rtlEnabled;
  String get selectedLanguage => _selectedLanguage;

  // Theme colors
  Color get backgroundColor => _themeEnabled ? const Color(0xFF2A2A2A) : const Color(0xFFF2F2F2);
  Color get cardColor => _themeEnabled ? Colors.grey.shade800 : Colors.white;
  Color get textColor => _themeEnabled ? Colors.white : const Color(0xFF121212);
  Color get iconBgColor => _themeEnabled ? Colors.grey.shade700 : const Color(0xFFF2F2F2);
  Color get dividerColor => _themeEnabled ? Colors.grey.shade700 : const Color(0xFFF2F2F2);
  Color get textGrey => const Color(0xFF8E8E8E);
  Color get brandRed => const Color(0xFFE53935);
  Color get black => const Color(0xFF121212);
  Color get lightGrey => const Color(0xFFF2F2F2);

  TextDirection get textDirection => _rtlEnabled ? TextDirection.rtl : TextDirection.ltr;

  void setTheme(bool enabled) {
    _themeEnabled = enabled;
    notifyListeners();
  }

  void setRTL(bool enabled) {
    _rtlEnabled = enabled;
    notifyListeners();
  }

  void setLanguage(String language) {
    _selectedLanguage = language;
    notifyListeners();
  }

  String getLanguageCode() {
    switch (_selectedLanguage) {
      case 'English':
        return 'en';
      case 'Arabic':
        return 'ar';
      case 'French':
        return 'fr';
      case 'Spanish':
        return 'es';
      default:
        return 'en';
    }
  }
}

