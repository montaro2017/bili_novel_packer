import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:bili_novel_packer/assets/assets.dart';
import 'package:bili_novel_packer/epub_packer/epub_navigator_ncx.dart';
import 'package:bili_novel_packer/epub_packer/epub_packer.dart';
import 'package:bili_novel_packer/light_novel/base/light_novel_cover_detector.dart';
import 'package:bili_novel_packer/light_novel/base/light_novel_model.dart';
import 'package:bili_novel_packer/light_novel/base/light_novel_source.dart';
import 'package:bili_novel_packer/light_novel/bili_novel/bili_novel_source.dart';
import 'package:bili_novel_packer/light_novel/wenku_novel/wenku_novel_source.dart';
import 'package:bili_novel_packer/logger.dart';
import 'package:bili_novel_packer/pack_argument.dart';
import 'package:bili_novel_packer/util/html_util.dart';
import 'package:bili_novel_packer/util/sequence.dart';
import 'package:bili_novel_packer/util/volume_util.dart';
import 'package:console/console.dart';
import 'package:html/dom.dart';

class NovelPacker {
  static final List<LightNovelSource> sources = [
    BiliNovelSource(),
    WenkuNovelSource(),
  ];

  String url;
  LightNovelSource lightNovelSource;

  final Sequence _imageSequence = Sequence();
  final Sequence _chapterSequence = Sequence();

  late Novel novel;
  late Catalog catalog;

  NovelPacker._(this.lightNovelSource, this.url);

  factory NovelPacker.fromUrl(String url) {
    for (var source in sources) {
      if (source.supportUrl(url)) {
        return NovelPacker._(source, url);
      }
    }
    throw "Unsupported url: $url";
  }

  Future<Novel> init({
    Function(Novel novel)? novelCallback,
    Function(Catalog catalog)? catalogCallback,
  }) async {
    novel = await getNovel();
    novelCallback?.call(novel);
    catalog = await getCatalog();
    catalogCallback?.call(catalog);
    return novel;
  }

  Future<Novel> getNovel() async {
    return lightNovelSource.getNovel(url).then((novel) => this.novel = novel);
  }

  Future<Catalog> getCatalog() async {
    return lightNovelSource
        .getNovelCatalog(novel)
        .then((catalog) => this.catalog = catalog);
  }

  Future<void> pack(PackArgument arg) async {
    if (!arg.combineVolume) {
      for (var volume in arg.packVolumes) {
        logger.i("开始打包 ${volume.catalog.novel.title} ${volume.volumeName}");
        _imageSequence.reset();
        _chapterSequence.reset();
        await _packVolume(volume, arg.addChapterTitle);
        logger.i("打包完成 ${volume.catalog.novel.title} ${volume.volumeName}");
      }
    } else {
      // 合并分卷
      String title = _sanitizeFileName(novel.title);
      String path = "$title${Platform.pathSeparator}$title.epub";
      logger.i("EPUB file: $path");
      await _combineVolume(path, arg);
    }
  }

  Future<void> _combineVolume(
    String path,
    PackArgument arg,
  ) async {
    EpubPacker packer = EpubPacker(path);
    packer.docTitle = novel.title;
    packer.creator = novel.author;
    packer.source = novel.url;
    packer.publisher = novel.publisher;
    packer.subjects = novel.tags ?? [];
    packer.description = novel.description;
    // 封面使用小说封面
    Uint8List coverData = novel.coverUrl == null
        ? Uint8List(0)
        : await _getSingleImage(novel.coverUrl!);
    String coverName =
        "images/${_imageSequence.next.toString().padLeft(6, '0')}.jpg";
    packer.addImage(name: "OEBPS/$coverName", data: coverData);
    packer.cover = coverName;

    if (arg.addChapterTitle) {
      packer.addStylesheet(styleCss());
    }

    for (Volume volume in arg.packVolumes) {
      logger.i("开始处理: ${volume.volumeName}");
      Console.write("正在处理: ${volume.volumeName}\n");
      NavPoint volumeNavPoint = NavPoint(volume.volumeName);
      List<Future<Document>> futures = volume.chapters
          .map(
            (chapter) => _resolveChapter(chapter, packer, arg.addChapterTitle),
          )
          .toList();

      List<Document> chapterDocuments = await Future.wait(futures);
      for (int i = 0; i < chapterDocuments.length; i++) {
        Chapter chapter = volume.chapters[i];
        Document document = chapterDocuments[i];
        _addTitle(document, chapter.chapterName);
        String html = _closeTag(document);
        html = _appendXmlDeclare(html);
        String name =
            "chapter${_chapterSequence.next.toString().padLeft(6, "0")}.xhtml";
        packer.addChapter(
          addNavPoint: false,
          name: "OEBPS/$name",
          title: chapter.chapterName,
          chapterContent: html,
        );
        NavPoint chapterNavPoint = NavPoint(chapter.chapterName, src: name);
        volumeNavPoint.addChild(chapterNavPoint);
        if (i == 0) {
          volumeNavPoint.src = name;
        }
      }
      packer.addNavPoint(volumeNavPoint);
      logger.i("处理完成: ${volume.volumeName}");
    }
    packer.pack();
    Console.write("打包完成: ${packer.absolutePath}\n");
  }

