import '../data/local/chat_cache.dart';
import '../data/local/local_store_factory.dart';
import '../data/local/prefs_app_settings.dart';
import '../data/local/prefs_friend_request_store.dart';
import '../data/local/prefs_outbox_repository.dart';
import '../data/local/prefs_profile_repository.dart';
import '../data/repositories/agora_chat_repository.dart';
import '../data/repositories/agora_contact_repository.dart';
import '../data/repositories/agora_group_repository.dart';
import '../data/repositories/agora_session_repository.dart';
import '../data/services/agora_chat_service.dart';
import '../data/services/chat_connection.dart';
import '../data/services/device_media_gateway_stub.dart'
    if (dart.library.io) '../data/services/device_media_gateway.dart';
import '../data/services/http_api_client.dart';
import '../domain/repositories/chat_repository.dart';
import '../domain/repositories/contact_repository.dart';
import '../domain/repositories/friend_request_store.dart';
import '../domain/repositories/group_repository.dart';
import '../domain/repositories/outbox_repository.dart';
import '../domain/repositories/profile_repository.dart';
import '../domain/repositories/session_repository.dart';
import '../domain/services/api_client.dart';
import '../domain/services/app_settings.dart';
import '../domain/services/chat_service.dart';
import '../domain/services/local_store.dart';
import '../domain/services/media_gateway.dart';
import '../domain/services/message_transport.dart';
import 'app_config.dart';

/// App composition root.
///
/// The only place that knows concrete services, repositories, and platform
/// adapters. ViewModels receive the interfaces declared here.
class AppDependencies {
  AppDependencies({
    required this.session,
    required this.chat,
    required this.contacts,
    required this.groups,
    required this.media,
    required this.outbox,
    required this.profiles,
    required this.friendRequests,
    this.api,
    this.settings,
    this.attachmentUploader,
    this.onDispose,
  });

  factory AppDependencies.create({
    ChatService? service,
    MediaGateway? media,
    LocalStore? localStore,
    ApiClient? api,
    AttachmentUploader? attachmentUploader,
    AppSettings? settings,
  }) {
    final store = localStore ?? createLocalStore();
    final connection = ChatConnection(service ?? AgoraChatService());
    final outbox = PrefsOutboxRepository(store);
    final mediaGateway = media ?? DeviceMediaGateway();
    final apiClient =
        api ??
        (AppConfig.apiBaseUrl == null
            ? null
            : HttpApiClient(
                baseUrl: AppConfig.apiBaseUrl!,
                timeout: AppConfig.apiTimeout,
              ));
    final transportMode = messageTransportModeFrom(AppConfig.messageTransport);
    return AppDependencies(
      session: AgoraSessionRepository(connection),
      chat: AgoraChatRepository(
        connection,
        ChatCache(store),
        outbox,
        transportMode: transportMode,
        uploader: attachmentUploader,
        customAttachmentKinds: AppConfig.customAttachmentKindSet,
      ),
      contacts: AgoraContactRepository(connection),
      groups: AgoraGroupRepository(connection.service),
      media: mediaGateway,
      outbox: outbox,
      profiles: PrefsProfileRepository(connection.service, store),
      friendRequests: PrefsFriendRequestStore(store),
      settings: settings ?? PrefsAppSettings(store),
      api: apiClient,
      attachmentUploader: attachmentUploader,
      onDispose: () async {
        await apiClient?.close();
        await mediaGateway.dispose();
        await connection.dispose();
      },
    );
  }

  final SessionRepository session;
  final ChatRepository chat;
  final ContactRepository contacts;
  final GroupRepository groups;
  final MediaGateway media;
  final OutboxRepository outbox;
  final ProfileRepository profiles;
  final FriendRequestStore friendRequests;
  final AppSettings? settings;
  final ApiClient? api;
  final AttachmentUploader? attachmentUploader;

  /// Injected by [AppDependencies.create]; tests that build a bundle manually
  /// own the lifecycle of the dependencies they pass in.
  final Future<void> Function()? onDispose;

  Future<void>? _disposeFuture;

  // Inject a complete bundle in tests so unrelated SDK sessions cannot mix.
  Future<void> dispose() => _disposeFuture ??= Future<void>.sync(() async {
    await onDispose?.call();
  });
}
