import 'package:flutter/material.dart';

import '../../../core/localization/l10n.dart';
import '../../../core/theme/app_theme.dart';

/// Floating card attachment grid under the timeline.
class AttachmentPanel extends StatelessWidget {
  const AttachmentPanel({
    super.key,
    required this.isRecording,
    required this.elapsed,
    required this.isBusy,
    required this.onCamera,
    required this.onGallery,
    required this.onRecord,
    required this.onContact,
    required this.onLocation,
    required this.onDocument,
  });

  final bool isRecording;
  final Duration elapsed;
  final bool isBusy;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onRecord;
  final VoidCallback onContact;
  final VoidCallback onLocation;
  final VoidCallback onDocument;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE8EEF5), width: 1),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0F0D2447),
                  blurRadius: 18,
                  offset: Offset(0, 6),
                ),
                BoxShadow(
                  color: Color(0x0A0D2447),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    _AttachmentAction(
                      icon: Icons.camera_alt_rounded,
                      label: l10n.camera,
                      onTap: onCamera,
                    ),
                    _AttachmentAction(
                      icon: isRecording
                          ? Icons.stop_rounded
                          : Icons.mic_rounded,
                      label: isRecording
                          ? l10n.stopRecording(_format(elapsed))
                          : l10n.voiceRecording,
                      onTap: isBusy ? null : onRecord,
                      highlight: isRecording,
                    ),
                    _AttachmentAction(
                      icon: Icons.photo_library_rounded,
                      label: l10n.gallery,
                      onTap: onGallery,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _AttachmentAction(
                      icon: Icons.person_rounded,
                      label: l10n.contact,
                      onTap: onContact,
                    ),
                    _AttachmentAction(
                      icon: Icons.location_on_rounded,
                      label: l10n.location,
                      onTap: onLocation,
                    ),
                    _AttachmentAction(
                      icon: Icons.insert_drive_file_rounded,
                      label: l10n.document,
                      onTap: onDocument,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _format(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _AttachmentAction extends StatelessWidget {
  const _AttachmentAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final bgGradient = highlight
        ? const LinearGradient(
            colors: [Color(0xFFFF5E5E), AppColors.danger],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFF38C5FF), AppColors.send],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    final glowColor = highlight
        ? AppColors.danger.withValues(alpha: 0.32)
        : AppColors.send.withValues(alpha: 0.28);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.send.withValues(alpha: 0.12),
          highlightColor: AppColors.send.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Opacity(
              opacity: onTap == null ? .45 : 1,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: bgGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: glowColor,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF383C49),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
