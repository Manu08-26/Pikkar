import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppLocalizations {
  final Locale locale;
  final AppTheme appTheme;

  AppLocalizations(this.locale, this.appTheme);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  // Helper method to get localized value
  String _getLocalizedValue(String english, String spanish, String french, String arabic) {
    final langCode = appTheme.getLanguageCode();
    switch (langCode) {
      case 'es':
        return spanish;
      case 'fr':
        return french;
      case 'ar':
        return arabic;
      case 'en':
      default:
        return english;
    }
  }

  // Home Screen
  String get currentLocation => _getLocalizedValue('Current location', 'Ubicación actual', 'Emplacement actuel', 'الموقع الحالي');
  String get whereNext => _getLocalizedValue('Where next?', '¿A dónde ahora?', 'Où ensuite?', 'إلى أين بعد ذلك؟');
  String get trendingOffers => _getLocalizedValue('Trending Offers', 'Ofertas populares', 'Offres tendances', 'العروض الرائجة');
  String get ride => _getLocalizedValue('Ride', 'Viaje', 'Trajet', 'رحلة');
  String get intercity => _getLocalizedValue('Intercity', 'Interurbano', 'Interurbain', 'بين المدن');
  String get package => _getLocalizedValue('Package', 'Paquete', 'Colis', 'طرد');
  String get schedule => _getLocalizedValue('Schedule', 'Programar', 'Planifier', 'جدولة');
  String get rental => _getLocalizedValue('Rental', 'Alquiler', 'Location', 'إيجار');
  String get home => _getLocalizedValue('Home', 'Inicio', 'Accueil', 'الرئيسية');
  String get services => _getLocalizedValue('Services', 'Servicios', 'Services', 'الخدمات');
  String get history => _getLocalizedValue('History', 'Historial', 'Historique', 'السجل');
  String get setting => _getLocalizedValue('Setting', 'Configuración', 'Paramètre', 'الإعدادات');
  String get appName => _getLocalizedValue('TAXIDO', 'TAXIDO', 'TAXIDO', 'TAXIDO');

  // Login Screen
  String get moveFasterPayLess => _getLocalizedValue('Move faster. Pay less.', 'Muévete más rápido. Paga menos.', 'Déplacez-vous plus vite. Payez moins.', 'تحرك أسرع. ادفع أقل.');
  String get login => _getLocalizedValue('Login', 'Iniciar sesión', 'Connexion', 'تسجيل الدخول');
  String get enterPhoneNumber => _getLocalizedValue('Enter your phone number to continue', 'Ingresa tu número de teléfono para continuar', 'Entrez votre numéro de téléphone pour continuer', 'أدخل رقم هاتفك للمتابعة');
  String get continueText => _getLocalizedValue('Continue', 'Continuar', 'Continuer', 'متابعة');
  String get or => _getLocalizedValue('or', 'o', 'ou', 'أو');
  String get continueWithGoogle => _getLocalizedValue('Continue with Google', 'Continuar con Google', 'Continuer avec Google', 'المتابعة مع Google');
  String get continueAsGuest => _getLocalizedValue('Continue as Guest', 'Continuar como invitado', 'Continuer en tant qu\'invité', 'المتابعة كضيف');
  String get termsAndPrivacy => _getLocalizedValue('By continuing, you agree to our Terms & Privacy Policy', 'Al continuar, aceptas nuestros Términos y Política de Privacidad', 'En continuant, vous acceptez nos Conditions et Politique de Confidentialité', 'بالمتابعة، أنت توافق على شروطنا وسياسة الخصوصية');

  // Location Screen
  String get location => _getLocalizedValue('Location', 'Ubicación', 'Emplacement', 'الموقع');
  String get locateOnMap => _getLocalizedValue('locate on map', 'ubicar en el mapa', 'localiser sur la carte', 'تحديد على الخريطة');
  String get savedLocation => _getLocalizedValue('Saved Location', 'Ubicación guardada', 'Emplacement enregistré', 'الموقع المحفوظ');
  String get recent => _getLocalizedValue('Recent', 'Reciente', 'Récent', 'حديث');
  String get noDataFound => _getLocalizedValue('No data found', 'No se encontraron datos', 'Aucune donnée trouvée', 'لم يتم العثور على بيانات');
  String get proceed => _getLocalizedValue('Proceed', 'Continuar', 'Procéder', 'متابعة');

  // Rental Ride Screen
  String get rentalRide => _getLocalizedValue('Rental Ride', 'Viaje de alquiler', 'Trajet de location', 'رحلة الإيجار');
  String get pickupLocation => _getLocalizedValue('Pickup Location', 'Ubicación de recogida', 'Lieu de prise en charge', 'موقع الاستلام');
  String get enterPickupLocation => _getLocalizedValue('Please Enter Pickup Location', 'Por favor ingresa la ubicación de recogida', 'Veuillez entrer le lieu de prise en charge', 'يرجى إدخال موقع الاستلام');
  String get dropLocation => _getLocalizedValue('Drop Location', 'Ubicación de destino', 'Lieu de destination', 'موقع الوجهة');
  String get startTimeAndDate => _getLocalizedValue('Start Time & date', 'Hora y fecha de inicio', 'Heure et date de début', 'وقت وتاريخ البدء');
  String get endTimeAndDate => _getLocalizedValue('End Time & date', 'Hora y fecha de fin', 'Heure et date de fin', 'وقت وتاريخ الانتهاء');
  String get selectDate => _getLocalizedValue('Select Date', 'Seleccionar fecha', 'Sélectionner la date', 'اختر التاريخ');
  String get selectTime => _getLocalizedValue('Select Time', 'Seleccionar hora', 'Sélectionner l\'heure', 'اختر الوقت');
  String get getDriverForTrip => _getLocalizedValue('Get a Driver for Your Trip', 'Obtén un conductor para tu viaje', 'Obtenez un chauffeur pour votre voyage', 'احصل على سائق لرحلتك');
  String get noDriverYet => _getLocalizedValue('No Driver Yet? Get a Car with a Driver Now', '¿Sin conductor? Obtén un auto con conductor ahora', 'Pas encore de chauffeur? Obtenez une voiture avec chauffeur maintenant', 'لا يوجد سائق بعد؟ احصل على سيارة مع سائق الآن');
  String get findNow => _getLocalizedValue('Find Now', 'Buscar ahora', 'Trouver maintenant', 'ابحث الآن');

  // Promo Code Details
  String get promoCodeDetails => _getLocalizedValue('Promo Code Details', 'Detalles del código promocional', 'Détails du code promo', 'تفاصيل رمز الخصم');
  String get bookNow => _getLocalizedValue('Book Now', 'Reservar ahora', 'Réserver maintenant', 'احجز الآن');
  String get copyCode => _getLocalizedValue('Copy Code', 'Copiar código', 'Copier le code', 'نسخ الرمز');
  String get copiedToClipboard => _getLocalizedValue('Copied to clipboard', 'Copiado al portapapeles', 'Copié dans le presse-papiers', 'تم النسخ إلى الحافظة');

  // Settings Screen
  String get settings => _getLocalizedValue('Settings', 'Configuración', 'Paramètres', 'الإعدادات');
  String get guest => _getLocalizedValue('Guest', 'Invitado', 'Invité', 'ضيف');
  String get appDetails => _getLocalizedValue('App Details', 'Detalles de la aplicación', 'Détails de l\'application', 'تفاصيل التطبيق');
  String get appSetting => _getLocalizedValue('App Setting', 'Configuración de la aplicación', 'Paramètre de l\'application', 'إعدادات التطبيق');
  String get shareApp => _getLocalizedValue('Share App', 'Compartir aplicación', 'Partager l\'application', 'مشاركة التطبيق');
  String get version => _getLocalizedValue('Version', 'Versión', 'Version', 'الإصدار');
  String get signIn => _getLocalizedValue('Sign In', 'Iniciar sesión', 'Se connecter', 'تسجيل الدخول');

  // App Settings Screen
  String get theme => _getLocalizedValue('Theme', 'Tema', 'Thème', 'المظهر');
  String get rtl => _getLocalizedValue('RTL', 'RTL', 'RTL', 'RTL');
  String get changeLanguage => _getLocalizedValue('Change Language', 'Cambiar idioma', 'Changer la langue', 'تغيير اللغة');

  // Services Screen
  String get moreServicesComingSoon => _getLocalizedValue('More Services', 'Más servicios', 'Plus de services', 'المزيد من الخدمات');
  String get comingSoon => _getLocalizedValue('Coming soon', 'Próximamente', 'Bientôt disponible', 'قريباً');
  String get moreServices => _getLocalizedValue('MORE SERVICES', 'MÁS SERVICIOS', 'PLUS DE SERVICES', 'المزيد من الخدمات');
  String get stayTuned => _getLocalizedValue('STAY TUNED', 'MANTENTE AL TANTO', 'RESTEZ À L\'ÉCOUTE', 'ترقبوا');

  // History Screen
  String get noRideHistory => _getLocalizedValue('No Ride History', 'Sin historial de viajes', 'Aucun historique de trajet', 'لا يوجد سجل رحلات');
  String get rideHistoryWillAppear => _getLocalizedValue('Your ride history will appear here', 'Tu historial de viajes aparecerá aquí', 'Votre historique de trajets apparaîtra ici', 'سيظهر سجل رحلاتك هنا');

  // Map Location Screen
  String get confirmLocation => _getLocalizedValue('Confirm Location', 'Confirmar ubicación', 'Confirmer l\'emplacement', 'تأكيد الموقع');

  // Notifications Screen
  String get notifications => _getLocalizedValue('Notifications', 'Notificaciones', 'Notifications', 'الإشعارات');
  String get nothingHere => _getLocalizedValue('Nothing here !!', '¡Nada aquí!', 'Rien ici !!', 'لا شيء هنا !!');
  String get refresh => _getLocalizedValue('Refresh', 'Actualizar', 'Actualiser', 'تحديث');

  // Share App Screen
  String get sharingLink => _getLocalizedValue('Sharing link', 'Enlace para compartir', 'Lien de partage', 'رابط المشاركة');

  // Language Names
  String get languageEnglish => _getLocalizedValue('English', 'Inglés', 'Anglais', 'الإنجليزية');
  String get languageSpanish => _getLocalizedValue('Spanish', 'Español', 'Espagnol', 'الإسبانية');
  String get languageFrench => _getLocalizedValue('French', 'Francés', 'Français', 'الفرنسية');
  String get languageArabic => _getLocalizedValue('Arabic', 'Árabe', 'Arabe', 'العربية');

  // Common
  String get update => _getLocalizedValue('Update', 'Actualizar', 'Mettre à jour', 'تحديث');
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  final AppTheme appTheme;

  AppLocalizationsDelegate(this.appTheme);

  @override
  bool isSupported(Locale locale) {
    return ['en', 'es', 'fr', 'ar'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale, appTheme);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => true;
}
