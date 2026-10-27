import 'package:flutter/material.dart';

/// Deterministic initial avatar used across inbox, contacts, profile, and chat.
///
/// Using a stable per-user color avoids shipping one shared placeholder image
/// and keeps the UI readable while user profiles/avatars are not yet fetched.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.userId,
    this.radius = 22,
    this.foregroundImage,
  });

  final String userId;
  final double radius;
  final ImageProvider? foregroundImage;

  static const _tones = <Color>[
    Color(0xFF1F7FB8),
    Color(0xFF2B8A6E),
    Color(0xFF8A5A2B),
    Color(0xFF6B5BB5),
    Color(0xFFB04E6E),
    Color(0xFF4A6B8A),
  ];

  @override
  Widget build(BuildContext context) {
    final id = userId.trim();
    final seed = id.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
    final tone = _tones[seed % _tones.length];
    final initial = id.isEmpty
        ? '?'
        : String.fromCharCode(id.runes.first).toUpperCase();

    return CircleAvatar(
      radius: radius,
      backgroundColor: tone.withValues(alpha: .14),
      foregroundImage: foregroundImage,
      child: Text(
        initial,
        style: TextStyle(
          color: tone,
          fontSize: radius * .68,
          fontWeight: FontWeight.w600,
          height: 1,
        ),
      ),
    );
  }
}
