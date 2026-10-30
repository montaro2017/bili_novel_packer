import 'package:bili_novel_packer/light_novel/bili_novel/bili_novel_chapterlog.dart';
import 'package:html/parser.dart';
import 'package:test/test.dart';

const _script = '''
function restore(chapterId) {
  if (count > 20) {
    var seed = Number(chapterId) * 17 + 3;
    seed = (seed * 1103515245 + 12345) % 2147483648;
  }
}
''';

void main() {
  BiliChapterLogResolver resolver() => BiliChapterLogResolver(
    domain: 'https://example.invalid',
    loadScript: (_) async => _script,
  );

  test('supports the existing versioned script URL', () async {
    final document = parse('''
      <script>ReadParams={chapterid:'42'};</script>
      <script src="/scripts/chapterlog.js?v=known"></script>
    ''');
    expect(
      await resolver().getShuffleParams(document),
      containsPair('seed', 717),
    );
  });

  test('restores chapters when the script URL has no version query', () async {
    final document = parse('''
      <script>ReadParams={chapterid:'42'};</script>
      <script src="/scripts/chapterlog.js"></script>
    ''');
    expect(
      await resolver().getShuffleParams(document),
      containsPair('seed', 717),
    );
  });

  test('supports a different script query and URL fragment', () async {
    final document = parse('''
      <script>ReadParams={chapterid:'42'};</script>
      <script src="/scripts/chapterlog.js?revision=current#restore"></script>
    ''');
    expect(
      await resolver().getShuffleParams(document),
      containsPair('seed', 717),
    );
  });

  test('supports whitespace and double quotes around the chapter ID', () async {
    final document = parse('''
      <script>ReadParams = { chapterid : "42" };</script>
      <script src="/scripts/chapterlog.js?v=known"></script>
    ''');
    expect(
      await resolver().getShuffleParams(document),
      containsPair('seed', 717),
    );
  });

  test('supports quoted chapter ID property names', () async {
    final document = parse('''
      <script>ReadParams = { "chapterid" : "42" };</script>
      <script src="/scripts/chapterlog.js?v=known"></script>
    ''');
    expect(
      await resolver().getShuffleParams(document),
      containsPair('seed', 717),
    );
  });

  test(
    'rejects missing chapter IDs instead of returning scrambled text',
    () async {
      final document = parse('''
      <script>ReadParams={chaptername:'sample'};</script>
      <script src="/scripts/chapterlog.js?v=known"></script>
      <div id="acontent"><p>Example paragraph</p></div>
    ''');
      await expectLater(
        resolver().getShuffleParams(document),
        throwsFormatException,
      );
    },
  );

  test('allows short pages without a restore script', () async {
    final document = parse('<div id="acontent"><p>Short page</p></div>');
    expect(await resolver().getShuffleParams(document), isNull);
  });

  test(
    'ignores unrelated scripts with chapterlog in a directory name',
    () async {
      final document = parse('''
      <script src="/chapterlog.js/assets/reader.js"></script>
      <div id="acontent"><p>Short page</p></div>
    ''');
      expect(await resolver().getShuffleParams(document), isNull);
    },
  );
}
