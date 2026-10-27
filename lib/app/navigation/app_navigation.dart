import 'package:flutter/widgets.dart';

/// Single root navigator used by GoRouter and app-level coordinators.
///
/// A stable key lets future call/push coordinators navigate without holding a
/// BuildContext from a screen that may already be disposed.
final GlobalKey<NavigatorState> appRootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'app-root-navigator',
);
