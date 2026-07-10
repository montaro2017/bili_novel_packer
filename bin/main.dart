import 'dart:io';

import 'package:bili_novel_packer/light_novel/base/light_novel_model.dart';
import 'package:bili_novel_packer/logger.dart';
import 'package:bili_novel_packer/novel_packer.dart';
import 'package:bili_novel_packer/pack_argument.dart';
import 'package:console/console.dart';

const String gitUrl = "https://github.com/Montaro2017/bili_novel_packer";
const String version = "0.2.45";

void main(List<String> args) async {
  printWelcome();
  try {
    await start();
  } catch (e, stackTrace) {
    logger.e(e, stackTrace: stackTrace);
    print(e);
    print(stackTrace);
    print("运行出错，按回车键退出.($version)");
    Console.readLine();
  }
}

void printWelcome() {
  print("欢迎使用轻小说打包器!");
  print("作者: Spark");
  print("当前版本: $version");
  print("如遇报错请先查看能否正常访问输入网址");
  print("否则请至开源地址携带报错信息进行反馈: $gitUrl");
}

Future<void> start() async {
  var url = readUrl();
  logger.i("version: $version");
  logger.i("URL: $url");
  var packer = NovelPacker.fromUrl(url);
  print("正在加载数据...");
  await packer.init();
  logger.i(packer.novel);
  printNovelDetail(packer.novel);
  var arg = readPackArgument(packer.catalog);
  logger.i(arg);
  await packer.pack(arg);
  // 防止打包完成后直接退出 无法查看到结果
  print("全部任务已完成，按回车键退出.");
  Console.readLine();
  exit(0);
}

String readUrl() {
  String? url;
  do {
    print("请输入URL(支持哔哩轻小说&轻小说文库):");
    url = stdin.readLineSync();
  } while (url == null || url.isEmpty);
  url = url.split(" ")[0];
  return url;
}

void printNovelDetail(Novel novel) {
  Console.write("\n");
  Console.write(novel.toString());
}

PackArgument readPackArgument(Catalog catalog) {
  var arg = PackArgument();
  var select = readSelectVolume(catalog);
  arg.packVolumes = select;

  if (arg.packVolumes.length > 1) {
    Console.write("\n");
    arg.combineVolume =
        Chooser(["是", "否"], message: "是否合并选择的分卷为一个文件? ").chooseSync() == "是";
  }

  Console.write("\n");
  arg.addChapterTitle =
      Chooser(["是", "否"], message: "是否在每章开头添加章节标题? ").chooseSync() == "是";
  Console.write("\n");
  return arg;
}

List<Volume> readSelectVolume(Catalog catalog) {
  Console.write("\n");
  for (int i = 0; i < catalog.volumes.length; i++) {
    Console.write("[${i + 1}] ${catalog.volumes[i].volumeName}\n");
  }
  Console.write("---------------\n");
  Console.write("[0] 选择全部\n");
  Console.write(
    "请选择需要下载的分卷(可输入如1-9进行范围选择以及如2,5单独选择):",
  );
  var input = Console.readLine();
  List<Volume> selectVolumeIndex = [];

  if (input == null || input == "0" || input == "") {
    for (int i = 0; i < catalog.volumes.length; i++) {
      selectVolumeIndex.add(catalog.volumes[i]);
    }
    return selectVolumeIndex;
  }
  input = input.trim();
  input = input.replaceAll("，", ",");
  input = input.replaceAll(" ", ",");
  List<String> parts = input.split(",");
  for (var part in parts) {
    List<String> range = part.split("-");
    if (range.length == 1) {
      int index = int.parse(range[0]) - 1;
      selectVolumeIndex.add(catalog.volumes[index]);
    } else {
      int from = int.parse(range[0]);
      int to = int.parse(range[1]);
      if (from > to) {
        int tmp = from;
        from = to;
        to = tmp;
      }
      for (int i = from; i <= to; i++) {
        int index = i - 1;
        selectVolumeIndex.add(catalog.volumes[index]);
      }
    }
  }
  return selectVolumeIndex;
}
