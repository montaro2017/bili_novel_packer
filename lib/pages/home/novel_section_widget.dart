import 'package:bili_novel_packer/novel_source/base/novel_model.dart';
import 'package:bili_novel_packer/novel_source/base/novel_source.dart';
import 'package:bili_novel_packer/widget/novel_card_grid.dart';
import 'package:flutter/material.dart';

class NovelSectionWidget extends StatefulWidget {
  final NovelSource source;
  final NovelSection section;
  final void Function(Novel)? onTap;

  const NovelSectionWidget({
    super.key,
    required this.source,
    required this.section,
    this.onTap,
  });

  @override
  State<StatefulWidget> createState() {
    return _NovelSectionWidgetState();
  }
}

class _NovelSectionWidgetState extends State<NovelSectionWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.section.name != null)
          Padding(
            padding: EdgeInsetsGeometry.symmetric(vertical: 8, horizontal: 16),
            child: Text(
              widget.section.name!,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
          ),
        NovelCardGridView(
          source: widget.source,
          novels: widget.section.novels,
          onTap: widget.onTap,
        ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}
