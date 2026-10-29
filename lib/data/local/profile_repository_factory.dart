import '../../domain/repositories/profile_repository.dart';
import '../../domain/services/local_store.dart';
import '../../domain/services/user_directory.dart';
import 'profile_repository_factory_stub.dart'
    if (dart.library.io) 'profile_repository_factory_io.dart'
    as platform;

ProfileRepository createProfileRepository(
  UserDirectory directory,
  LocalStore store,
) => platform.createProfileRepository(directory, store);
