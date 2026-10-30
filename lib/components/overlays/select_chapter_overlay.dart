import 'dart:math' as math;

import 'package:bili_novel_packer/colors.dart';
import 'package:bili_novel_packer/light_novel/base/light_novel_model.dart';
import 'package:nocterm/nocterm.dart';
// nocterm 尚未公开导出文字宽度工具，使用与其渲染器相同的计算方式。
// ignore: implementation_imports
import 'package:nocterm/src/utils/unicode_width.dart';

class SelectChapterOverlay extends StatefulComponent {
  const SelectChapterOverlay({
    required this.catalog,
    this.onConfirm,
    this.onCancel,
  });

  final Catalog catalog;
  final void Function(List<Volume> selectedVolume)? onConfirm;
  final void Function()? onCancel;

  @override
  State<StatefulComponent> createState() => _SelectChapterOverlayState();
}

class _SelectChapterOverlayState extends State<SelectChapterOverlay> {
  int hoverIndex = 0;
  Map<int, bool> selectedMap = {};
  final ScrollController scrollController = ScrollController();

  List<Volume> get volumes => component.catalog.volumes;

  List<Volume> get selectedVolumes {
    List<Volume> selectedVolumes = [];
    for (var e in selectedMap.entries) {
      if (e.value) {
        selectedVolumes.add(volumes[e.key]);
      }
    }
    return selectedVolumes;
  }

  double get _listWidth {
    var width = 4;
    for (final volume in volumes) {
      for (final line in volume.volumeName.split('\n')) {
        // 三格选择标记 + 一格间距。
        width = math.max(width, 4 + UnicodeWidth.stringWidth(line));
      }
    }
    return width.toDouble();
  }

