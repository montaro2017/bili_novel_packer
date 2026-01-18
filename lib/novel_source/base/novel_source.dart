import 'dart:typed_data';

import 'package:bili_novel_packer/novel_source/base/novel_model.dart';
import 'package:bili_novel_packer/novel_source/bili_novel/bili_novel_source.dart';
import 'package:bili_novel_packer/novel_source/wenku_novel/wenku_novel_source.dart';
import 'package:html/dom.dart';

abstract class NovelSource {
  static List<NovelSource> sources = [
    BiliNovelSource(),
    WenkuNovelSource(),
  ];

  String get name;

  String get userAgent;

  Future<List<NovelSection>> explore();

  SearchIterator<Novel> search(String keyword);

  Future<Novel> loadNovel(String id);

  Future<Catalog> loadCatalog(Novel novel);

  Future<Document> loadChapter(Catalog catalog, Chapter chapter);

  Future<Uint8List> loadImage(String src);
}

abstract class SearchIterator<E> {
  bool get hasNext;

  Future<List<E>> next();
}
