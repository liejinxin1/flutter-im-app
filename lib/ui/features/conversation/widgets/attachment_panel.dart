import 'package:flutter/material.dart';

import '../../../core/localization/l10n.dart';
import '../../../core/theme/app_theme.dart';

/// Expandable attachment grid under the timeline.
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
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        children: [
          Row(
            children: [
              _AttachmentAction(
                icon: Icons.camera_alt_outlined,
                label: l10n.camera,
                onTap: onCamera,
              ),
              _AttachmentAction(
                icon: isRecording ? Icons.stop_rounded : Icons.mic_none_rounded,
                label: isRecording
                    ? l10n.stopRecording(_format(elapsed))
                    : l10n.voiceRecording,
                onTap: isBusy ? null : onRecord,
                highlight: isRecording,
              ),
              _AttachmentAction(
                icon: Icons.photo_library_outlined,
                label: l10n.gallery,
                onTap: onGallery,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _AttachmentAction(
                icon: Icons.person_outline_rounded,
                label: l10n.contact,
                onTap: onContact,
              ),
              _AttachmentAction(
                icon: Icons.location_on_outlined,
                label: l10n.location,
                onTap: onLocation,
              ),
              _AttachmentAction(
                icon: Icons.insert_drive_file_outlined,
                label: l10n.document,
                onTap: onDocument,
              ),
            ],
          ),
        ],
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
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Opacity(
        opacity: onTap == null ? .45 : 1,
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: highlight ? AppColors.danger : AppColors.send,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 23),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF424652), fontSize: 11),
            ),
          ],
        ),
      ),
    ),
  );
}
