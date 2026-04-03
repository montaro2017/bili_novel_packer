import 'dart:math';

import 'package:bili_novel_packer/novel_source/base/novel_model.dart';
import 'package:bili_novel_packer/novel_source/base/novel_source.dart';
import 'package:bili_novel_packer/widget/novel_card.dart';
import 'package:flutter/material.dart';

class NovelCardGridView extends StatefulWidget {
  final NovelSource source;
  final List<Novel> novels;
  final void Function(Novel novel)? onTap;

  const NovelCardGridView({
    super.key,
    required this.source,
    required this.novels,
    this.onTap,
  });

  @override
  State<StatefulWidget> createState() => _NovelCardGridState();
}

class _NovelCardGridState extends State<NovelCardGridView> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final crossAxisCount = (constraints.maxWidth / 360).round();
          final itemWidth = constraints.maxWidth / crossAxisCount;
          final double coverWidth = min(itemWidth * 0.34, 140);
          final coverHeight = coverWidth * 4 / 3;
          final itemHeight = coverHeight + 16;
          final aspectRatio = itemWidth / itemHeight;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: aspectRatio, // 横向卡片比例
            ),
            itemCount: widget.novels.length,
            itemBuilder: (ctx, index) {
              return _novelCard(widget.novels[index], coverWidth, widget.onTap);
            },
          );
        },
      ),
    );
  }

  Widget _novelCard(
    Novel novel,
    double coverWidth,
    void Function(Novel)? onTap,
  ) {
    return NovelCard(
      source: widget.source,
      novel: novel,
      coverWidth: coverWidth,
      onTap: onTap != null ? () => onTap(novel) : null,
    );
  }
}
