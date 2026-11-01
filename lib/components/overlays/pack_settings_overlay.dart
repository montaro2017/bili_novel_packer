import 'dart:math' as math;

import 'package:bili_novel_packer/colors.dart';
import 'package:bili_novel_packer/pack_option.dart';
import 'package:nocterm/nocterm.dart';
// ignore: implementation_imports
import 'package:nocterm/src/utils/unicode_width.dart';

class PackSettingsOverlay extends StatefulComponent {
  const PackSettingsOverlay({
    this.onCancel,
    this.onConfirm,
  });

  final void Function()? onCancel;
  final void Function(PackSettings option)? onConfirm;

  @override
  State<StatefulComponent> createState() => _PackSettingsOverlayState();
}

final addTitle = _PackSettingsItem<bool>(
  name: "添加标题",
  options: [
    _Option("是", true),
    _Option("否", false),
  ],
  defaultValue: false,
  desc: "在每一章开头添加一个醒目的标题",
);

final combineVolume = _PackSettingsItem<bool>(
  name: "合并分卷",
  options: [
    _Option("是", true),
    _Option("否", false),
  ],
  defaultValue: false,
  desc: "将所选分卷合并为一个文件，不推荐，花费时间长容易失败",
);

final chineseConvert = _PackSettingsItem<ChineseConvert>(
  name: "繁简转换",
  options: [
    _Option("不转换", .none),
    _Option("转简体", .t2s),
    _Option("转繁体", .s2t),
  ],
  defaultValue: .none,
);

class _PackSettingsOverlayState extends State<PackSettingsOverlay> {
  final List<_PackSettingsItem> items = [
    addTitle,
    combineVolume,
    chineseConvert,
  ];

  int focusedIndex = 0;

  double get _nameWidth {
    var width = 0;
    for (var item in items) {
      width = math.max(width, UnicodeWidth.stringWidth(item.name));
    }
    return width.toDouble();
  }

  @override
  Component build(BuildContext context) {
    List<Component> selectors = [];
    for (var i = 0; i < items.length; i++) {
      var item = items[i];
      selectors.add(
        _PackSettingsItemSelector(
          item: item,
          focused: i == focusedIndex,
          nameWidth: _nameWidth,
        ),
      );
    }

    return Focusable(
      focused: true,
      onKeyEvent: _onKeyEvent,
      child: Container(
        padding: EdgeInsets.all(1),
        constraints: BoxConstraints.expand(),
        decoration: BoxDecoration(border: BoxBorder.all()),
        child: Column(
          crossAxisAlignment: .center,
          children: [
            Text("打包配置"),
            SizedBox(height: 1),
            Column(
              crossAxisAlignment: .start,
              children: selectors,
            ),
          ],
        ),
      ),
    );
  }

  bool _onKeyEvent(KeyboardEvent event) {
    if (event.logicalKey == LogicalKey.arrowDown) {
      _focusDown();
      return true;
    }
    if (event.logicalKey == LogicalKey.arrowUp) {
      _focusUp();
      return true;
    }
    return false;
  }

  void _focusDown() {
    if (focusedIndex >= items.length - 1) return;
    setState(() {
      focusedIndex++;
    });
  }

  void _focusUp() {
    if (focusedIndex <= 0) return;
    setState(() {
      focusedIndex--;
    });
  }
}

class _PackSettingsItem<T> {
  _PackSettingsItem({
    required this.name,
    required this.options,
    required this.defaultValue,
    this.desc,
  }) : assert(options.map((opt) => opt.value).toList().contains(defaultValue));

  final String name;
  final List<_Option<T>> options;
  final T defaultValue;
  final String? desc;
}

class _Option<T> {
  const _Option(this.label, this.value);

  final String label;
  final T value;

  @override
  int get hashCode => value.hashCode;

  @override
  bool operator ==(Object other) {
    if (other is! _Option<T>) return false;
    if (value == other.value) return true;
    return false;
  }
}

class _PackSettingsItemSelector<T> extends StatefulComponent {
  const _PackSettingsItemSelector({
    required this.item,
    this.defaultValue,
    required this.focused,
    required this.nameWidth,
  });

  final _PackSettingsItem<T> item;
  final bool focused;
  final T? defaultValue;
  final double nameWidth;

  @override
  State<StatefulComponent> createState() => _PackSettingsItemSelectorState<T>();
}

class _PackSettingsItemSelectorState<T>
    extends State<_PackSettingsItemSelector<T>> {
  _PackSettingsItem<T> get item => component.item;

  List<_Option<T>> get options => item.options;

  T? get defaultValue => component.defaultValue;

  bool get focused => component.focused;

  @override
  Component build(BuildContext context) {
    List<Component> labels = [];
    for (var i = 0; i < options.length; i++) {
      var opt = options[i];
      if (i == 0) {
        labels.add(Text(opt.label, style: TextStyle(color: mutedColor)));
      } else {
        labels.add(
          Row(
            mainAxisSize: .min,
            children: [
              SizedBox(width: 2),
              Text(opt.label, style: TextStyle(color: mutedColor)),
            ],
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: .start,
      children: [
        Row(
          mainAxisSize: .min,
          mainAxisAlignment: .start,
          children: [
            SizedBox(
              width: 2,
              child: focused
                  ? Text("›", style: TextStyle(color: primaryColor))
                  : null,
            ),
            SizedBox(
              width: component.nameWidth,
              child: Text(item.name),
            ),
            SizedBox(width: 2),
            ...labels,
          ],
        ),
        if (item.desc != null)
          Row(
            mainAxisSize: .min,
            children: [
              SizedBox(width: 2),
              Text(item.desc!, style: TextStyle(color: mutedColor)),
            ],
          ),
        SizedBox(height: 1),
      ],
    );
  }
}
