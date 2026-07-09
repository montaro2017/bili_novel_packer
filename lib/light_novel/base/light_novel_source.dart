import 'dart:typed_data';

import 'package:bili_novel_packer/light_novel/base/light_novel_model.dart';
import 'package:html/dom.dart';

abstract class LightNovelSource {
  static const String html =
      "<html xmlns='http://www.w3.org/1999/xhtml' lang='zh-CN'><body></body></html>";

  String get name;

  String get sourceUrl;

  bool supportUrl(String url);

  Future<Novel> getNovel(String url);

  Future<Catalog> getNovelCatalog(Novel novel);

  Future<Document> getNovelChapter(Chapter chapter);

  Future<Uint8List> getImage(String src);
}
