import '../../domain/repositories/profile_repository.dart';
import '../../domain/services/local_store.dart';
import '../../domain/services/user_directory.dart';
import 'prefs_profile_repository.dart';

ProfileRepository createProfileRepository(
  UserDirectory directory,
  LocalStore store,
) => PrefsProfileRepository(directory, store);
