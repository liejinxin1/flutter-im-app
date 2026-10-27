import 'package:agora_im_flutter/domain/models/chat_message_content.dart';
import 'package:agora_im_flutter/domain/models/chat_message_envelope.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatMessageEnvelope', () {
    test('round-trips text', () {
      final envelope = const ChatMessageEnvelope(
        clientId: 'c1',
        content: TextMessageContent('hello'),
      );

      final decoded = ChatMessageEnvelope.tryDecode(envelope.encode());

      expect(decoded?.clientId, 'c1');
      expect(decoded?.content, isA<TextMessageContent>());
      expect((decoded!.content as TextMessageContent).text, 'hello');
    });

    test('uses the uploaded URL and omits local paths', () {
      final envelope = const ChatMessageEnvelope(
        clientId: 'c2',
        content: ImageMessageContent(
          localPath: '/private/photo.jpg',
          remotePath: 'https://oss.example/photo.jpg',
          width: 800,
          height: 600,
        ),
      );

      final encoded = envelope.encode();
      expect(encoded, isNot(contains('/private/photo.jpg')));

      final decoded = ChatMessageEnvelope.tryDecode(encoded);
      final image = decoded!.content as ImageMessageContent;
      expect(image.remotePath, 'https://oss.example/photo.jpg');
      expect(image.localPath, isNull);
      expect(image.width, 800);
      expect(image.height, 600);
    });

    test('rejects missing remote URLs for attachments', () {
      const envelope = ChatMessageEnvelope(
        clientId: 'c3',
        content: VoiceMessageContent(
          localPath: '/private/voice.m4a',
          durationSeconds: 5,
        ),
      );

      expect(() => envelope.encode(), throwsStateError);
    });

    test('ignores unknown versions and malformed payloads', () {
      expect(
        ChatMessageEnvelope.tryDecode('{"v":99,"clientId":"c","kind":"text"}'),
        isNull,
      );
      expect(ChatMessageEnvelope.tryDecode('not-json'), isNull);
    });
  });
}
