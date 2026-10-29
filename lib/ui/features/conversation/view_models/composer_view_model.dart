import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../domain/errors/app_failure.dart';
import '../../../../domain/models/chat_message.dart';
import '../../../../domain/models/voice_recording.dart';
import '../../../../domain/services/media_gateway.dart';
import '../../../core/localization/app_error.dart';
import '../../../core/view_model.dart';

/// Presentation state for the composer: attachment sheet, voice recording,
/// audio playback, and short-lived user notices.
///
/// Device plugins stay behind [MediaGateway]; the ViewModel remains unit
/// testable and free of `dart:io`.
class ComposerViewModel extends ViewModel {
  ComposerViewModel(this._media, this._resolveAttachment) {
    _playbackSubscription = _media.playbackCompleted.listen((_) {
      if (isDisposed) return;
      playingMessageId.value = null;
    });
  }

  final MediaGateway _media;
  final Future<String?> Function(ChatMessage message) _resolveAttachment;
  late final StreamSubscription<void> _playbackSubscription;
  Timer? _recordingTicker;

  /// Kept separate from [notifyListeners] so the recording ticker and other
  /// composer state do not rebuild the whole message timeline every second.
  final ValueNotifier<String?> playingMessageId = ValueNotifier<String?>(null);

  bool _attachmentsExpanded = false;
  bool get attachmentsExpanded => _attachmentsExpanded;
  bool _isRecording = false;
  bool get isRecording => _isRecording;
  bool _isPaused = false;
  bool get isPaused => _isPaused;
  Duration _elapsed = Duration.zero;
  Duration get elapsed => _elapsed;
  bool _isBusy = false;
  bool get isBusy => _isBusy;
  AppError? _notice;
  AppError? get notice => _notice;

  void toggleAttachments() {
    if (_isRecording) return;
    _attachmentsExpanded = !_attachmentsExpanded;
    notifyListeners();
  }

  void closeAttachments() {
    if (!_attachmentsExpanded) return;
    _attachmentsExpanded = false;
    notifyListeners();
  }

  void consumeNotice() => _notice = null;

  Future<String?> pickImage(MediaImageSource source) async {
    _attachmentsExpanded = false;
    _notice = null;
    notifyListeners();
    try {
      return await _media.pickImage(source: source);
    } catch (error) {
      _setNotice(
        AppError(AppErrorCode.imagePickFailed, detail: friendlyError(error)),
      );
      return null;
    }
  }

  /// Starts recording and switches the composer into the recording bar.
  Future<void> startRecordingMode() async {
    if (_isRecording) return;
    _attachmentsExpanded = false;
    notifyListeners();
    await _startRecording();
  }

  /// Stops the active recording and returns it for sending.
  Future<VoiceRecording?> finishRecording() => _stopRecording();

  /// Discards the active recording without sending it.
  Future<void> cancelRecording() async {
    if (!_isRecording) return;
    _recordingTicker?.cancel();
    _recordingTicker = null;
    final wasPaused = _isPaused;
    _isRecording = false;
    _isPaused = false;
    _elapsed = Duration.zero;
    try {
      if (wasPaused) await _media.resumeRecording();
      final recording = await _media.stopRecording();
      if (recording != null) await _media.discardRecording(recording.path);
    } catch (_) {
      // Canceling must not surface an error.
    } finally {
      notifyListeners();
    }
  }

  Future<void> togglePause() async {
    if (!_isRecording || _isBusy) return;
    _isPaused = !_isPaused;
    try {
      if (_isPaused) {
        await _media.pauseRecording();
      } else {
        await _media.resumeRecording();
      }
    } catch (_) {
      _isPaused = !_isPaused;
    }
    notifyListeners();
  }

  /// Starts a recording, or stops and returns the finished recording.
  ///
  /// Returns `null` when starting, when permission is denied, or when the clip
  /// is too short (in which case a notice is exposed for the view).
  Future<VoiceRecording?> toggleRecording() async {
    if (_isRecording) return _stopRecording();
    return _startRecording();
  }

