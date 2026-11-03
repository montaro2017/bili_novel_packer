import 'package:bili_novel_packer/components/clickable.dart';
import 'package:bili_novel_packer/components/wrap.dart';
import 'package:bili_novel_packer/pack_settings.dart';
import 'package:nocterm/nocterm.dart';

class PackSettingsOverlay extends StatefulComponent {
  const PackSettingsOverlay({
    this.onCancel,
    this.onConfirm,
  });

  final void Function()? onCancel;
  final void Function(PackSettings settings)? onConfirm;

  @override
  State<StatefulComponent> createState() => _PackSettingsOverlayState();
}

class _PackSettingsOverlayState extends State<PackSettingsOverlay> {
  int focusedIndex = 0;

  // settings
  bool addTitle = false;
  bool combineVolume = false;
  ChineseConvert chineseConvert = .none;
  String? bookName;

  List<_SettingsField> get fields {
    final builders = <_SettingsField Function(int index)>[
      (index) => _SelectorField<bool>(
        label: "添加标题",
        labelWidth: 8,
        desc: "在每一章开头添加一个醒目的标题",
        options: [
          _Option("否", false),
          _Option("是", true),
        ],
        value: addTitle,
        focused: focusedIndex == index,
        onRequestFocus: () {
          setState(() => focusedIndex = index);
          return true;
        },
        onValueChanged: (value) {
          setState(() => addTitle = value);
        },
      ),
      (index) => _SelectorField<bool>(
        label: "合并分卷",
        labelWidth: 8,
        desc: "将所选分卷合并为一个文件，所需时间较长",
        options: [
          _Option("否", false),
          _Option("是", true),
        ],
        value: combineVolume,
        focused: focusedIndex == index,
        onRequestFocus: () {
          setState(() => focusedIndex = index);
          return true;
        },
        onValueChanged: (value) => setState(() => combineVolume = value),
      ),
      (index) => _SelectorField<ChineseConvert>(
        label: "繁简转换",
        labelWidth: 8,
        desc: "转换为简体或繁体",
        options: [
          _Option("不转换", .none),
          _Option("转繁体", .s2t),
          _Option("转简体", .t2s),
        ],
        value: chineseConvert,
        focused: focusedIndex == index,
        onRequestFocus: () {
          setState(() => focusedIndex = index);
          return true;
        },
        onValueChanged: (value) => setState(() => chineseConvert = value),
      ),
      (index) => _InputField(
        label: "覆盖书名",
        desc: "重新设定书名",
        value: bookName,
        focused: focusedIndex == index,
        onRequestFocus: () {
          setState(() => focusedIndex = index);
          return true;
        },
        onValueChanged: (v) => setState(() => bookName = v),
      ),
    ];
    return [
      for (final (index, build) in builders.indexed) build(index),
    ];
  }

