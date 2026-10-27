import 'dart:io';

import 'package:flutter/widgets.dart';

Widget buildLocalImage({
  required String path,
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  ImageErrorWidgetBuilder? errorBuilder,
}) => Image.file(
  File(path),
  width: width,
  height: height,
  fit: fit,
  errorBuilder: errorBuilder,
);
