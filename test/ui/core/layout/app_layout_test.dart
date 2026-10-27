import 'package:agora_im_flutter/ui/core/layout/app_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps widths to compact, medium, and expanded', () {
    expect(AppBreakpoints.windowClassForWidth(320), AppWindowClass.compact);
    expect(AppBreakpoints.windowClassForWidth(600), AppWindowClass.medium);
    expect(AppBreakpoints.windowClassForWidth(900), AppWindowClass.expanded);
    expect(AppBreakpoints.windowClassForWidth(1400), AppWindowClass.expanded);
  });
}
