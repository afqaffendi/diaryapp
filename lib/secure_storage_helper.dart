import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageHelper {
  static final _storage = FlutterSecureStorage();

  static Future<void> savePin(String pin) async {
    await _storage.write(key: 'user_pin', value: pin);
    await _storage.write(key: 'pin_enabled', value: 'true');
  }

  static Future<String?> getPin() async {
    return await _storage.read(key: 'user_pin');
  }

  static Future<bool> isPinEnabled() async {
    final status = await _storage.read(key: 'pin_enabled');
    return status == 'true';
  }

  static Future<void> disablePin() async {
    await _storage.write(key: 'pin_enabled', value: 'false');
  }

  static Future<void> clearPin() async {
    await _storage.delete(key: 'user_pin');
    await _storage.write(key: 'pin_enabled', value: 'false');
  }
}
