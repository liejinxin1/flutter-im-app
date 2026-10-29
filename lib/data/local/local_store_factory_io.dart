import '../../domain/services/local_store.dart';
import 'app_database.dart';
import 'sqlite_local_store.dart';

LocalStore createLocalStore() => SqliteLocalStore(AppDatabase());
