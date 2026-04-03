import 'dart:typed_data';

import 'package:bili_novel_packer/config/global_config.dart';
import 'package:bili_novel_packer/novel_source/base/novel_model.dart';
import 'package:bili_novel_packer/novel_source/base/novel_source.dart';
import 'package:flutter/material.dart';
import 'package:nil/nil.dart';

class NovelCard extends StatefulWidget {
  final NovelSource source;
  final Novel novel;
  final double coverWidth;
  final void Function()? onTap;

  const NovelCard({
    super.key,
    required this.source,
    required this.coverWidth,
    required this.novel,
    this.onTap,
  });

  @override
  State<StatefulWidget> createState() {
    return _NovelCardState();
  }
}

class _NovelCardState extends State<NovelCard> {
  Uint8List? _imageData;

  @override
  void initState() {
    super.initState();
    if (widget.novel.coverUrl != null && GlobalConfig.loadImage) {
      widget.source.loadImage(widget.novel.coverUrl!).then((data) {
        setState(() {
          _imageData = data;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadiusGeometry.circular(8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          child: Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _novelCover(),
                SizedBox(width: 8),
                _novelInfo(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _novelCover() {
    return SizedBox(
      width: widget.coverWidth,
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: _imageData != null
              ? Image.memory(
                  _imageData!,
                  fit: BoxFit.cover,
                )
              : Container(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Center(child: Icon(Icons.info)),
                ),
        ),
      ),
    );
  }

  Widget _novelInfo() {
    return Flexible(
      fit: FlexFit.loose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          // 标题
          _title(),
          // 作者
          if (widget.novel.author != null) _author(),
          // 标签
          if (widget.novel.tags != null) _tags(),
          if (widget.novel.description != null) _desc(),
        ],
      ),
    );
  }

  Widget _title() {
    return Text(
      widget.novel.title,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
    );
  }

  Widget _author() {
    return Row(
      spacing: 4,
      children: [
        Icon(
          Icons.person_rounded,
          size: 13,
        ),
        Flexible(
          child: Text(
            widget.novel.author!,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13),
          ),
        ),
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: 4,
        children: widget.novel.tags!.map((tag) => _tag(tag)).toList(),
      ),
    );
  }

  Widget _desc() {
    return Flexible(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          var fontSize = 13;
          var lineHeight = 1.5;
          var maxLines = (constraints.maxHeight / (fontSize * lineHeight))
              .floor();
          if (maxLines <= 0) {
            return nil;
          }
          return Text(
            _removeLineBreak(widget.novel.description!),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, height: lineHeight),
          );
        },
      ),
    );
  }

  String _removeLineBreak(String str) {
    return str.replaceAll("[\r\n\t]", "");
  }
}
