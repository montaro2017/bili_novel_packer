import 'dart:typed_data';

import 'package:bili_novel_packer/light_novel/base/light_novel_model.dart';
import 'package:bili_novel_packer/light_novel/bili_novel/bili_novel_source.dart';
import 'package:bili_novel_packer/light_novel/wenku_novel/wenku_novel_source.dart';
import 'package:html/dom.dart';

abstract class LightNovelSource {
  static const String html =
      "<html xmlns='http://www.w3.org/1999/xhtml' lang='zh-CN'><body></body></html>";

  static List<LightNovelSource Function()> sourceFactories = [
    () => BiliNovelSource(),
    () => WenkuNovelSource(),
  ];

  static LightNovelSource? detectSource(String url) {
    for (var createSource in sourceFactories) {
      final source = createSource();
      var (support, _) = source.supportUrl(url);
      if (support) {
        return source;
      }
    }
    return null;
  }

  String get name;

  String get sourceUrl;

  (bool, String?) supportUrl(String url);

  Future<Novel> getNovel(String url);

  Future<Catalog> getNovelCatalog(Novel novel);

  Future<Document> getNovelChapter(Chapter chapter);

  Future<Uint8List> getImage(String url);
}
