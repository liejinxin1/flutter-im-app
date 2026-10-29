import '../models/voice_recording.dart';

enum MediaImageSource { camera, gallery }

/// Device capabilities used by the chat composer.
///
/// ViewModels depend on this contract instead of `image_picker`, `record`,
/// `audioplayers`, or `dart:io`, so presentation code stays testable and the
/// platform implementation lives in `data/services`.
abstract interface class MediaGateway {
  /// Emits once whenever the currently playing audio reaches its end.
  Stream<void> get playbackCompleted;

  Future<String?> pickImage({required MediaImageSource source});

  Future<bool> hasMicrophonePermission();

  Future<void> startRecording();

  Future<void> pauseRecording();

  Future<void> resumeRecording();

  /// Stops the active recording. Returns `null` when nothing was recorded.
  Future<VoiceRecording?> stopRecording();

  Future<void> discardRecording(String path);

  Future<bool> fileExists(String path);

  Future<void> playAudio(String path);

  Future<void> stopAudio();

  Future<void> dispose();
}
