import 'package:agora_im_flutter/ui/features/conversation/widgets/voice_recording_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';

void main() {
  testWidgets('forwards pause, cancel, and send recording actions', (
    tester,
  ) async {
    var paused = 0;
    var canceled = 0;
    var sent = 0;

    await tester.pumpWidget(
      testApp(
        Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: VoiceRecordingBar(
              elapsed: const Duration(seconds: 5),
              isPaused: false,
              isBusy: false,
              onPause: () => paused++,
              onCancel: () => canceled++,
              onSend: () => sent++,
            ),
          ),
        ),
      ),
    );

    expect(find.text('00:05'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.pause_rounded));
    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();

    expect(paused, 1);
    expect(canceled, 1);
    expect(sent, 1);
  });
}
