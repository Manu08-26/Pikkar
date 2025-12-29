import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/app_localizations.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
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
            localizations.appSetting,
            style: TextStyle(
              color: _appTheme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: _appTheme.cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Theme Setting
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _appTheme.iconBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _appTheme.themeEnabled ? Icons.light_mode : Icons.dark_mode,
                      color: _appTheme.textColor,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    localizations.theme,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: _appTheme.textColor,
                    ),
                  ),
                  trailing: Switch(
                    value: _appTheme.themeEnabled,
                    onChanged: (value) {
                      _appTheme.setTheme(value);
                    },
                    activeColor: _appTheme.brandRed,
                  ),
                ),
                Divider(height: 1, color: _appTheme.dividerColor),
                
                // RTL Setting
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _appTheme.iconBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.swap_horiz,
                      color: _appTheme.textColor,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    localizations.rtl,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: _appTheme.textColor,
                    ),
                  ),
                  trailing: Switch(
                    value: _appTheme.rtlEnabled,
                    onChanged: (value) {
                      _appTheme.setRTL(value);
                    },
                    activeColor: _appTheme.brandRed,
                  ),
                ),
                Divider(height: 1, color: _appTheme.dividerColor),
                
                // Change Language
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _appTheme.iconBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.language,
                      color: _appTheme.textColor,
                      size: 20,
                    ),
                  ),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations.changeLanguage,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: _appTheme.textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _appTheme.getLanguageCode(),
                        style: TextStyle(
                          fontSize: 12,
                          color: _appTheme.textGrey,
                        ),
                      ),
                    ],
                  ),
                  trailing: Icon(
                    _appTheme.rtlEnabled ? Icons.chevron_left : Icons.chevron_right,
                    color: _appTheme.textGrey,
                  ),
                  onTap: () {
                    _showLanguageBottomSheet(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLanguageBottomSheet(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    String tempSelectedLanguage = _appTheme.selectedLanguage;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: _appTheme.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _appTheme.brandRed,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              
              // Title
              Text(
                localizations.changeLanguage,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _appTheme.textColor,
                ),
              ),
              const SizedBox(height: 24),
              
              // Language List
              _buildLanguageOption(
                context,
                localizations,
                'English',
                localizations.languageEnglish,
                '🇺🇸',
                tempSelectedLanguage == 'English',
                () {
                  setModalState(() {
                    tempSelectedLanguage = 'English';
                  });
                },
              ),
              _buildLanguageOption(
                context,
                localizations,
                'Arabic',
                localizations.languageArabic,
                '🇸🇦',
                tempSelectedLanguage == 'Arabic',
                () {
                  setModalState(() {
                    tempSelectedLanguage = 'Arabic';
                  });
                },
              ),
              _buildLanguageOption(
                context,
                localizations,
                'French',
                localizations.languageFrench,
                '🇫🇷',
                tempSelectedLanguage == 'French',
                () {
                  setModalState(() {
                    tempSelectedLanguage = 'French';
                  });
                },
              ),
              _buildLanguageOption(
                context,
                localizations,
                'Spanish',
                localizations.languageSpanish,
                '🇪🇸',
                tempSelectedLanguage == 'Spanish',
                () {
                  setModalState(() {
                    tempSelectedLanguage = 'Spanish';
                  });
                },
              ),
              
              const SizedBox(height: 20),
              
              // Update Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _appTheme.setLanguage(tempSelectedLanguage);
                      Navigator.pop(context);
                      setState(() {}); // Rebuild to show new language
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _appTheme.brandRed,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      localizations.update,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    AppLocalizations localizations,
    String languageKey,
    String languageDisplayName,
    String flag,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: _appTheme.dividerColor, width: 1),
          ),
        ),
        child: Row(
          children: [
            Text(
              flag,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                languageDisplayName,
                style: TextStyle(
                  fontSize: 16,
                  color: _appTheme.textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? _appTheme.brandRed : Colors.transparent,
                border: Border.all(
                  color: isSelected ? _appTheme.brandRed : _appTheme.textGrey,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 12,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