  TextSpan _buildHelpText(int selectedCount) => TextSpan(
    children: [
      TextSpan(
        text: "↑/↓: ",
        style: TextStyle(color: mutedColor),
      ),
      TextSpan(text: "导航 "),
      TextSpan(
        text: "←/→: ",
        style: TextStyle(color: mutedColor),
      ),
      TextSpan(text: "翻页 "),
      TextSpan(
        text: "Space: ",
        style: TextStyle(color: mutedColor),
      ),
      TextSpan(text: "选择 "),
      TextSpan(
        text: "A: ",
        style: TextStyle(color: mutedColor),
      ),
      TextSpan(text: "切换 "),
      TextSpan(
        text: "Enter: ",
        style: TextStyle(color: mutedColor),
      ),
      TextSpan(text: "确认 "),
      TextSpan(
        text: "Esc: ",
        style: TextStyle(color: mutedColor),
      ),
      TextSpan(text: "取消"),
    ],
  );

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < volumes.length; i++) {
      selectedMap[i] = false;
    }
  }

  @override
  void dispose() {
    super.dispose();
    scrollController.dispose();
  }

  @override
  Component build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(1),
      constraints: BoxConstraints.expand(),
      decoration: BoxDecoration(border: BoxBorder.all()),
      child: Focusable(
        focused: true,
        onKeyEvent: _onKeyEvent,
        child: Column(
          crossAxisAlignment: .center,
          children: [
            Text("选择分卷", style: TextStyle()),
            SizedBox(height: 1),
            // 分卷列表
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: _listWidth,
                  child: ListView.builder(
                    controller: scrollController,
                    itemExtent: 1,
                    itemCount: volumes.length,
                    itemBuilder: (context, index) {
                      return _buildItem(
                        volumes[index],
                        index,
                        hoverIndex == index,
                        selectedMap[index] ?? false,
                      );
                    },
                  ),
                ),
              ),
            ),
            SizedBox(height: 1),
            Row(
              mainAxisAlignment: .center,
              children: [
                Text("已选: "),
                Text(
                  "${selectedVolumes.length}/${volumes.length}",
                  style: TextStyle(color: mutedColor),
                ),
              ],
            ),
            SizedBox(height: 1),
            RichText(text: _buildHelpText(selectedVolumes.length)),
          ],
        ),
      ),
    );
  }

  bool _onKeyEvent(KeyboardEvent event) {
    if (event.logicalKey == LogicalKey.keyA) {
      _toggleAll();
      return true;
    }
    if (event.logicalKey == LogicalKey.space) {
      _selectHover();
      return true;
    }
    if (event.logicalKey == LogicalKey.arrowDown ||
        event.logicalKey == LogicalKey.digit2) {
      _hoverDown();
      return true;
    }
    if (event.logicalKey == LogicalKey.arrowUp ||
        event.logicalKey == LogicalKey.digit8) {
      _hoverUp();
      return true;
    }
    if (event.logicalKey == LogicalKey.arrowLeft ||
        event.logicalKey == LogicalKey.digit4 ||
        event.logicalKey == LogicalKey.pageUp) {
      _pageUp();
      return true;
    }
    if (event.logicalKey == LogicalKey.arrowRight ||
        event.logicalKey == LogicalKey.digit6 ||
        event.logicalKey == LogicalKey.pageDown) {
      _pageDown();
      return true;
    }
    if (event.logicalKey == LogicalKey.enter) {
      if (selectedVolumes.isNotEmpty) {
        component.onConfirm?.call(selectedVolumes);
      }
      return true;
    }
    if (event.logicalKey == LogicalKey.escape) {
      component.onCancel?.call();
    }
    return false;
  }

  void _hoverDown() {
    if (volumes.isEmpty) return;
    int index = hoverIndex + 1;
    if (index >= volumes.length) {
      index = 0;
    }
    setState(() {
      scrollController.ensureIndexVisible(index: index);
      hoverIndex = index;
    });
  }

  void _pageDown() => _scrollPage(1);

  void _pageUp() => _scrollPage(-1);

  void _scrollPage(int direction) {
    if (volumes.isEmpty) return;
    // 每个分卷占一行，一页以布局后的实际视口高度为准。
    final pageSize = scrollController.viewportDimension.floor();
    if (pageSize <= 0) return;

    setState(() {
      final previousOffset = scrollController.offset;
      scrollController.scrollBy((direction * pageSize).toDouble());
      // 首尾处实际滚动可能不足一页，高亮跟随实际位移以保持屏内行位置。
      final movedRows = (scrollController.offset - previousOffset).round();
      hoverIndex = (hoverIndex + movedRows).clamp(0, volumes.length - 1);
    });
  }

  void _hoverUp() {
    if (volumes.isEmpty) return;
    int index = hoverIndex - 1;
    if (index < 0) {
      index = volumes.length - 1;
    }
    setState(() {
      scrollController.ensureIndexVisible(index: index);
      hoverIndex = index;
    });
  }

  void _selectHover() {
    if (volumes.isEmpty) return;
    setState(() {
      selectedMap[hoverIndex] = !(selectedMap[hoverIndex] ?? false);
    });
  }

  void _toggleAll() {
    if (selectedVolumes.length == volumes.length) {
      setState(() {
        for (var i = 0; i < volumes.length; i++) {
          selectedMap[i] = false;
        }
      });
    } else {
      setState(() {
        for (var i = 0; i < volumes.length; i++) {
          selectedMap[i] = true;
        }
      });
    }
  }

  Component _buildItem(Volume volume, int index, bool hover, bool selected) {
    Component indicator;
    if (selected && hover) {
      indicator = Text("[+]", style: TextStyle(color: primaryColor));
    } else if (hover) {
      indicator = Text("[•]", style: TextStyle(color: primaryColor));
    } else if (selected) {
      indicator = Text("[+]", style: TextStyle(color: successColor));
    } else {
      indicator = Text("[ ]", style: TextStyle(color: mutedColor));
    }
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          hoverIndex = index;
        });
      },
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedMap[index] = !(selectedMap[index] ?? false);
          });
        },
        child: Row(
          children: [
            indicator,
            SizedBox(width: 1),
            Expanded(
              child: Text(
                volume.volumeName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: hover ? null : mutedColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PackSettings {
  const PackSettings({
    required this.volumes,
    this.combineVolume = false,
    this.addChapterTitle = false,
  });

  final List<Volume> volumes;
  final bool combineVolume;
  final bool addChapterTitle;
}
