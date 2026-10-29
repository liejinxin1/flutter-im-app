import '../../domain/services/local_store.dart';
import 'shared_preferences_local_store.dart';

/// Web has no sqflite plugin; keep the existing key-value fallback.
LocalStore createLocalStore() => SharedPreferencesLocalStore();
