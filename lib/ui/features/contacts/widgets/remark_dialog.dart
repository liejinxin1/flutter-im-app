import 'package:flutter/material.dart';

import '../../../core/localization/l10n.dart';

class RemarkDialog extends StatefulWidget {
  const RemarkDialog({super.key, this.initialRemark});

  final String? initialRemark;

  @override
  State<RemarkDialog> createState() => _RemarkDialogState();
}

class _RemarkDialogState extends State<RemarkDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialRemark);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.l10n.editRemark),
    content: TextField(
      controller: _controller,
      autofocus: true,
      maxLength: 64,
      decoration: InputDecoration(hintText: context.l10n.remarkHint),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(context.l10n.cancel),
      ),
      FilledButton(
        onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
        child: Text(context.l10n.save),
      ),
    ],
  );
}
