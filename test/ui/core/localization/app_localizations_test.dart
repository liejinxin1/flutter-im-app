import 'package:agora_im_flutter/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('English and Chinese bundles are generated', () async {
    final english = await AppLocalizations.delegate.load(const Locale('en'));
    final chinese = await AppLocalizations.delegate.load(const Locale('zh'));

    expect(english.loginTitle, 'Log in to Agora Chat');
    expect(chinese.loginTitle, '登录 Agora Chat');
    expect(english.selectedCount(2), '2 selected');
    expect(chinese.selectedCount(2), '已选择 2 人');
    expect(english.rtcVoiceComingSoon, contains('Voice calls'));
    expect(chinese.rtcVoiceComingSoon, contains('语音通话'));
  });
}