  Future<Document> _resolveChapter(
    Chapter chapter,
    EpubPacker packer,
    bool addChapterTitle, [
    LightNovelCoverDetector? detector,
  ]) async {
    Document doc = await lightNovelSource.getNovelChapter(chapter);
    // 处理图片资源
    await _resolveImages(doc, packer, detector);

    // 添加章节标题
    if (addChapterTitle) {
      doc.head!.append(
        Element.html(
          '<link rel="stylesheet" type="text/css" href="styles/style.css">',
        ),
      );
      var firstChild = doc.body!.firstChild;
      Node chapterTitle = Element.html(
        '<div class="chapter-title">${chapter.chapterName}</div>',
      );
      doc.body!.insertBefore(chapterTitle, firstChild);
    }
    logger.i("OK ${chapter.volume.volumeName} ${chapter.chapterName}");
    return doc;
  }

  Future<Uint8List> _getSingleImage(String src) async {
    try {
      return await lightNovelSource.getImage(src);
    } catch (e) {
      print("$src 图片下载失败: $e");
      return Uint8List(0);
    }
  }

  Future<void> _packVolume(
    Volume volume,
    bool addChapterTitle,
  ) async {
    Console.write("开始打包 ${volume.volumeName}...\n");
    EpubPacker packer = EpubPacker(_getEpubName(volume));
    packer.docTitle = "${volume.catalog.novel.title} ${volume.volumeName}";
    if (volume.volumeName.startsWith(volume.catalog.novel.title)) {
      packer.docTitle = volume.volumeName;
    }
    packer.creator = volume.catalog.novel.author;
    packer.source = novel.url;
    packer.publisher = novel.publisher;
    packer.subjects = novel.tags ?? [];
    packer.description = novel.description;
    // 当识别出丛书编号时才设置丛书名 否则丛书编号会被当成1
    packer.calibreSeriesIndex = VolumeUtil.getSeriesIndex(volume.volumeName);
    if (packer.calibreSeriesIndex != null) {
      packer.calibreSeries = volume.catalog.novel.title;
    }

    LightNovelCoverDetector detector = LightNovelCoverDetector();

    if (addChapterTitle) {
      packer.addStylesheet(styleCss());
    }

    List<Future<Document>> futures = volume.chapters
        .map(
          (chapter) =>
              _resolveChapter(chapter, packer, addChapterTitle, detector),
        )
        .toList();

    List<Document> chapterDocuments = await Future.wait(futures);

    // 添加章节资源
    for (int i = 0; i < chapterDocuments.length; i++) {
      var chapter = volume.chapters[i];
      var document = chapterDocuments[i];
      _addTitle(document, chapter.chapterName);
      String html = _closeTag(document);
      html = _appendXmlDeclare(html);
      packer.addChapter(
        name:
            "OEBPS/chapter${_chapterSequence.next.toString().padLeft(6, "0")}.xhtml",
        title: chapter.chapterName,
        chapterContent: html,
      );
    }

    // 设置封面
    await _resolveCover(volume, packer, detector);
    // 写出目标文件
    packer.pack();
    logger.i("EPUB file: ${packer.absolutePath}");
    Console.write("打包完成: ${packer.absolutePath}\n\n");
  }

