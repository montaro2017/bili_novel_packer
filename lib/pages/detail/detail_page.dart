import 'dart:typed_data';

import 'package:bili_novel_packer/novel_source/base/novel_model.dart';
import 'package:bili_novel_packer/novel_source/base/novel_source.dart';
import 'package:bili_novel_packer/widget/exception_widget.dart';
import 'package:flutter/material.dart';

class DetailPage extends StatefulWidget {
  final NovelSource source;
  final String novelId;
  final String? title;

  const DetailPage({
    super.key,
    required this.source,
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
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: title != null ? Text(title!) : null),
      body: _buildBody(context),
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
    return Column(
      children: [
        Row(
          crossAxisAlignment: .start,
          children: [
            _cover(),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                spacing: 4,
                children: [
                  _title(),
                  _source(),
                  // if (widget.novel.alias != null) _aliasTitle(),
                  _author(),
                  _tags(),
                  _desc(context),
                ],
              ),
            ),
          ],
        ),
        // Padding(
        //   padding: EdgeInsets.symmetric(vertical: 16),
        //   child: Divider(thickness: 1, height: 1),
        // ),
        // Column(
        //   crossAxisAlignment: .start,
        //   children: [
        //     Text(
        //       '作品简介',
        //       style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        //     ),
        //     SizedBox(height: 8),
        //     Text(
        //       widget.novel.description!,
        //       style: TextStyle(fontSize: 14),
        //     ),
        //   ],
        // ),
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
    return Row(
      spacing: 4,
      children: [
        Icon(Icons.person_rounded, size: 13),
        Text(widget.novel.author!, style: TextStyle(fontSize: 13)),
      ],
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
      spacing: 8,
      runSpacing: 8,
      children: widget.novel.tags!.map((tag) => _tag(tag)).toList(),
    );
  }

  Widget _desc(BuildContext context) {
    return InkWell(
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
      child: Text(
        widget.novel.description!,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 14),
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
  late List<ExpansionPanel> _panels;
  late Map<Volume, bool> _expands;

  @override
  void initState() {
    super.initState();
    _expands = widget.catalog.volumes.asMap().map((index, volume) {
      return MapEntry(volume, false);
    });
    _panels = widget.catalog.volumes.map((volume) {
      return ExpansionPanel(
        headerBuilder: (context, isExpanded) {
          return ListTile(
            title: Text(volume.name),
          );
        },
        body: Column(
          children: volume.chapters.map((chapter) {
            return ListTile(
              title: Text(chapter.name),
            );
          }).toList(),
        ),
        isExpanded: _expands[volume] ?? false,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Text(
          "目录",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        _catalog(),
      ],
    );
  }

  Widget _catalog() {
    return ExpansionPanelList(
      expansionCallback: (index, isExpanded) {
        setState(() {
          var volume = widget.catalog.volumes[index];
          _expands[volume] = isExpanded;
        });
      },
      children: _panels,
    );
  }
}
