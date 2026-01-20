import 'dart:typed_data';

import 'package:bili_novel_packer/novel_source/base/novel_model.dart';
import 'package:bili_novel_packer/novel_source/bili_novel/bili_novel_source.dart';
import 'package:bili_novel_packer/novel_source/wenku_novel/wenku_novel_source.dart';
import 'package:html/dom.dart';

abstract class NovelSource {
  static const String html =
      "<html xmlns='http://www.w3.org/1999/xhtml' lang='zh-CN'><body></body></html>";

  static List<NovelSource> sources = [
    BiliNovelSource.instance,
    WenkuNovelSource.instance,
  ];

  String get name;

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
