
import 'package:bili_novel_packer/light_novel/base/light_novel_source.dart';
import 'package:bili_novel_packer/light_novel/bili_novel/bili_novel_source.dart';
import 'package:bili_novel_packer/light_novel/wenku_novel/wenku_novel_source.dart';

const String version = "0.2.49";
const String gitUrl = "https://github.com/Montaro2017/bili_novel_packer";


final List<LightNovelSource> sources = [
  BiliNovelSource(),
  WenkuNovelSource(),
];
