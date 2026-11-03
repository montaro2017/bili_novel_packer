class PackSettings {
  // 添加标题
  final bool addTitle;

  // 分卷合并
  final bool combineVolume;

  // 繁简转换
  final ChineseConvert chineseConvert;

  PackSettings({
    this.addTitle = false,
    this.combineVolume = false,
    this.chineseConvert = .none,
  });

  @override
  String toString() {
    return 'addTitle = $addTitle, combineVolume = $combineVolume, chineseConvert = $chineseConvert';
  }
}

enum ChineseConvert {
  none,
  t2s,
  s2t,
}
