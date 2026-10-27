import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/services/local_store.dart';

/// SharedPreferences-backed store. The instance is resolved once and reused,
/// avoiding a platform-channel round trip for every cache read/write.
class SharedPreferencesLocalStore implements LocalStore {
  SharedPreferences? _preferences;
  Future<SharedPreferences>? _loading;

  Future<SharedPreferences> _instance() {
    final existing = _preferences;
    if (existing != null) return Future.value(existing);
    return _loading ??= SharedPreferences.getInstance()
        .then((value) {
          _preferences = value;
          _loading = null;
          return value;
        })
        .catchError((Object error) {
          _loading = null;
          throw error;
        });
  }

  @override
  Future<String?> read(String key) async => (await _instance()).getString(key);

  @override
  Future<void> write(String key, String value) async {
    await (await _instance()).setString(key, value);
  }

  @override
  Future<void> remove(String key) async {
    await (await _instance()).remove(key);
  }
}
