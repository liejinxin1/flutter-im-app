import '../../domain/services/app_settings.dart';
import '../../domain/services/local_store.dart';

class PrefsAppSettings implements AppSettings {
  PrefsAppSettings(this._store);

  final LocalStore _store;

  String _showNetworkHistoryKey(String userId) =>
      'settings.show_network_history.v1.$userId';

  @override
  Future<bool> showNetworkHistory(String userId) async {
    if (userId.isEmpty) return true;
    try {
      final value = await _store.read(_showNetworkHistoryKey(userId));
      return value != 'false';
    } catch (_) {
      return true;
    }
  }

  @override
  Future<void> setShowNetworkHistory(String userId, bool value) async {
    if (userId.isEmpty) return;
    try {
      await _store.write(_showNetworkHistoryKey(userId), '$value');
    } catch (_) {
      // Settings persistence is best effort.
    }
  }
}
