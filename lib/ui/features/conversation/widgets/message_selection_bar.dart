import 'package:flutter/material.dart';

import '../../../core/localization/l10n.dart';
import '../../../core/theme/app_theme.dart';

class MessageSelectionBar extends StatelessWidget {
  const MessageSelectionBar({
    super.key,
    required this.count,
    required this.onClose,
    required this.onCopy,
    required this.onForward,
    required this.onDelete,
  });

  final int count;
  final VoidCallback onClose;
  final VoidCallback onCopy;
  final VoidCallback onForward;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Material(
      color: AppColors.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            children: [
              IconButton(
                tooltip: l10n.cancel,
                onPressed: onClose,
                icon: const Icon(Icons.close),
              ),
              Expanded(
                child: Text(
                  l10n.selectedMessages(count),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _Action(
                label: l10n.copy,
                icon: Icons.copy_outlined,
                onPressed: onCopy,
              ),
              _Action(
                label: l10n.forward,
                icon: Icons.forward_outlined,
                onPressed: onForward,
              ),
              _Action(
                label: l10n.delete,
                icon: Icons.delete_outline,
                onPressed: onDelete,
                color: AppColors.danger,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: label,
    onPressed: onPressed,
    icon: Icon(icon, color: color),
  );
}
