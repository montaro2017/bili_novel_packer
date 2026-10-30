import 'dart:typed_data';

import 'package:bili_novel_packer/components/novel_item.dart';
import 'package:bili_novel_packer/components/packer_app.dart';
import 'package:bili_novel_packer/light_novel/base/light_novel_model.dart';
import 'package:bili_novel_packer/light_novel/base/light_novel_source.dart';
import 'package:html/dom.dart';
import 'package:nocterm/nocterm.dart' hide isEmpty;
import 'package:test/test.dart';

const _title = '某科学的超电磁炮外传之某自动贩卖机的存在证明与御坂美琴的奇妙冒险故事集';
const _url =
    'https://example.com/novel/1234567890/very/long/path/segment/index.html';
const _failure =
    'DioException [connection error]: The socket connection was closed '
    'unexpectedly while receiving data from the remote host. uri=$_url';

const _width = 60;

class _FakeSource extends LightNovelSource {
  _FakeSource({this.fail = false});

  final bool fail;

  @override
  String get name => 'fake';

  @override
  String get sourceUrl => 'https://example.com';

  @override
  bool supportUrl(String url) => true;

  @override
  Future<Novel> getNovel(String url) async {
    if (fail) throw _failure;
    return Novel()
      ..id = '1'
      ..title = _title
      ..author = 'author'
      ..status = 'status';
  }

  @override
  Future<Catalog> getNovelCatalog(Novel novel) async {
    final catalog = Catalog(novel);
    catalog.volumes.add(Volume('volume', catalog));
    return catalog;
  }

  @override
  Future<Document> getNovelChapter(Chapter chapter) async => Document.html('');

  @override
  Future<Uint8List> getImage(String url) async => Uint8List(0);
}

Future<String> _render(NoctermTester tester, {required bool fail}) async {
  await tester.pumpComponent(
    SizedBox(
      width: _width.toDouble(),
      child: NovelItem(
        link: NovelLink(_url, _FakeSource(fail: fail)),
        mode: WorkMode.auto,
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 100));
  return tester.renderToString(showBorders: false);
}

void main() {
  test('long title, url and error wrap inside the item width', () async {
    final tester = await NoctermTester.create(
      size: Size(_width.toDouble(), 24),
    );

    var rendered = await _render(tester, fail: false);
    expect(rendered.split('\n').every((line) => line.length <= _width), isTrue);
    expect(rendered, contains('某科学的超电磁炮外传'));
    expect(rendered, contains('index.html)'));

    rendered = await _render(tester, fail: true);
    expect(rendered.split('\n').every((line) => line.length <= _width), isTrue);
    expect(rendered, contains('remote host.'));
    expect(rendered, contains('index.html'));
  });
}
