import 'package:bili_novel_packer/colors.dart';
import 'package:bili_novel_packer/components/overlays/select_chapter_overlay.dart';
import 'package:bili_novel_packer/components/packer_app.dart';
import 'package:bili_novel_packer/components/spinner.dart';
import 'package:bili_novel_packer/light_novel/base/light_novel_model.dart';
import 'package:bili_novel_packer/light_novel/base/light_novel_source.dart';
import 'package:nocterm/nocterm.dart';

class NovelItem extends StatefulComponent {
  const NovelItem({
    required this.link,
    required this.mode,
    this.onStatusChanged,
    this.onRequestFocus,
  });

  NovelItem copyWith({WorkMode? mode}) {
    return NovelItem(
      link: link,
      mode: mode ?? this.mode,
      onStatusChanged: onStatusChanged,
      onRequestFocus: onRequestFocus,
    );
  }

  final NovelLink link;
  final WorkMode mode;
  final void Function(WorkStatus status)? onStatusChanged;
  final void Function(bool requestFocus)? onRequestFocus;

  @override
  State<StatefulComponent> createState() => _NovelItemState();
}

class _NovelItemState extends State<NovelItem> {
  late WorkMode mode;
  late WorkStatus _status;

  Novel? novel;
  Catalog? catalog;
  PackSettings? packSettings;

  String? statusLine;
  dynamic err;

  OverlayEntry? _overlayEntry;

  String get url => component.link.url;

  LightNovelSource get source => component.link.source;

  WorkStatus get status => _status;

  set status(WorkStatus s) {
    if (s == _status) {
      return;
    }
    _status = s;
    component.onStatusChanged?.call(s);
  }

  @override
  void initState() {
    super.initState();
    mode = component.mode;
    _status = .working;
    _pack();
  }

  @override
  void didUpdateComponent(covariant NovelItem oldComponent) {
    if (oldComponent.mode != component.mode) {
      mode = component.mode;
    }
  }

  @override
  void dispose() {
    super.dispose();
    _hideOverlay();
  }

  @override
  Component build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        _titleLine(),
        ?_statusLine(),
        ?_errLine(),
      ],
    );
  }

  Component _titleLine() {
    Component indicator = switch (status) {
      .idle => Text("•", style: TextStyle(color: mutedColor)),
      .working => Spinner(color: primaryColor),
      .complted => Text("•", style: TextStyle(color: successColor)),
      .error => Text("•", style: TextStyle(color: destructiveColor)),
    };
    return Row(
      crossAxisAlignment: .start,
      children: [
        indicator,
        SizedBox(width: 1),
        Flexible(
          child: novel != null
              ? RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(text: novel!.title),
                      TextSpan(
                        text: "(${component.link.url})",
                        style: TextStyle(color: mutedColor),
                      ),
                    ],
                  ),
                )
              : Text(component.link.url),
        ),
      ],
    );
  }

  Component? _statusLine() {
    if (statusLine == null) {
      return null;
    }
    return Padding(
      padding: EdgeInsets.only(left: 2),
      child: Row(
        crossAxisAlignment: .start,
        children: [
          Text("└ "),
          Flexible(child: Text("$statusLine")),
        ],
      ),
    );
  }

  Component? _errLine() {
    if (err == null) {
      return null;
    }
    return Padding(
      padding: EdgeInsets.only(left: 2),
      child: Row(
        crossAxisAlignment: .start,
        children: [
          Text(
            "└ ",
            style: TextStyle(
              color: destructiveColor,
            ),
          ),
          Flexible(
            child: SelectionArea(
              child: Text(
                err.toString(),
                style: TextStyle(
                  color: destructiveColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSelectChapterOverlay() {
    statusLine = "选择分卷...";
    _hideOverlay();
    _hideCursor();
    _overlayEntry = OverlayEntry(
      opaque: true,
      builder: (context) {
        return SelectChapterOverlay(
          catalog: catalog!,
          onCancel: () {
            _hideOverlay();
            setState(() {
              status = .error;
              err = "操作已取消";
            });
          },
        );
      },
    );
    component.onRequestFocus?.call(true);
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _showPackSettingsOverlay() {
    _hideOverlay();
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    component.onRequestFocus?.call(false);
    _showCursor();
  }

  void _hideCursor() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _overlayEntry == null) return;
      final terminal = TerminalBinding.instance.terminal;
      terminal.hideCursor();
      terminal.flush();
    });
  }

  void _showCursor() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _overlayEntry == null) return;
      final terminal = TerminalBinding.instance.terminal;
      terminal.showCursor();
    });
  }

  void _pack() async {
    try {
      await _fetchNovel();
      await _fetchCatalog();
    } catch (e) {
      setState(() {
        err = e;
        status = .error;
      });
    }
  }

  Future<void> _fetchNovel() async {
    setState(() {
      statusLine = "获取详情...";
    });
    novel = await source.getNovel(url);
  }

  Future<void> _fetchCatalog() async {
    setState(() {
      statusLine = "获取目录...";
    });
    catalog = await source.getNovelCatalog(novel!);
    if (mode == .manual) {
      _showSelectChapterOverlay();
    } else {
      packSettings = _defaultSettings();
      await _doPack();
    }
  }

  Future<void> _doPack() async {}

  PackSettings _defaultSettings() {
    return PackSettings(
      volumes: catalog!.volumes,
    );
  }
}
