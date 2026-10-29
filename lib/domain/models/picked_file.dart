class PickedFile {
  const PickedFile({
    required this.path,
    required this.name,
    required this.sizeBytes,
    this.mimeType,
  });

  final String path;
  final String name;
  final int sizeBytes;
  final String? mimeType;
}
