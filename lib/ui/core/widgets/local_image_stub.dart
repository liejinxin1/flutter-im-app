import 'package:flutter/material.dart';

Widget buildLocalImage({
  required String path,
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  ImageErrorWidgetBuilder? errorBuilder,
}) => SizedBox(
  width: width,
  height: height,
  child: const Center(
    child: Icon(Icons.image_not_supported_outlined, color: Colors.black38),
  ),
);
