import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';

class StorageService {
  StorageService(this._storage);

  final FlutterSecureStorage _storage;

  /// Keys whose value is mirrored in memory.
  ///
  /// `AuthInterceptor` reads the access token on **every** outgoing request, and
  /// each `flutter_secure_storage` read is a platform-channel round trip into
  /// the Keychain / EncryptedSharedPreferences. That is latency on the critical
  /// path of every call, for a value that changes about once a week. Everything
  /// that mutates these keys goes through this class, so the mirror cannot
  /// drift from what is on disk.
  static const Set<String> _mirroredKeys = <String>{
    AppConstants.tokenKey,
    AppConstants.refreshTokenKey,
    AppConstants.userIdKey,
  };

  final Map<String, String?> _mirror = <String, String?>{};
  final Set<String> _known = <String>{};

  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
    if (_mirroredKeys.contains(key)) {
      _mirror[key] = value;
      _known.add(key);
    }
  }

  Future<String?> read(String key) async {
    if (_mirroredKeys.contains(key) && _known.contains(key)) {
      return _mirror[key];
    }
    final value = await _storage.read(key: key);
    if (_mirroredKeys.contains(key)) {
      _mirror[key] = value;
      _known.add(key);
    }
    return value;
  }

  Future<void> delete(String key) async {
    await _storage.delete(key: key);
    if (_mirroredKeys.contains(key)) {
      _mirror.remove(key);
      // "Known to be absent" — otherwise the next read re-hits the platform.
      _known.add(key);
    }
  }

  Future<void> clear() async {
    await _storage.deleteAll();
    _mirror.clear();
    _known.addAll(_mirroredKeys);
  }

  Future<bool> containsKey(String key) async {
    return await _storage.containsKey(key: key);
  }
}
