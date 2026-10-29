import '../../domain/models/voice_recording.dart';
import '../../domain/services/media_gateway.dart';

/// Fallback for platforms where the native media plugins are unavailable.
///
/// Kept API-compatible with the IO implementation so [AppDependencies] can use
/// a conditional import and still build for Web.
class DeviceMediaGateway implements MediaGateway {
  const DeviceMediaGateway();

  static final _unsupported = UnsupportedError(
    'Media capture is only available on Android and iOS.',
  );

  @override
  Stream<void> get playbackCompleted => Stream<void>.empty();

  @override
  Future<String?> pickImage({required MediaImageSource source}) =>
      Future.error(_unsupported);

  @override
  Future<bool> hasMicrophonePermission() async => false;

  @override
  Future<void> startRecording() => Future.error(_unsupported);

  @override
  Future<void> pauseRecording() => Future.error(_unsupported);

  @override
  Future<void> resumeRecording() => Future.error(_unsupported);

  @override
  Future<VoiceRecording?> stopRecording() async => null;

  @override
  Future<void> discardRecording(String path) async {}

  @override
  Future<bool> fileExists(String path) async => false;

  @override
  Future<void> playAudio(String path) => Future.error(_unsupported);

  @override
  Future<void> stopAudio() async {}

  @override
  Future<void> dispose() async {}
}
