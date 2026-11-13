class VolumeProgress {
  final VolumeProgressPhase phase;
  final int totalChapters;
  final int resolvedChapters;
  final String? chapterName;

  final int totalImages;
  final int resolvedImages;
  final String? imageUrl;

  final dynamic error;

  VolumeProgress({
    required this.phase,
    required this.totalChapters,
    required this.resolvedChapters,
    this.chapterName,
    required this.totalImages,
    required this.resolvedImages,
    this.imageUrl,
    this.error,
  });
}

enum VolumeProgressPhase {
  start,
  resolveChapter,
  resolveImage,
  resolveCover,
  error,
  complete,
}