  List<Component> get spacedFields => [
    for (var i = 0; i < fields.length; i++) ...[
      if (i > 0) const SizedBox(height: 1),
      fields[i],
    ],
  ];

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: _keyEvent,
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
              children: spacedFields,
            ),
            SizedBox(height: 1),
            _buildHelpText(context),
          ],
        ),
      ),
    );
  }

  Component _buildHelpText(
    BuildContext context,
  ) {
    return Wrap(
      spacing: 2,
      alignment: WrapAlignment.center,
      children: [
        _helpHint("↑↓←→: ", "导航"),
        _helpHint("Space: ", "选中"),
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

  bool _keyEvent(KeyboardEvent e) {
    if (e.logicalKey == LogicalKey.arrowDown) {
      _focusDown();
      return true;
    }
    if (e.logicalKey == LogicalKey.arrowUp) {
      _focusUp();
      return true;
    }
    if (e.logicalKey == LogicalKey.enter) {
      _confirm();
      return true;
    }
    if (e.logicalKey == LogicalKey.escape) {
      _cancel();
      return true;
    }
    return false;
  }

  void _focusDown() {
    if (focusedIndex >= fields.length - 1) return;
    setState(() => focusedIndex++);
  }

  void _focusUp() {
    if (focusedIndex <= 0) return;
    setState(() => focusedIndex--);
  }

  void _confirm() {
    var settings = PackSettings(
      addTitle: addTitle,
      combineVolume: combineVolume,
      chineseConvert: chineseConvert,
    );
    component.onConfirm?.call(settings);
  }

  void _cancel() {
    component.onCancel?.call();
  }
}

abstract class _SettingsField<T> extends StatefulComponent {
  const _SettingsField({
    required this.label,
    this.desc,
    this.focused = false,
    this.value,
    this.onRequestFocus,
    this.onValueChanged,
  });

  final String label;
  final String? desc;
  final bool focused;
  final T? value;
  final bool Function()? onRequestFocus;
  final void Function(T value)? onValueChanged;
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

class _SelectorField<T> extends _SettingsField<T> {
  _SelectorField({
    required super.label,
    required super.desc,
    required this.options,
    super.value,
    super.focused,
    super.onRequestFocus,
    super.onValueChanged,
    required this.labelWidth,
  });

  final double labelWidth;
  final List<_Option<T>> options;

  @override
  State<StatefulComponent> createState() => _SelectorFieldState<T>();
}

class _SelectorFieldState<T> extends State<_SelectorField<T>> {
  int hoverIndex = 0;

  int get activatedIndex => selectorOptions.indexed
      .where((e) => e.$2.value == component.value)
      .first
      .$1;

  bool get focused => component.focused;

  List<_Option<T>> get selectorOptions => component.options;

  @override
  Component build(BuildContext context) {
    var theme = TuiTheme.of(context);
    return Focusable(
      focused: component.focused,
      onKeyEvent: _keyEvent,
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Row(
            mainAxisSize: .min,
            children: [
              SizedBox(
                width: component.labelWidth,
                child: Text(component.label),
              ),
              SizedBox(width: 2),
              Row(
                mainAxisSize: .min,
                children: _buildOptions(),
              ),
            ],
          ),
          if (component.desc != null)
            Text(component.desc!, style: TextStyle(color: theme.outlineVariant)),
        ],
      ),
    );
  }

  bool _keyEvent(KeyboardEvent e) {
    if (e.logicalKey == LogicalKey.arrowLeft) {
      _hoverLeft();
      return true;
    }
    if (e.logicalKey == LogicalKey.arrowRight) {
      _hoverRight();
      return true;
    }
    if (e.logicalKey == LogicalKey.space) {
      _select(hoverIndex);
      return true;
    }
    return false;
  }

  void _hoverLeft() {
    if (hoverIndex <= 0) return;
    setState(() => hoverIndex--);
  }

  void _hoverRight() {
    if (hoverIndex >= selectorOptions.length - 1) return;
    setState(() => hoverIndex++);
  }

  void _select(int index) {
    var value = selectorOptions[index].value;
    component.onValueChanged?.call(value);
  }

  List<Component> _buildOptions() {
    List<Component> options = [];
    for (var i = 0; i < selectorOptions.length; i++) {
      var option = selectorOptions[i];
      var hover = hoverIndex == i;
      var activated = activatedIndex == i;
      options.add(_buildOption(option, i, hover, activated));
    }
    return options;
  }

  Component _buildOption(
    _Option<T> option,
    int index,
    bool hover,
    bool activated,
  ) {
    var theme = TuiTheme.of(context);
    return Clickable(
      onClick: () {
        component.onValueChanged?.call(option.value);
      },
      onEnter: () {
        if (_requestFocus()) {
          setState(() {
            hoverIndex = index;
          });
        }
      },
      builder: (_) => Row(
        mainAxisSize: .min,
        children: [
          SizedBox(
            width: 1,
            child: hover && focused ? Text("[") : null,
          ),
          Text(
            activated ? "● " : "○ ",
            style: TextStyle(
              color: ((hover && focused) || activated) ? null : theme.outlineVariant,
            ),
          ),
          Text(
            option.label,
            style: TextStyle(
              color: ((hover && focused) || activated) ? null : theme.outlineVariant,
            ),
          ),
          SizedBox(
            width: 1,
            child: hover && focused ? Text("]") : null,
          ),
        ],
      ),
    );
  }

  bool _requestFocus() {
    return component.onRequestFocus?.call() ?? false;
  }
}

class _InputField extends _SettingsField<String> {
  _InputField({
    required super.label,
    super.desc,
    super.value,
    super.focused,
    super.onRequestFocus,
    super.onValueChanged,
  });

  @override
  State<StatefulComponent> createState() => _InputFieldState();
}

class _InputFieldState extends State<_InputField> {
  final TextEditingController controller = TextEditingController();

  @override
  void initState() {
    if (component.value != null) {
      controller.text = component.value!;
    }
  }

  @override
  Component build(BuildContext context) {
    var theme = TuiTheme.of(context);
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 45),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Text(component.label),
          Column(
            children: [
              Divider(),
              Clickable(
                onClick: () {
                  _requestFocus();
                },
                builder: (_) => Row(
                  mainAxisSize: .min,
                  children: [
                    Text("› "),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        focused: component.focused,
                        onChanged: (value) =>
                            component.onValueChanged?.call(value),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(),
            ],
          ),
          if (component.desc != null)
            Text(
              component.desc!,
              style: TextStyle(
                color: theme.outlineVariant,
              ),
            ),
        ],
      ),
    );
  }

  bool _requestFocus() {
    return component.onRequestFocus?.call() ?? false;
  }
}
