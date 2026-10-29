import 'package:flutter/material.dart';

import '../../../core/localization/l10n.dart';
import '../../../core/theme/app_theme.dart';

class VoiceRecordingBar extends StatelessWidget {
  const VoiceRecordingBar({
    super.key,
    required this.elapsed,
    required this.isPaused,
    required this.isBusy,
    required this.onPause,
    required this.onCancel,
    required this.onSend,
  });

  final Duration elapsed;
  final bool isPaused;
  final bool isBusy;
  final VoidCallback onPause;
  final VoidCallback onCancel;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.surface,
    padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
    child: SafeArea(
      top: false,
      child: Row(
        children: [
          IconButton(
            tooltip: context.l10n.cancel,
            onPressed: isBusy ? null : onCancel,
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Color(0xFFD95656),
              size: 27,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4BC9F4), Color(0xFF19AEEB)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 7),
                  InkWell(
                    onTap: isBusy ? null : onPause,
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPaused
                            ? Icons.play_arrow_rounded
                            : Icons.pause_rounded,
                        color: const Color(0xFF1EA9E4),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(child: _Waveform()),
                  const SizedBox(width: 8),
                  Text(
                    _format(elapsed),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 46,
            height: 46,
            child: FilledButton(
              onPressed: isBusy ? null : onSend,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.send,
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                shape: const CircleBorder(),
              ),
              child: const Icon(Icons.send_rounded, size: 22),
            ),
          ),
        ],
      ),
    ),
  );

  String _format(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _Waveform extends StatelessWidget {
  const _Waveform();

  static const _bars = [
    6.0,
    12.0,
    20.0,
    10.0,
    26.0,
    16.0,
    30.0,
    12.0,
    22.0,
    8.0,
    18.0,
    26.0,
    14.0,
    7.0,
    12.0,
    5.0,
    4.0,
    3.0,
    3.0,
    2.0,
  ];

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      for (final height in _bars)
        Container(
          width: 1.5,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: height < 5 ? .55 : .95),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
    ],
  );
}
