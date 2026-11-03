import 'package:bili_novel_packer/components/overlays/pack_settings_overlay.dart';
import 'package:bili_novel_packer/components/overlays/select_chapter_overlay.dart';
import 'package:bili_novel_packer/components/packer_app.dart';
import 'package:bili_novel_packer/components/spinner.dart';
import 'package:bili_novel_packer/light_novel/base/light_novel_model.dart';
import 'package:bili_novel_packer/light_novel/base/light_novel_source.dart';
import 'package:bili_novel_packer/pack_settings.dart';
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

  String? statusLine;
  dynamic err;

  final List<OverlayEntry> _overlays = [];

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
  void dispose() {
    for (final e in _overlays.reversed) {
      e.remove();
    }
    _overlays.clear();
    super.dispose();
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
    var theme = TuiTheme.of(context);
    Component indicator = switch (status) {
      .idle => Text("•", style: TextStyle(color: theme.outlineVariant)),
      .working => Spinner(color: theme.primary),
      .complted => Text("•", style: TextStyle(color: theme.success)),
      .error => Text("•", style: TextStyle(color: theme.error)),
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
                        style: TextStyle(color: theme.outlineVariant),
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
    var theme = TuiTheme.of(context);

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
              color: theme.error,
            ),
          ),
          Flexible(
            child: SelectionArea(
              child: Text(
                err.toString(),
                style: TextStyle(
                  color: theme.error,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openOverlay(OverlayEntry overlay) {
    if (_overlays.isEmpty) {
      component.onRequestFocus?.call(true);
      _hideCursor();
    }
    _overlays.add(overlay);
    Overlay.of(context).insert(overlay);
  }

  void _closeOverlay(OverlayEntry overlay) {
    if (!_overlays.remove(overlay)) return;
    overlay.remove();
    if (_overlays.isEmpty) {
      component.onRequestFocus?.call(false);
      _showCursor();
    }
  }

  void _popOverlay() {
    if (_overlays.isEmpty) return;
    _closeOverlay(_overlays.last);
  }

  void _closeAllOverlays() {
    while (_overlays.isNotEmpty) {
      _popOverlay();
    }
  }

  void _showSelectChapterOverlay() {
    statusLine = "选择分卷...";
    _openOverlay(
      OverlayEntry(
        opaque: true,
        maintainState: true,
        builder: (context) {
          return SelectChapterOverlay(
            catalog: catalog!,
            onCancel: () {
              _popOverlay();
              setState(() {
                status = .error;
                err = "操作已取消";
              });
            },
            onConfirm: (selectedVolumes) {
              _showPackSettingsOverlay(selectedVolumes);
            },
          );
        },
      ),
    );
  }

  void _showPackSettingsOverlay(List<Volume> selectedVolumes) {
    _openOverlay(
      OverlayEntry(
        opaque: true,
        maintainState: true,
        builder: (context) {
          return PackSettingsOverlay(
            onCancel: () {
              _popOverlay();
            },
            onConfirm: (settings) {
              _closeAllOverlays();
              _doPack(selectedVolumes, settings);
            },
          );
        },
      ),
    );
  }

  void _hideCursor() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final terminal = TerminalBinding.instance.terminal;
      terminal.hideCursor();
      terminal.flush();
    });
  }

  void _showCursor() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
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
      await _doPack([], PackSettings());
    }
  }

  Future<void> _doPack(List<Volume> volumes, PackSettings settings) async {}
}
