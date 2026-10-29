import '../../domain/services/local_store.dart';
import 'local_store_factory_stub.dart'
    if (dart.library.io) 'local_store_factory_io.dart'
    as platform;

LocalStore createLocalStore() => platform.createLocalStore();
