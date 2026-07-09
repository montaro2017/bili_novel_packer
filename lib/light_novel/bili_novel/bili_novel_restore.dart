import 'package:html/dom.dart';

/// 还原 Bilinovel 的 chapterlog.js 打乱过的段落顺序。
///
/// 原脚本只会移动有效且非空的直接 `<p>` 节点。其它子节点会保持原位置，
/// 相当于正文段落槽位之间的固定分隔物。
class BiliNovelRestore {
  static const String _fixedLengthKey = 'fixedLength';
  static const String _seedKey = 'seed';
  static const String _multiplierKey = 'a';
  static const String _incrementKey = 'c';
  static const String _modulusKey = 'mod';

  const BiliNovelRestore._();

  /// 使用从 chapterlog.js 解析出的参数还原 [content]。
  static void restore(Element content, Map<String, int> shuffleParams) {
    _restoreWithParams(content, _BiliNovelRestoreParams.fromMap(shuffleParams));
  }

  /// 还原 [content] 中被打乱的正文段落。
  ///
  /// 这里按反混淆后的 chapterlog.js 逻辑处理：
  /// 1. 保存完整的 `content.nodes`。
  /// 2. 只收集有效正文段落，并记录它们在完整子节点列表里的槽位。
  /// 3. 还原正文段落顺序。
  /// 4. 把还原后的正文段落放回这些槽位。
  static void _restoreWithParams(
    Element content,
    _BiliNovelRestoreParams params,
  ) {
    List<Node> childNodes = content.nodes.toList();
    List<int> paragraphSlots = <int>[];
    List<Element> paragraphs = <Element>[];

    // paragraphSlots 使用完整 childNodes 索引，paragraphs 使用压缩后的正文段落索引。
    // 非正文段落不会进入 paragraphs，因此不会移动。
    for (int i = 0; i < childNodes.length; i++) {
      Node node = childNodes[i];
      if (_isShuffleParagraph(node)) {
        paragraphSlots.add(i);
        paragraphs.add(node as Element);
      }
    }

    if (paragraphs.isEmpty) {
      return;
    }

    List<Element> restoredParagraphs = _restoreParagraphs(paragraphs, params);
    for (int i = 0; i < paragraphSlots.length; i++) {
      childNodes[paragraphSlots[i]] = restoredParagraphs[i];
    }

    // 只替换正文段落槽位后，重建完整子节点列表。
    content.nodes.clear();
    content.nodes.addAll(childNodes);
  }

  /// 返回已恢复顺序的正文段落。
  ///
  /// `indices[i]` 表示当前段落 `paragraphs[i]` 应该放到恢复后的第 `indices[i]`
  /// 个正文段落槽位。
  static List<Element> _restoreParagraphs(
    List<Element> paragraphs,
    _BiliNovelRestoreParams params,
  ) {
    List<int> indices = _buildRestoreIndices(paragraphs.length, params);
    List<Element> restored = List<Element>.from(paragraphs);
    for (int i = 0; i < paragraphs.length; i++) {
      restored[indices[i]] = paragraphs[i];
    }

    return restored;
  }

  /// 对齐 chapterlog.js 中用于收集正文段落的过滤条件。
  static bool _isShuffleParagraph(Node node) {
    return node is Element &&
        node.localName == 'p' &&
        node.innerHtml.replaceAll(RegExp(r'\s+'), '').isNotEmpty;
  }

  /// 生成正文段落槽位的还原索引。
  ///
  /// 前 [_BiliNovelRestoreParams.fixedLength] 个段落固定不动，后续段落使用
  /// chapterlog.js 中的确定性 LCG 洗牌。
  static List<int> _buildRestoreIndices(
    int paragraphCount,
    _BiliNovelRestoreParams params,
  ) {
    if (paragraphCount <= 0) {
      return const [];
    }

    List<int> fixed = <int>[];
    List<int> shuffled = <int>[];
    for (int i = 0; i < paragraphCount; i++) {
      if (i < params.fixedLength) {
        fixed.add(i);
      } else {
        shuffled.add(i);
      }
    }

    if (paragraphCount > params.fixedLength) {
      _shuffleIndices(shuffled, params);
      return <int>[...fixed, ...shuffled];
    }

    return fixed;
  }

  /// 使用 chapterlog.js 的线性同余随机数驱动 Fisher-Yates 洗牌。
  static List<int> _shuffleIndices(
    List<int> indices,
    _BiliNovelRestoreParams params,
  ) {
    int seed = params.seed;
    for (int i = indices.length - 1; i > 0; i--) {
      seed = (seed * params.multiplier + params.increment) % params.modulus;
      int j = (seed / params.modulus * (i + 1)).floor();
      int tmp = indices[i];
      indices[i] = indices[j];
      indices[j] = tmp;
    }
    return indices;
  }
}

/// 从 chapterlog.js 解析出的洗牌参数。
class _BiliNovelRestoreParams {
  final int fixedLength;
  final int seed;
  final int multiplier;
  final int increment;
  final int modulus;

  const _BiliNovelRestoreParams({
    required this.fixedLength,
    required this.seed,
    required this.multiplier,
    required this.increment,
    required this.modulus,
  });

  factory _BiliNovelRestoreParams.fromMap(Map<String, int> map) {
    return _BiliNovelRestoreParams(
      fixedLength: map[BiliNovelRestore._fixedLengthKey]!,
      seed: map[BiliNovelRestore._seedKey]!,
      multiplier: map[BiliNovelRestore._multiplierKey]!,
      increment: map[BiliNovelRestore._incrementKey]!,
      modulus: map[BiliNovelRestore._modulusKey]!,
    );
  }
}
