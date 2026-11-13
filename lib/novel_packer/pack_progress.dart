import 'package:bili_novel_packer/light_novel/base/light_novel_model.dart';

class PackVolumeProgress {
  const PackVolumeProgress({
    required this.phase,
    this.chapter,
    this.imageUrl,
    this.error,
    this.path,
  });

  final PackVolumePhase phase;
  final Chapter? chapter;
  final String? imageUrl;
  final dynamic error;
  final String? path;

  PackVolumeProgress copyWith({
    PackVolumePhase? phase,
    Chapter? chapter,
    String? imageUrl,
    dynamic error,
  }) {
    return PackVolumeProgress(
      phase: phase ?? this.phase,
      chapter: chapter ?? this.chapter,
      imageUrl: imageUrl ?? this.imageUrl,
      error: error ?? this.error,
    );
  }
}

enum PackVolumePhase {
  start,
  resolvingChapter,
  resolvedChapter,
  resolvingImage,
  resolvedImage,
  error,
  completed,
}

class CombineVolumeProgress {
  const CombineVolumeProgress({
    required this.phase,
    this.volume,
    this.chapter,
    this.path,
  });

  final CombineVolumePhase phase;
  final Volume? volume;
  final Chapter? chapter;
  final String? path;

  CombineVolumeProgress copyWith({
    CombineVolumePhase? phase,
    Chapter? chapter,
    String? imageUrl,
    dynamic error,
  }) {
    return CombineVolumeProgress(
      phase: phase ?? this.phase,
      volume: volume ?? this.volume,
      chapter: chapter ?? this.chapter,
      path: path ?? this.path,
    );
  }
}

enum CombineVolumePhase {
  start,
  resolvingVolume,
  resolvedVolume,
  resolvingChapter,
  resolvedChapter,
  resolvingImage,
  resolvedImage,
  error,
  completed,
}
