import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart' hide PickedFile;
import 'package:open_filex/open_filex.dart';
import 'package:record/record.dart';

import '../../domain/models/picked_file.dart';
import '../../domain/models/voice_recording.dart';
import '../../domain/services/media_gateway.dart';

/// Mobile/desktop implementation of [MediaGateway].
///
/// Plugin usage and file-system access stay in the data layer; ViewModels only
/// see the domain contract.
class DeviceMediaGateway implements MediaGateway {
  DeviceMediaGateway();

  final ImagePicker _picker = ImagePicker();
  final AudioRecorder _recorder = AudioRecorder();
  final StreamController<void> _playbackCompleted =
      StreamController<void>.broadcast();

  AudioPlayer? _player;
  StreamSubscription<void>? _playerSubscription;
  String? _recordingPath;
  DateTime? _recordingStartedAt;
  bool _disposed = false;

  @override
  Stream<void> get playbackCompleted => _playbackCompleted.stream;

  @override
  Future<String?> pickImage({required MediaImageSource source}) async {
    final image = await _picker.pickImage(
      source: switch (source) {
        MediaImageSource.camera => ImageSource.camera,
        MediaImageSource.gallery => ImageSource.gallery,
      },
      imageQuality: 88,
      maxWidth: 1920,
    );
    return image?.path;
  }

  @override
  Future<PickedFile?> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: false,
    );
    if (result == null || result.files.isEmpty) return null;
    final file = result.files.single;
    final path = file.path;
    if (path == null || path.isEmpty) return null;
    return PickedFile(path: path, name: file.name, sizeBytes: file.size);
  }

  @override
  Future<bool> hasMicrophonePermission() => _recorder.hasPermission();

  @override
  Future<void> startRecording() async {
    if (_disposed) throw StateError('Media gateway has been disposed.');
    final activePath = _recordingPath;
    if (activePath != null) await discardRecording(activePath);

    final path =
        '${Directory.systemTemp.path}/agora_voice_'
        '${DateTime.now().microsecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000),
      path: path,
    );
    _recordingPath = path;
    _recordingStartedAt = DateTime.now();
  }

  @override
  Future<void> pauseRecording() async {
    if (_recordingPath == null) return;
    await _recorder.pause();
  }

  @override
  Future<void> resumeRecording() async {
    if (_recordingPath == null) return;
    await _recorder.resume();
  }

  @override
  Future<VoiceRecording?> stopRecording() async {
    final startedAt = _recordingStartedAt;
    _recordingPath = null;
    _recordingStartedAt = null;

    final path = await _recorder.stop();
    if (path == null || startedAt == null) return null;
    return VoiceRecording(
      path: path,
      duration: DateTime.now().difference(startedAt),
    );
  }

  @override
  Future<void> discardRecording(String path) async {
    if (_recordingPath == path) {
      _recordingPath = null;
      _recordingStartedAt = null;
      await _recorder.stop();
    }
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  @override
  Future<bool> fileExists(String path) async {
    if (path.isEmpty) return false;
    try {
      return await File(path).exists();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> openFile(String path) async {
    final result = await OpenFilex.open(path);
    if (result.type != ResultType.done) {
      throw StateError(result.message);
    }
  }

  @override
  Future<void> playAudio(String path) async {
    if (_disposed) throw StateError('Media gateway has been disposed.');
    await _disposePlayer();

    final player = AudioPlayer();
    _player = player;
    _playerSubscription = player.onPlayerComplete.listen((_) {
      if (!_playbackCompleted.isClosed) _playbackCompleted.add(null);
    });
    final source = path.startsWith(RegExp(r'https?://'))
        ? UrlSource(path)
        : DeviceFileSource(path);
    await player.play(source);
  }

  @override
  Future<void> stopAudio() => _disposePlayer();

  Future<void> _disposePlayer() async {
    final subscription = _playerSubscription;
    _playerSubscription = null;
    if (subscription != null) await subscription.cancel();

    final player = _player;
    _player = null;
    if (player != null) await player.dispose();
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

    final activePath = _recordingPath;
    _recordingPath = null;
    _recordingStartedAt = null;
    if (activePath != null) {
      try {
        await _recorder.stop();
      } catch (_) {
        // The recorder may already be stopped if the OS revoked the session.
      }
      try {
        final file = File(activePath);
        if (await file.exists()) await file.delete();
      } catch (_) {
        // Best-effort cleanup of the temporary recording.
      }
    }

    await _disposePlayer();
    await _recorder.dispose();
    await _playbackCompleted.close();
  }
}
