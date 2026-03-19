import 'dart:async';
import 'dart:typed_data';

import 'package:bili_novel_packer/exception.dart';
import 'package:bili_novel_packer/extension/string_extension.dart';
import 'package:bili_novel_packer/novel_source/base/cloudflare_interceptor.dart';
import 'package:bili_novel_packer/novel_source/base/novel_model.dart';
import 'package:bili_novel_packer/novel_source/base/novel_source.dart';
import 'package:bili_novel_packer/novel_source/base/redirect_interceptor.dart';
import 'package:bili_novel_packer/novel_source/wenku_novel/wenku_interceptor.dart';
import 'package:bili_novel_packer/novel_source/wenku_novel/wenku_novel.dart';
import 'package:bili_novel_packer/scheduler/scheduler.dart';
import 'package:bili_novel_packer/util/html_util.dart';
import 'package:bili_novel_packer/util/sequence.dart';
import 'package:dio/dio.dart';
import 'package:gbk_codec/gbk_codec.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:retry/retry.dart';
import 'package:synchronized/synchronized.dart';

class WenkuNovelSource implements NovelSource {
  static final String domain = "https://www.wenku8.net";
  static final Lock lock = Lock();
  static final Scheduler _scheduler = Scheduler(20, Duration(minutes: 1));
  static final Dio dio = _dio();

  @override
  final String name = "轻小说文库";

  WenkuNovelSource._();

  static final WenkuNovelSource _instance = WenkuNovelSource._();

  static WenkuNovelSource get instance => _instance;

  static const String userAgent =
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36 Edg/143.0.0.0";

  static Dio _dio() {
    FutureOr<String?> gbkDecoder(responseBytes, options, responseBody) {
      return gbk_bytes.decode(responseBytes);
    }

    var headers = {
      "User-Agent": userAgent,
    };
    BaseOptions options = BaseOptions(
      headers: headers,
      responseType: ResponseType.plain,
      responseDecoder: gbkDecoder,
      validateStatus: (status) {
        if (status == null) return false;
        if (status >= 200 && status < 400) return true;
        if (status == 403) return true;
        return false;
      },
    );
    var dio = Dio(options);
    dio.interceptors.add(RedirectInterceptor(dio));
    dio.interceptors.add(CloudflareInterceptor(dio));
    dio.interceptors.add(WenkuInterceptor(dio));
    return dio;
  }

  @override
  Future<List<NovelSection>> explore() async {
    var html = (await dio.get(
      "https://www.wenku8.net/index.php",
    )).data.toString();
    var doc = parse(html);
    var blocks = doc.querySelectorAll("#centers .block");
    List<NovelSection> sections = [];

    Novel parseNovel(Element el) {
      var firstLink = el.querySelector("a")!;
      var href = firstLink.attributes["href"]!;
      var id = href.subBetween("/book/", ".htm")!;
      var title = firstLink.attributes["title"]!;
      var coverUrl = firstLink.querySelector("img")!.attributes["src"]!;
      var novel = Novel();
      novel.id = id;
      novel.title = title;
      novel.coverUrl = coverUrl;
      return novel;
    }

    for (var block in blocks) {
      var title = block.querySelector(".blocktitle")!.text;
      var books = block.querySelectorAll(".blockcontent > div > div");
      if (books.isEmpty) {
        continue;
      }
      var novels = books.map((book) => parseNovel(book)).toList();
      if (novels.isEmpty) {
        continue;
      }
      var section = NovelSection();
      section.name = title;
      section.novels = novels;
      sections.add(section);
    }
    return sections;
  }

  @override
  SearchIterator<Novel> search(String keyword) {
    throw NotRetryableException("轻小说文库仅支持直接搜索链接");
  }

  @override
  Future<Novel> loadNovel(String id) async {
    String url = "$domain/book/$id.htm";
    var resp = await dio.get(url);
    String html = resp.data.toString();
    return _parseNovel(id, url, html);
  }

