import 'dart:async';

import 'package:agora_im_flutter/domain/models/chat_message.dart';
import 'package:agora_im_flutter/domain/models/voice_recording.dart';
import 'package:agora_im_flutter/ui/core/localization/app_error.dart';
import 'package:agora_im_flutter/ui/features/conversation/view_models/composer_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fakes.dart';

void main() {
  group('ComposerViewModel', () {
    test('starts and stops a recording', () async {
      final media = FakeMediaGateway();
      final viewModel = ComposerViewModel(media, (message) async => null);
      addTearDown(media.dispose);
      addTearDown(viewModel.dispose);

      viewModel.toggleAttachments();
      expect(viewModel.attachmentsExpanded, isTrue);

      final started = await viewModel.toggleRecording();
      expect(started, isNull);
      expect(viewModel.isRecording, isTrue);
      expect(media.startRecordingCalls, 1);
      expect(viewModel.attachmentsExpanded, isTrue);

      final recording = await viewModel.toggleRecording();
      expect(recording?.path, '/tmp/voice.m4a');
      expect(viewModel.isRecording, isFalse);
      expect(media.stopRecordingCalls, 1);
      expect(viewModel.attachmentsExpanded, isFalse);
    });

    test('discards clips shorter than one second', () async {
      final media = FakeMediaGateway()
        ..nextRecording = const VoiceRecording(
          path: '/tmp/short.m4a',
          duration: Duration(milliseconds: 600),
        );
      final viewModel = ComposerViewModel(media, (message) async => null);
      addTearDown(media.dispose);
      addTearDown(viewModel.dispose);

      await viewModel.toggleRecording();
      final recording = await viewModel.toggleRecording();

      expect(recording, isNull);
      expect(media.discardedPaths, ['/tmp/short.m4a']);
      expect(viewModel.notice?.code, AppErrorCode.recordingTooShort);
    });

    test('reports missing microphone permission', () async {
      final media = FakeMediaGateway()..microphonePermission = false;
      final viewModel = ComposerViewModel(media, (message) async => null);
      addTearDown(media.dispose);
      addTearDown(viewModel.dispose);

      await viewModel.toggleRecording();

      expect(media.startRecordingCalls, 0);
      expect(viewModel.isRecording, isFalse);
      expect(viewModel.notice?.code, AppErrorCode.microphonePermission);
    });

    test('downloads a remote voice message before playing it', () async {
      final media = FakeMediaGateway();
      var resolved = false;
      final viewModel = ComposerViewModel(media, (message) async {
        resolved = true;
        return '/download/voice.m4a';
      });
      addTearDown(media.dispose);
      addTearDown(viewModel.dispose);

      final message = ChatMessage(
        id: 'voice-1',
        conversationId: 'peer',
        senderId: 'peer',
        text: '',
        sentAt: DateTime(2026),
        deliveryState: ChatMessageDeliveryState.sent,
        isOutgoing: false,
        kind: ChatMessageKind.voice,
        durationSeconds: 2,
      );

      await viewModel.togglePlayback(message);

      expect(resolved, isTrue);
      expect(media.playedPaths, ['/download/voice.m4a']);
      expect(viewModel.playingMessageId.value, 'voice-1');

      media.completePlayback();
      await Future<void>.delayed(Duration.zero);
      expect(viewModel.playingMessageId.value, isNull);
    });

    test('cleans up if disposed while start is in flight', () async {
      final gate = Completer<void>();
      final media = FakeMediaGateway()..startRecordingGate = gate;
      final viewModel = ComposerViewModel(media, (message) async => null);

      final pending = viewModel.toggleRecording();
      await Future<void>.delayed(Duration.zero);
      expect(media.startRecordingCalls, 1);
      viewModel.dispose();
      gate.complete();
      await pending;

      expect(media.stopRecordingCalls, 1);
      expect(media.discardedPaths, ['/tmp/voice.m4a']);
      await media.dispose();
    });

    test('plays a custom-protocol voice URL without downloading', () async {
      final media = FakeMediaGateway();
      var resolved = false;
      final viewModel = ComposerViewModel(media, (message) async {
        resolved = true;
        return null;
      });
      addTearDown(media.dispose);
      addTearDown(viewModel.dispose);

      final message = ChatMessage(
        id: 'voice-url',
        conversationId: 'peer',
        senderId: 'peer',
        content: const VoiceMessageContent(
          remotePath: 'https://oss.example/voice.m4a',
          durationSeconds: 4,
        ),
        sentAt: DateTime(2026),
        deliveryState: ChatMessageDeliveryState.sent,
        isOutgoing: false,
      );

      await viewModel.togglePlayback(message);

      expect(resolved, isFalse);
      expect(media.playedPaths, ['https://oss.example/voice.m4a']);
      expect(viewModel.playingMessageId.value, 'voice-url');
    });

    test('re-downloads a voice message when the cached file is gone', () async {
      final media = FakeMediaGateway()..missingPaths.add('/stale/voice.m4a');
      var resolved = false;
      final viewModel = ComposerViewModel(media, (message) async {
        resolved = true;
        return '/download/voice.m4a';
      });
      addTearDown(media.dispose);
      addTearDown(viewModel.dispose);

      final message = ChatMessage(
        id: 'voice-stale',
        conversationId: 'peer',
        senderId: 'peer',
        text: '',
        sentAt: DateTime(2026),
        deliveryState: ChatMessageDeliveryState.sent,
        isOutgoing: false,
        kind: ChatMessageKind.voice,
        localPath: '/stale/voice.m4a',
        durationSeconds: 7,
      );

      await viewModel.togglePlayback(message);

      expect(resolved, isTrue);
      expect(media.playedPaths, ['/download/voice.m4a']);
      expect(viewModel.playingMessageId.value, 'voice-stale');
    });
  });
}
