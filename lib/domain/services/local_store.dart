/// Minimal key-value persistence contract used by caches and small stores.
///
/// Kept in `domain` so ViewModels and repositories can be tested without
/// platform plugins. The implementation lives in `data/local`.
abstract interface class LocalStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> remove(String key);
}
