/// A finished local voice recording produced by a platform recorder.
class VoiceRecording {
  const VoiceRecording({required this.path, required this.duration});

  final String path;
  final Duration duration;

  int get seconds => duration.inSeconds;
}