  Novel _parseNovel(String id, String url, String html) {
    WenkuNovel novel = WenkuNovel();
    var doc = parse(html);
    novel.id = id.toString();
    novel.url = url;
    novel.title = doc
        .querySelector("#content")!
        .querySelector("table:nth-child(1)")!
        .querySelector("span b")!
        .text;
    novel.coverUrl = doc.querySelector("#content table img")?.attributes["src"];
    List<Element>? details = doc
        .querySelector("#content table:nth-child(1)")
        ?.querySelector("tr:nth-child(2)")
        ?.querySelectorAll("td");
    if (details != null && details.length >= 3) {
      novel.status = details[2].text.replaceFirst("文章状态：", "");
      novel.author = details[1].text.replaceFirst("小说作者：", "");
    }
    Element td = doc
        .querySelectorAll("#content table")[2]
        .querySelectorAll("td")[1];

    novel.tags = td
        .querySelector("span")!
        .text
        .replaceFirst("作品Tags：", "")
        .split(" ");
    novel.description = td.querySelectorAll("span").last.text;

    novel.catalogUrl = doc
        .querySelector("legend + div > a")!
        .attributes["href"]!;
    if (!novel.catalogUrl.startsWith("http")) {
      novel.catalogUrl =
          domain +
          (novel.catalogUrl.startsWith("/") ? "" : "/") +
          novel.catalogUrl;
    }
    return novel;
  }

  @override
  Future<Catalog> loadCatalog(Novel novel) async {
    String catalogUrl = (novel as WenkuNovel).catalogUrl;
    String prefix = Uri.parse(catalogUrl).resolve("./").toString();
    var resp = await dio.get(catalogUrl);
    String html = resp.data.toString();
    return _parseCatalog(html, prefix);
  }

  Catalog _parseCatalog(String html, String prefix) {
    Catalog catalog = Catalog();
    Sequence seq = Sequence();
    Volume? volume;

    var doc = parse(html);
    var tdList = doc.querySelectorAll("table td");
    for (var td in tdList) {
      var styleClass = td.attributes["class"];
      if (styleClass == "vcss") {
        if (volume != null) {
          catalog.volumes.add(volume);
        }
        volume = Volume(id: seq.next)..name = td.text;
      } else if (styleClass == "ccss") {
        var link = td.querySelector("a");
        if (link == null) continue;
        var href = link.attributes["href"];
        if (volume == null) continue;
        var chapter = Chapter(id: "$prefix/$href", name: link.text);
        // 将插图移动至最前面
        if (chapter.name == "插图") {
          volume.chapters.insert(0, chapter);
        } else {
          volume.chapters.add(chapter);
        }
      }
    }
    if (volume != null) {
      catalog.volumes.add(volume);
    }
    return catalog;
  }

  @override
  Future<Document> loadChapter(Catalog catalog, Chapter chapter) {
    return retry(
      () => _scheduler.run(
        (c) => _loadChapter(catalog, chapter, c),
      ),
      maxAttempts: 3,
      retryIf: (e) => true,
    );
  }

  Future<Document> _loadChapter(
    Catalog catalog,
    Chapter chapter,
    SchedulerController controller,
  ) async {
    String chapterUrl = chapter.id as String;
    var resp = await dio.get(chapterUrl);
    var html = resp.data.toString();
    var doc = parse(html);
    var content = doc.querySelector("#content");
    if (content == null) {
      throw "no such element: #content";
    }
    HTMLUtil.removeElements(content.querySelectorAll("#contentdp"));
    HTMLUtil.removeElements(content.querySelectorAll("br"));
    return _wrapDocument(content);
  }

  Document _wrapDocument(Element content) {
    Document doc = Document.html(NovelSource.html);
    var nodes = content.nodes;
    for (var node in nodes) {
      if (node is Text) {
        String text = node.data.trim();
        if (text.isEmpty) continue;
        var element = Element.tag("p")..text = text;
        doc.body!.append(element);
      } else {
        doc.body!.append(node.clone(true));
      }
    }
    var links = doc.querySelectorAll("a");
    for (var link in links) {
      HTMLUtil.unwrap(link);
    }
    return doc;
  }

  @override
  Future<Uint8List> loadImage(String src) async {
    var resp = await dio.get(
      src,
      options: Options(responseType: ResponseType.bytes),
    );
    return resp.data as Uint8List;
  }
}
