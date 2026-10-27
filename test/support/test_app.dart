import 'package:agora_im_flutter/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Wraps a screen with the app's localization configuration.
///
/// Tests default to Chinese so existing copy assertions stay readable; pass
/// `locale: const Locale('en')` to exercise English.
Widget testApp(Widget home, {Locale locale = const Locale('zh')}) =>
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );
