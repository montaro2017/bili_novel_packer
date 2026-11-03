import 'package:bili_novel_packer/components/clickable.dart';
import 'package:bili_novel_packer/components/marquee.dart';
import 'package:bili_novel_packer/components/wrap.dart';
import 'package:bili_novel_packer/light_novel/base/light_novel_model.dart';
import 'package:nocterm/nocterm.dart';

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

  Component _buildHelpText(
    BuildContext context,
  ) {
    return Wrap(
      alignment: .center,
      spacing: 2,
      crossAxisAlignment: .center,
      children: [
        _helpHint("↑/↓: ", "导航"),
        _helpHint("←/→: ", "翻页"),
        _helpHint("Space: ", "选择"),
        _helpAction("A: ", "全选", _toggleAll),
        _helpAction("Enter: ", "确认", _confirm),
        _helpAction("Esc: ", "取消", _cancel),
      ],
    );
  }

  Component _helpHint(String key, String desc) {
    var theme = TuiTheme.of(context);
    return Row(
      mainAxisSize: .min,
      children: [
        Text(key, style: TextStyle(color: theme.outlineVariant)),
        Text(desc),
      ],
    );
  }

  Component _helpAction(
    String key,
    String desc,
    void Function() onClick,
  ) {
    var theme = TuiTheme.of(context);
    return Clickable(
      onClick: onClick,
      builder: (hover) => Row(
        mainAxisSize: .min,
        children: [
          Text(key, style: TextStyle(color: hover ? null : theme.outlineVariant)),
          Text(desc),
        ],
      ),
    );
  }

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
            _buildVolumeList(),
            SizedBox(height: 1),
            _buildHelpText(context),
          ],
        ),
      ),
    );
  }

  Component _buildVolumeList() {
    return Expanded(
      child: Scrollbar(
        controller: scrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: scrollController,
          keyboardScrollable: true,
          padding: EdgeInsets.only(right: 2),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 75),
            child: Column(
              crossAxisAlignment: .start,
              children: [
                for (var i = 0; i < volumes.length; i++)
                  _buildItem(
                    volumes[i],
                    i,
                    hoverIndex == i,
                    selectedMap[i] ?? false,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _onKeyEvent(KeyboardEvent event) {
    if (event.logicalKey == LogicalKey.keyA) {
      _toggleAll();
      return true;
    }
    if (event.logicalKey == LogicalKey.space ||
        event.logicalKey == LogicalKey.digit5) {
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
      _confirm();
      return true;
    }
    if (event.logicalKey == LogicalKey.escape) {
      _cancel();
      return true;
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
      scrollController.ensureVisible(
        itemOffset: index.toDouble(),
        itemExtent: 1.0,
      );
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
      scrollController.ensureVisible(
        itemOffset: index.toDouble(),
        itemExtent: 1.0,
      );
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

  void _confirm() {
    if (selectedVolumes.isNotEmpty) {
      component.onConfirm?.call(selectedVolumes);
    }
  }

  void _cancel() {
    component.onCancel?.call();
  }

  Component _buildItem(
    Volume volume,
    int index,
    bool hover,
    bool selected,
  ) {
    var theme = TuiTheme.of(context);
    Component indicator;
    if (selected && hover) {
      indicator = Text("[+]", style: TextStyle(color: theme.primary));
    } else if (hover) {
      indicator = Text("[ ]", style: TextStyle(color: theme.primary));
    } else if (selected) {
      indicator = Text("[+]", style: TextStyle(color: theme.success));
    } else {
      indicator = Text("[ ]", style: TextStyle(color: theme.outlineVariant));
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
          mainAxisSize: .min,
          children: [
            indicator,
            SizedBox(width: 1),
            Flexible(
              child: Marquee(
                marquee: hover,
                child: Text(
                  volume.volumeName,
                  maxLines: 1,
                  style: TextStyle(color: hover ? null : theme.outlineVariant),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}