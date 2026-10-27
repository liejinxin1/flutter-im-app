import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../ui/core/theme/app_theme.dart';

/// In the Widget Previewer the app's assets live under
/// `packages/agora_im_flutter/...`, while normal app tests/builds use the root
/// asset keys. This bundle tries the package-prefixed key first and falls back
/// to the root key, so the same widgets render in both environments.
class PreviewAssetBundle extends CachingAssetBundle {
  static const _packagePrefix = 'packages/agora_im_flutter/';

  String _resolve(String key) =>
      key.startsWith('assets/') ? '$_packagePrefix$key' : key;

  @override
  Future<ByteData> load(String key) async {
    final resolved = _resolve(key);
    try {
      return await rootBundle.load(resolved);
    } catch (_) {
      return rootBundle.load(key);
    }
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final resolved = _resolve(key);
    try {
      return await rootBundle.loadString(resolved, cache: cache);
    } catch (_) {
      return rootBundle.loadString(key, cache: cache);
    }
  }
}

/// Wraps a real page in the app theme and a phone-sized viewport so the
/// Widget Previewer matches the device layout, including status/nav insets.
class PreviewHost extends StatelessWidget {
  const PreviewHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: MediaQuery(
      data: const MediaQueryData(
        size: Size(393, 852),
        devicePixelRatio: 3,
        padding: EdgeInsets.only(top: 24, bottom: 24),
        viewPadding: EdgeInsets.only(top: 24, bottom: 24),
      ),
      child: DefaultAssetBundle(bundle: PreviewAssetBundle(), child: child),
    ),
  );
}
