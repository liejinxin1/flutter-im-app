import 'package:flutter/material.dart';

import '../../../core/localization/l10n.dart';

/// Attachment grid from the Figma Ver2 conversation design.
class AttachmentPanel extends StatelessWidget {
  const AttachmentPanel({
    super.key,
    required this.onCamera,
    required this.onGallery,
    required this.onRecord,
    required this.onContact,
    required this.onLocation,
    required this.onDocument,
  });

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
      color: Colors.white,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _AttachmentAction(
                icon: Icons.photo_camera_rounded,
                label: l10n.camera,
                color: const Color(0xFFF25C5C),
                onTap: onCamera,
              ),
              _AttachmentAction(
                icon: Icons.mic_none_rounded,
                label: l10n.voiceRecording,
                color: const Color(0xFF64CFF5),
                onTap: onRecord,
              ),
              _AttachmentAction(
                icon: Icons.person_rounded,
                label: l10n.contact,
                color: const Color(0xFF3F76C5),
                onTap: onContact,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _AttachmentAction(
                icon: Icons.image_outlined,
                label: l10n.gallery,
                color: const Color(0xFFF0C21B),
                onTap: onGallery,
              ),
              _AttachmentAction(
                icon: Icons.location_on_rounded,
                label: l10n.myLocation,
                color: const Color(0xFF20B7E7),
                onTap: onLocation,
              ),
              _AttachmentAction(
                icon: Icons.description_outlined,
                label: l10n.documentAction,
                color: const Color(0xFF34B77B),
                onTap: onDocument,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttachmentAction extends StatelessWidget {
  const _AttachmentAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 23),
            ),
            const SizedBox(height: 9),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF2F3440),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
