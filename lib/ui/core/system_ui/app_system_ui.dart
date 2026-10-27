import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Centralized edge-to-edge system bar configuration.
///
/// Status bar stays transparent so the page's own background/header shows
/// through. The Android navigation bar is painted by [SystemNavBarInset] or by
/// [AppBottomNav]'s white SafeArea, because Android 15 ignores
/// `systemNavigationBarColor` under edge-to-edge enforcement.
abstract final class AppSystemUi {
  static const SystemUiOverlayStyle lightStatus = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarContrastEnforced: false,
  );

  static const SystemUiOverlayStyle darkStatus = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarContrastEnforced: false,
  );

  static Future<void> configure() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(darkStatus);
  }
}

/// A white strip that occupies only the system navigation bar inset.
///
/// Use as `Scaffold.bottomNavigationBar` on pages without an app bottom bar so
/// the Android system nav area is white even when the page background is the
/// canvas color.
class SystemNavBarInset extends StatelessWidget {
  const SystemNavBarInset({super.key, this.color = Colors.white});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.viewPaddingOf(context).bottom;
    if (height <= 0) return const SizedBox.shrink();
    return ColoredBox(
      color: color,
      child: SizedBox(height: height),
    );
  }
}
