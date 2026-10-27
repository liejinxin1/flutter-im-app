import '../domain/models/chat_message_kind.dart';

/// Compile-time Agora Chat configuration.
///
/// `AGORA_APP_KEY` can still be overridden with
/// `--dart-define=AGORA_APP_KEY=...`. No key is committed to this repository;
/// each developer must provide their own Agora Chat AppKey. An Agora Chat
/// AppKey is an app identifier, not the App Certificate, so it is safe to ship
/// in a local build; never put the App Certificate or server secrets here.
abstract final class AppConfig {
  static const String _configuredAppKey = String.fromEnvironment(
    'AGORA_APP_KEY',
  );
  static const String _configuredAppId = String.fromEnvironment('AGORA_APP_ID');
  static const String _configuredApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  static String get appKey => _configuredAppKey;

  static String get appId => _configuredAppId;

  static bool get hasChatCredentials => appKey.isNotEmpty || appId.isNotEmpty;

  /// Optional REST API root for future application endpoints. Chat itself is
  /// transported by the Agora SDK and does not use this URL.
  static Uri? get apiBaseUrl {
    if (_configuredApiBaseUrl.isEmpty) return null;
    final uri = Uri.tryParse(_configuredApiBaseUrl);
    return uri != null && uri.hasScheme ? uri : null;
  }

  static const Duration apiTimeout = Duration(seconds: 20);

  /// `native`: always use SDK message types.
  /// `custom`: always use the app envelope (attachments need an uploader).
  /// `hybrid`: custom text; custom attachments when an uploader exists,
  /// otherwise fall back to native SDK types.
  static const String messageTransport = String.fromEnvironment(
    'MESSAGE_TRANSPORT',
    defaultValue: 'hybrid',
  );

  /// Comma-separated attachment kinds that may use custom transport when an
  /// uploader is configured. Set to `file` to keep image/voice native.
  static const String customAttachmentKinds = String.fromEnvironment(
    'CUSTOM_ATTACHMENT_KINDS',
    defaultValue: 'image,voice,file,video',
  );

  static Set<ChatMessageKind> get customAttachmentKindSet {
    final result = <ChatMessageKind>{};
    for (final raw in customAttachmentKinds.split(',')) {
      final name = raw.trim().toLowerCase();
      for (final kind in ChatMessageKind.values) {
        if (kind.name == name) {
          result.add(kind);
          break;
        }
      }
    }
    return result;
  }
}
