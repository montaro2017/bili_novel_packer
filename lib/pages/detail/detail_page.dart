import 'package:bili_novel_packer/novel_source/base/novel_model.dart';
import 'package:bili_novel_packer/novel_source/base/novel_source.dart';
import 'package:bili_novel_packer/widget/collapse_panel.dart';
import 'package:bili_novel_packer/widget/exception_widget.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DetailPage extends StatefulWidget {
  final NovelSource source;
  final Novel novel;
  final String novelId;
  final String? title;

  const DetailPage({
    super.key,
    required this.source,
    required this.novel,
    required this.novelId,
    this.title,
  });

  @override
  State<StatefulWidget> createState() {
    return _DetailPageState();
  }
}

class _DetailPageState extends State<DetailPage> {
  Novel? novel;
  Catalog? catalog;
  bool loading = false;
  dynamic error;
  Uint8List? imageData;

  String? get title => novel?.title ?? widget.title;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    setState(() {
      error = null;
      loading = true;
    });
    try {
      novel = await widget.source.loadNovel(widget.novelId);
      catalog = await widget.source.loadCatalog(novel!);
    } catch (e) {
      error = e;
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: title != null ? Text(title!) : null,
        actions: [
          PopupMenuButton(
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                child: Text('刷新'),
                onTap: () {
                  _loadData();
                },
              ),
              PopupMenuItem(
                child: Text('复制链接'),
                onTap: () async {
                  await Clipboard.setData(
                    ClipboardData(text: widget.novel.url),
                  );
                  BotToast.showText(text: "复制成功");
                },
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(context),
      floatingActionButton: _buttons(),
    );
  }

  Widget _buttons() {
    return FloatingActionButton(
      onPressed: () {},
      child: Icon(Icons.download),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (loading) {
      return _loading();
    } else if (error != null) {
      return _error();
    } else {
      return _body(context);
    }
  }

  Widget _loading() {
    return Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _error() {
    return ExceptionWidget(
      e: error,
      retry: _loadData,
    );
  }

  Widget _body(BuildContext context) {
    double width = 750;
    double padding = 16;
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        constraints: BoxConstraints(maxWidth: width + padding),
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: Column(
            spacing: 16,
            children: [
              _NovelDetail(widget.source, novel!),
              Divider(thickness: 1, height: 1),
              _CatalogDetail(widget.source, catalog!),
              SizedBox(height: 64),
            ],
          ),
        ),
      ),
    );
  }
}

class _NovelDetail extends StatefulWidget {
  final NovelSource source;
  final Novel novel;

  const _NovelDetail(this.source, this.novel);

  @override
  State<StatefulWidget> createState() {
    return _NovelDetailState();
  }
}

class _NovelDetailState extends State<_NovelDetail> {
  Uint8List? imageData;

  @override
  Widget build(BuildContext context) {
    var widgets = [
      _title(),
      _source(),
      // if (widget.novel.alias != null) _aliasTitle(),
      _author(),
      _tags(),
      _desc(context),
    ];
    return Row(
      crossAxisAlignment: .start,
      children: [
        _cover(),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: .stretch,
            spacing: 4,
            children: widgets,
          ),
        ),
      ],
    );
  }

  Widget _cover() {
    return SizedBox(
      width: 130,
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: imageData != null
              ? Image.memory(imageData!)
              : Container(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Center(child: Icon(Icons.info)),
                ),
        ),
      ),
    );
  }

  Widget _title() {
    return Text(
      widget.novel.title,
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
    );
  }

  Widget _source() {
    return Text(
      widget.source.name,
      style: TextStyle(fontSize: 12),
    );
  }

  Widget _aliasTitle() {
    return Text(
      widget.novel.alias!,
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
    );
  }

  Widget _author() {
    return Text(
      widget.novel.author!,
      style: TextStyle(fontSize: 13),
    );
  }

  Widget _tag(String tag) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Text(tag, style: TextStyle(fontSize: 12)),
      ),
    );
  }

  Widget _tags() {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: widget.novel.tags!.map((tag) => _tag(tag)).toList(),
    );
  }

  Widget _desc(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      borderRadius: BorderRadiusGeometry.all(Radius.circular(8)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text('作品简介'),
                content: Text(widget.novel.description!),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('确定'),
                  ),
                ],
              );
            },
          );
        },
        child: Padding(
          padding: EdgeInsets.all(8),
          child: Text(
            widget.novel.description!,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13),
          ),
        ),
      ),
    );
  }
}

class _CatalogDetail extends StatefulWidget {
  final NovelSource source;
  final Catalog catalog;

  const _CatalogDetail(this.source, this.catalog);

  @override
  State<StatefulWidget> createState() {
    return _CatalogDetailState();
  }
}

class _CatalogDetailState extends State<_CatalogDetail> {
  final Map<Volume, bool> selectMap = {};

  bool? get selectAll {
    if (selectMap.values.every((element) => element)) {
      return true;
    }
    if (selectMap.values.any((element) => element)) {
      return null;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    for (var volume in widget.catalog.volumes) {
      selectMap[volume] = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Row(
          children: [
            Text(
              "目录",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            Spacer(),
            Text("全选"),
            SizedBox(width: 8),
            Checkbox(
              value: selectAll,
              tristate: true,
              onChanged: _toggleSelectAll,
            ),
            SizedBox(width: 8),
          ],
        ),

        SizedBox(height: 8),
        _catalog(),
        SizedBox(height: 8),
      ],
    );
  }

  void _toggleSelectAll(bool? value) {
    debugPrint("selectAll: $selectAll, value: $value");
    if (value == true) {
      setState(() {
        selectMap.updateAll((key, value) => true);
      });
    } else {
      setState(() {
        selectMap.updateAll((key, value) => false);
      });
    }
  }

  void _toggleSelect(Volume volume) {
    setState(() {
      selectMap[volume] = !(selectMap[volume] ?? false);
    });
  }

  Widget _catalog() {
    var collapsePanels = widget.catalog.volumes.map((volume) {
      return CollapsePanel(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        title: (context) {
          var state = context.findAncestorStateOfType<CollapsePanelState>();
          Animation<double> turns = Tween<double>(begin: 0.0, end: 0.5).animate(
            CurvedAnimation(
              parent: state!.controller,
              curve: Curves.easeInOut,
            ),
          );
          return Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: () {
                _toggleSelect(volume);
              },
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Checkbox(
                      value: selectMap[volume] ?? false,
                      onChanged: (v) {
                        setState(() {
                          selectMap[volume] = v!;
                        });
                      },
                    ),
                    SizedBox(width: 4),
                    Text(volume.name),
                    Spacer(),
                    GestureDetector(
                      onTap: state.toggle,
                      child: RotationTransition(
                        turns: turns,
                        child: Icon(Icons.keyboard_arrow_down_sharp),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        child: (context) {
          var chapters = volume.chapters.map((chapter) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(chapter.name, overflow: TextOverflow.ellipsis),
            );
          }).toList();
          return Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: .stretch,
              spacing: 4,
              children: [
                Divider(thickness: 1, height: 1),
                SizedBox(height: 4),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: 200),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: .start,
                      spacing: 4,
                      children: chapters,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }).toList();
    return Column(
      spacing: 8,
      children: collapsePanels,
    );
  }
}