  Future<VoiceRecording?> _startRecording() async {
    if (_isBusy) return null;
    _isBusy = true;
    _notice = null;
    notifyListeners();
    try {
      if (!await _media.hasMicrophonePermission()) {
        if (isDisposed) return null;
        _setNotice(const AppError(AppErrorCode.microphonePermission));
        return null;
      }
      if (isDisposed) return null;
      await _media.startRecording();
      if (isDisposed) {
        final recording = await _media.stopRecording();
        if (recording != null) await _media.discardRecording(recording.path);
        return null;
      }
      _isRecording = true;
      _isPaused = false;
      _elapsed = Duration.zero;
      _recordingTicker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_isPaused) return;
        _elapsed += const Duration(seconds: 1);
        notifyListeners();
      });
      return null;
    } catch (error) {
      _setNotice(
        AppError(
          AppErrorCode.recordingStartFailed,
          detail: friendlyError(error),
        ),
      );
      return null;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<VoiceRecording?> _stopRecording() async {
    if (_isBusy) return null;
    _isBusy = true;
    _recordingTicker?.cancel();
    _recordingTicker = null;
    try {
      final recording = await _media.stopRecording();
      _isRecording = false;
      _isPaused = false;
      _elapsed = Duration.zero;
      if (recording == null) return null;
      if (recording.duration < const Duration(seconds: 1)) {
        await _media.discardRecording(recording.path);
        _setNotice(const AppError(AppErrorCode.recordingTooShort));
        return null;
      }
      return recording;
    } catch (error) {
      _isRecording = false;
      _elapsed = Duration.zero;
      _setNotice(
        AppError(
          AppErrorCode.recordingStopFailed,
          detail: friendlyError(error),
        ),
      );
      return null;
    } finally {
      _isBusy = false;
      _attachmentsExpanded = false;
      notifyListeners();
    }
  }

  Future<void> togglePlayback(ChatMessage message) async {
    if (isDisposed) return;
    if (playingMessageId.value == message.id) {
      await stopPlayback();
      return;
    }

    try {
      var path = message.localPath;
      if (path == null || path.isEmpty) {
        final content = message.content;
        if (content is VoiceMessageContent &&
            content.remotePath != null &&
            content.remotePath!.startsWith(RegExp(r'https?://'))) {
          path = content.remotePath;
        }
      }
      if (path == null ||
          path.isEmpty ||
          (!path.startsWith(RegExp(r'https?://')) &&
              !await _media.fileExists(path))) {
        path = await _resolveAttachment(message);
      }
      if (isDisposed) return;
      if (path == null || path.isEmpty) {
        _setNotice(const AppError(AppErrorCode.voiceNotDownloaded));
        return;
      }
      await _media.playAudio(path);
      if (isDisposed) return;
      playingMessageId.value = message.id;
    } catch (error) {
      if (isDisposed) return;
      playingMessageId.value = null;
      _setNotice(
        AppError(
          AppErrorCode.voicePlaybackFailed,
          detail: friendlyError(error),
        ),
      );
    }
  }

  Future<void> stopPlayback() async {
    await _media.stopAudio();
    if (isDisposed) return;
    playingMessageId.value = null;
  }

  void _setNotice(AppError message) {
    if (isDisposed) return;
    _notice = message;
    notifyListeners();
  }

  @override
  void dispose() {
    _recordingTicker?.cancel();
    _playbackSubscription.cancel();
    unawaited(_releaseMedia());
    playingMessageId.dispose();
    super.dispose();
  }

  Future<void> _releaseMedia() async {
    try {
      if (_isRecording) {
        final recording = await _media.stopRecording();
        if (recording != null) await _media.discardRecording(recording.path);
      }
      await _media.stopAudio();
    } catch (_) {
      // Leaving the screen should never throw; the OS will reclaim the session.
    }
  }
}
