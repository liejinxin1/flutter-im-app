import 'package:flutter/widgets.dart';

import 'local_image_stub.dart'
    if (dart.library.io) 'local_image_io.dart'
    as impl;

/// Renders a local file image on IO platforms and a graceful placeholder on
/// Web, keeping `dart:io` out of the presentation layer.
class LocalImage extends StatelessWidget {
  const LocalImage({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorBuilder,
  });

  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) => impl.buildLocalImage(
    path: path,
    width: width,
    height: height,
    fit: fit,
    errorBuilder: errorBuilder,
  );
}
