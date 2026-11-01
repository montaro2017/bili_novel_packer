import 'package:bili_novel_packer/light_novel/base/light_novel_model.dart';

class PackSettings {
  // 选择要打包的分卷
  final List<Volume> selectedVolumes;

  // 添加标题
  final bool addChapterTitle;

  // 分卷合并
  final bool combineVolume;

  PackSettings({
    this.addChapterTitle = false,
    this.combineVolume = false,
    required this.selectedVolumes,
  });

  @override
  String toString() {
    return 'addChapterTitle = $addChapterTitle, selectedVolumes = $selectedVolumes';
  }
}

enum ChineseConvert {
  none,
  t2s,
  s2t,
}