  Future<void> _resolveImages(
    Document doc,
    EpubPacker packer,
    LightNovelCoverDetector? detector,
  ) async {
    // 下载图片 添加到epub中
    List<Element> imgList = doc.querySelectorAll("img");
    List<Future<Pair<Element, Uint8List>?>> futures = [];
    for (var img in imgList) {
      futures.add(_resolveSingleImage(img, packer, detector));
    }
    List<Pair<Element, Uint8List>?> pairList = await Future.wait(futures);
    for (Pair<Element, Uint8List>? pair in pairList) {
      if (pair == null) continue;
      Element img = pair.v1;
      Uint8List imageData = pair.v2;
      String name = "${_imageSequence.next.toString().padLeft(6, '0')}.jpg";
      String relativeSrc = "images/$name";
      packer.addImage(name: "OEBPS/$relativeSrc", data: imageData);
      String? src = img.attributes["src"];
      img.attributes["src"] = relativeSrc;
      try {
        detector?.add("OEBPS/$relativeSrc", imageData);
      } on UnsupportedImageException catch (e) {
        print("$src ${e.message}");
      }
    }

    HTMLUtil.wrapDuoKanImage(doc.body!);
  }

  Future<Pair<Element, Uint8List>?> _resolveSingleImage(
    Element img,
    EpubPacker packer,
    LightNovelCoverDetector? detector,
  ) async {
    String? src = img.attributes["src"];
    if (src == null || src.isEmpty) {
      return null;
    }
    Uint8List imageData = await _getSingleImage(src);
    if (imageData.isEmpty) {
      print("$src 图片下载失败");
      return null;
    }
    return Pair(img, imageData);
  }

  Future<void> _resolveCover(
    Volume volume,
    EpubPacker packer,
    LightNovelCoverDetector coverDetector,
  ) async {
    // 优先使用目录中的封面 否则自动检测
    if (volume.cover != null) {
      Uint8List coverData = await _getSingleImage(volume.cover!);
      if (coverData.isEmpty) {
        print("封面下载失败");
        return;
      }
      String coverName =
          "images/${_imageSequence.next.toString().padLeft(6, '0')}.jpg";
      packer.addImage(name: "OEBPS/$coverName", data: coverData);
      packer.cover = coverName;
    } else {
      String? cover = coverDetector.detectCover();
      if (cover != null) {
        packer.cover = cover.replaceFirst("OEBPS/", "");
      }
    }
  }

  String _getEpubName(Volume volume) {
    String title = _sanitizeFileName(volume.catalog.novel.title);
    String volumeName = _sanitizeFileName(volume.volumeName);
    if (volumeName == "") {
      return "$title${Platform.pathSeparator}$title.epub";
    }
    if (volumeName.startsWith(title)) {
      return "$title${Platform.pathSeparator}$volumeName.epub";
    }
    return "$title${Platform.pathSeparator}$title $volumeName.epub";
  }

  String _sanitizeFileName(String name) {
    var keywords = {":", "*", "?", "\"", "\\", "/", "<", ">", "|", "\\0", "　"};
    for (var keyword in keywords) {
      name = name.replaceAll(keyword, " ");
    }
    if (name.startsWith(".")) {
      name = name.substring(1);
    }
    if (name.endsWith(".")) {
      name = name.substring(0, name.length - 1);
    }
    // 替换连续空格为一个空格
    name = name.replaceAllMapped(RegExp("\\s+"), (_) => " ");
    return name.trim();
  }

  // 添加title元素
  void _addTitle(Document document, String title) {
    var element = document.createElement("title");
    element.text = title;
    document.head?.append(element);
  }

  /// 将标签闭合
  String _closeTag(Document document) {
    String html = document.outerHtml;
    RegExp regExp = RegExp("(<(?:img|link).*?)>");
    Iterable<RegExpMatch> matches = regExp.allMatches(html);
    for (var match in matches) {
      String img = match.group(0)!;
      if (!img.endsWith("/>")) {
        String newImg = "${match.group(1)!}/>";
        html = html.replaceAll(img, newImg);
      }
    }
    return html;
  }

  String _appendXmlDeclare(String html) {
    String xmlDeclare = """<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html>
""";
    return xmlDeclare + html;
  }
}

class Pair<V1, V2> {
  V1 v1;
  V2 v2;

  Pair(this.v1, this.v2);
}
