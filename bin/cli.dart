import 'package:bili_novel_packer/console/console.dart';
import 'package:bili_novel_packer/console/prompt.dart';
import 'package:bili_novel_packer/console/selector.dart';
import 'package:bili_novel_packer/const.dart';
import 'package:bili_novel_packer/light_novel/base/light_novel_model.dart';
import 'package:bili_novel_packer/light_novel/base/light_novel_source.dart';
import 'package:bili_novel_packer/light_novel/bili_novel/bili_novel_source.dart';
import 'package:bili_novel_packer/light_novel/wenku_novel/wenku_novel_source.dart';
import 'package:bili_novel_packer/logger.dart';
import 'package:bili_novel_packer/novel_packer.dart';
import 'package:bili_novel_packer/pack_settings.dart';

List<LightNovelSource> sources = [
  BiliNovelSource(),
  WenkuNovelSource(),
];

void main(List<String> args) async {
  printWelcome();
  do {
    try {
      await start();
    } catch (e, stackTrace) {
      logger.e(e, stackTrace: stackTrace);
      console.writeLine(e);
      console.writeLine(stackTrace);
      console.writeLine("运行出错.($version)");
      console.writeLine();
    }
  } while (true);
}

void printWelcome() {
  logger.i("version: $version");
  console.writeLine("欢迎使用轻小说打包器!");
  console.writeLine("作者: Spark");
  console.writeLine("当前版本: $version");
  console.writeLine("如遇报错请先查看能否正常访问输入网址");
  console.writeLine("否则请至开源地址携带报错信息进行反馈: $gitUrl");
}

Future<void> start() async {
  var pairs = readUrlSource();
  if (pairs.length == 1) {
    var (url, source) = pairs.first;
    await runOne(url, source, true);
  } else {
    await runMany(pairs);
  }
}

Future<void> runOne(String url, LightNovelSource source, bool manual) async {
  logger.i("URL: $url");

  console.writeLine("正在加载数据...");
  var novel = await source.getNovel(url);
  logger.i(novel);
  printNovelDetail(novel);
  var catalog = await source.getNovelCatalog(novel);
  List<Volume> volumes;
  PackSettings settings;
  if (manual) {
    (volumes, settings) = readPackOption(catalog);
  } else {
    volumes = catalog.volumes;
    settings = PackSettings(
      addTitle: false,
      combineVolume: false,
    );
  }
  logger.i("settings: $settings");
  await pack(
    source: source,
    novel: novel,
    volumes: volumes,
    settings: settings,
  );
}

Future<void> runMany(List<(String, LightNovelSource)> pairs) async {
  var continuousMode = "连续模式: 无需手动介入，所有选项使用默认";
  var manualMode = "手动模式：每次需手动介入，需手动选择选项";
  var manual =
      Selector(
        options: [continuousMode, manualMode],
        prefix: "\n",
        message: '检测到多个链接，请选择工作模式：',
        defaultValue: continuousMode,
      ).selectOne() ==
      manualMode;
  for (var (url, source) in pairs) {
    await runOne(url, source, manual);
  }
}

List<(String, LightNovelSource)> readUrlSource() {
  do {
    console.writeLine("请输入链接(多个链接使用空格隔开):");
    var input = console.readLine();
    if (input == null || input.trim() == "") {
      continue;
    }
    input = input.trim();
    var inputs = input.split(RegExp("\\s+"));
    var pairs = <(String, LightNovelSource)>[];
    var err = false;
    for (var url in inputs) {
      url = url.trim();
      if (url.isEmpty) continue;
      var s = detectSource(url);
      if (s == null) {
        console.writeLine("不支持的URL: $url\n");
        err = true;
        break;
      } else {
        pairs.add((url, s));
      }
    }
    if (!err) return pairs;
  } while (true);
}

LightNovelSource? detectSource(String url) {
  for (var source in sources) {
    if (source.supportUrl(url)) {
      return source;
    }
  }
  return null;
}

void printNovelDetail(Novel novel) {
  console.writeLine();
  console.write(novel.toString());
  console.writeLine();
}

(List<Volume>, PackSettings) readPackOption(Catalog catalog) {
  var combineVolume = false;
  var selectedVolumes = Selector(
    options: catalog.volumes,
    message: "请选择要下载的分卷: ",
    suffix: "选择全部\n",
  ).selectMany();

  if (selectedVolumes.length > 1) {
    console.writeLine();
    combineVolume = Prompt(
      "是否合并选择的分卷为一个文件? ",
      defaultValue: false,
    ).prompt();
  }

  console.writeLine();

  var addChapterTitle = Prompt(
    "是否在每章开头添加章节标题? ",
    defaultValue: false,
  ).prompt();
  console.writeLine();
  var settings = PackSettings(
    addTitle: addChapterTitle,
    combineVolume: combineVolume,
  );
  return (selectedVolumes, settings);
}

Future<void> pack({
  required LightNovelSource source,
  required Novel novel,
  required List<Volume> volumes,
  required PackSettings settings,
}) async {
  var packer = NovelPacker(source);
  if (settings.combineVolume) {
    await packer.packCombine(
      source: source,
      novel: novel,
      volumes: volumes,
      option: settings,
    );
  } else {
    for (var volume in volumes) {
      await packer.packVolume(source: source, volume: volume, option: settings);
    }
  }
}
