import 'package:flutter/material.dart';

import '../../../core/widgets/local_image.dart';

Future<void> showImagePreview(BuildContext context, String path) {
  final isNetwork = path.startsWith(RegExp(r'https?://'));
  return showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      insetPadding: const EdgeInsets.all(20),
      backgroundColor: Colors.black,
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: InteractiveViewer(
          child: isNetwork
              ? Image.network(path, fit: BoxFit.contain)
              : LocalImage(path: path, fit: BoxFit.contain),
        ),
      ),
    ),
  );
}
