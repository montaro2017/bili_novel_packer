
import 'package:bili_novel_packer/novel_source/bili_novel/bili_novel_source.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {

  test("BiliNovel loadCatalog", () async {
    WidgetsFlutterBinding.ensureInitialized();
    var source = BiliNovelSource.instance;
    var id = "4915";
    var novel = await source.loadNovel(id);
    var catalog = await source.loadCatalog(novel);
  });

}