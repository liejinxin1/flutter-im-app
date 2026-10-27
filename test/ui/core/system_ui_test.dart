import 'package:agora_im_flutter/ui/core/system_ui/app_system_ui.dart';
import 'package:agora_im_flutter/ui/core/widgets/gradient_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('gradient header includes the status bar inset', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(padding: EdgeInsets.only(top: 24)),
          child: Scaffold(body: GradientHeader(title: 'Chats')),
        ),
      ),
    );

    expect(tester.getSize(find.byType(GradientHeader)).height, 82 + 24);
  });

  testWidgets('system nav inset fills only the bottom system bar', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(viewPadding: EdgeInsets.only(bottom: 48)),
          child: Scaffold(
            bottomNavigationBar: SystemNavBarInset(),
            body: SizedBox.expand(),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(SystemNavBarInset)).height, 48);
  });
}
