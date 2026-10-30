import 'package:bili_novel_packer/components/packer_app.dart';
import 'package:bili_novel_packer/light_novel/base/light_novel_model.dart';
import 'package:bili_novel_packer/light_novel/base/light_novel_source.dart';
import 'package:bili_novel_packer/light_novel/bili_novel/bili_novel_source.dart';
import 'package:bili_novel_packer/light_novel/wenku_novel/wenku_novel_source.dart';
import 'package:bili_novel_packer/novel_packer.dart';
import 'package:bili_novel_packer/pack_option.dart';
import 'package:nocterm/nocterm.dart';

const String gitUrl = "https://github.com/Montaro2017/bili_novel_packer";
const String version = "0.2.49";

List<LightNovelSource> sources = [
  BiliNovelSource(),
  WenkuNovelSource(),
];
void main() {
  runApp(
    TuiTheme(
      data: TuiThemeData.dark,
      child: Navigator(
        home: PackerApp(),
      ),
    ),
  );
}

Future<void> pack({
  required LightNovelSource source,
  required Novel novel,
  required PackOption option,
  required bool combineVolume,
}) async {
  if (combineVolume && option.selectedVolumes.length <= 1) {
    combineVolume = false;
  }
  var packer = NovelPacker(source);
  if (combineVolume) {
    await packer.packCombine(source: source, novel: novel, option: option);
  } else {
    for (var volume in option.selectedVolumes) {
      await packer.packVolume(source: source, volume: volume, option: option);
    }
  }
}
