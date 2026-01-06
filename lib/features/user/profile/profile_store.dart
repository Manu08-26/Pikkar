import '../../../core/services/api_client.dart';

class ProfileStore {
  static const _kFirstName = 'firstName';
  static const _kLastName = 'lastName';
  static const _kPhone = 'phone';
  static const _kEmail = 'email';

  static Future<Map<String, String>> load() async {
    final data = await ApiClient.getUserData();
    return {
      _kFirstName: (data?[_kFirstName] ?? '').toString(),
      _kLastName: (data?[_kLastName] ?? '').toString(),
      _kPhone: (data?[_kPhone] ?? '').toString(),
      _kEmail: (data?[_kEmail] ?? '').toString(),
    };
  }

  static Future<void> save({
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
  }) async {
    final existing = await ApiClient.getUserData() ?? <String, dynamic>{};
    final updated = <String, dynamic>{
      ...existing,
      _kFirstName: firstName.trim(),
      _kLastName: lastName.trim(),
      _kPhone: phone.trim(),
      _kEmail: email.trim(),
    };
    await ApiClient.saveUserData(updated);
  }
}


