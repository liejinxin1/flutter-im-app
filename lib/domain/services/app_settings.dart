/// Per-account chat display settings.
abstract interface class AppSettings {
  Future<bool> showNetworkHistory(String userId);
  Future<void> setShowNetworkHistory(String userId, bool value);
}
