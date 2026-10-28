import 'package:agora_im_flutter/domain/models/chat_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatMessageContent', () {
    test('round-trips every first-class content type', () {
      final contents = <ChatMessageContent>[
        const TextMessageContent('hello'),
        const TextMessageContent(
          'reply',
          quote: ChatMessageQuote(
            messageId: 'm1',
            senderId: 'peer',
            kind: ChatMessageKind.text,
            text: 'hello',
          ),
        ),
        const ImageMessageContent(
          localPath: '/tmp/a.jpg',
          remotePath: 'https://example/a.jpg',
          thumbnailLocalPath: '/tmp/a-thumb.jpg',
          width: 800,
          height: 600,
        ),
        const VoiceMessageContent(localPath: '/tmp/a.m4a', durationSeconds: 7),
        const FileMessageContent(
          fileName: 'brief.pdf',
          fileSizeBytes: 1234,
          mimeType: 'application/pdf',
          remotePath: 'https://example/brief.pdf',
        ),
        const VideoMessageContent(
          localPath: '/tmp/a.mp4',
          durationSeconds: 12,
          width: 1920,
          height: 1080,
        ),
        const LocationMessageContent(
          latitude: 31.2,
          longitude: 121.5,
          address: 'Shanghai',
        ),
        const ContactMessageContent(userId: 'alice', displayName: 'Alice'),
        const CustomMessageContent(event: 'rtc_call', params: {'callId': 'c1'}),
        const SystemMessageContent(text: 'recalled', systemType: 'recall'),
        const UnknownMessageContent(rawType: 'combine'),
      ];

      for (final content in contents) {
        final decoded = ChatMessageContent.fromJson(content.toJson());
        expect(decoded.runtimeType, content.runtimeType);
        expect(decoded.toJson(), content.toJson());
      }
    });

    test('reads legacy flat message caches', () {
      final message = ChatMessage.fromJson({
        'id': 'm1',
        'conversationId': 'peer',
        'senderId': 'peer',
        'text': '',
        'kind': 'voice',
        'localPath': '/tmp/legacy.m4a',
        'durationSeconds': 5,
        'sentAt': 1,
        'deliveryState': 'sent',
        'isOutgoing': false,
      });

      expect(message.content, isA<VoiceMessageContent>());
      final voice = message.content as VoiceMessageContent;
      expect(voice.localPath, '/tmp/legacy.m4a');
      expect(voice.durationSeconds, 5);
    });

    test('keeps cached attachment paths when merging an SDK update', () {
      final merged = mergeChatMessageContent(
        const ImageMessageContent(
          localPath: '/cache/a.jpg',
          thumbnailLocalPath: '/cache/a-thumb.jpg',
        ),
        const ImageMessageContent(remotePath: 'https://example/a.jpg'),
      );

      expect(merged, isA<ImageMessageContent>());
      final image = merged as ImageMessageContent;
      expect(image.localPath, '/cache/a.jpg');
      expect(image.thumbnailLocalPath, '/cache/a-thumb.jpg');
      expect(image.remotePath, 'https://example/a.jpg');
    });
  });
}
