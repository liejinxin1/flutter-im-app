import 'package:flutter/widgets.dart';

enum AppWindowClass { compact, medium, expanded }

abstract final class AppBreakpoints {
  static const double medium = 600;
  static const double expanded = 900;

  static AppWindowClass windowClassOf(BuildContext context) =>
      windowClassForWidth(MediaQuery.sizeOf(context).width);

  static AppWindowClass windowClassForWidth(double width) {
    if (width >= expanded) return AppWindowClass.expanded;
    if (width >= medium) return AppWindowClass.medium;
    return AppWindowClass.compact;
  }

  static bool isExpanded(BuildContext context) =>
      windowClassOf(context) == AppWindowClass.expanded;
}

/// Centers page content on tablets/desktop while leaving phones untouched.
class AppContentFrame extends StatelessWidget {
  const AppContentFrame({
    super.key,
    required this.child,
    this.maxWidth = 760,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Padding(padding: padding, child: child),
    ),
  );
}
