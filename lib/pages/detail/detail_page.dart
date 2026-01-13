import 'package:bili_novel_packer/novel_source/base/novel_model.dart';
import 'package:bili_novel_packer/novel_source/base/novel_source.dart';
import 'package:flutter/material.dart';

class DetailPage extends StatefulWidget {
  final NovelSource source;
  final String novelId;

  const DetailPage({
    super.key,
    required this.source,
    required this.novelId,
  });

  @override
  State<StatefulWidget> createState() {
    return _DetailPageState();
  }
}

class _DetailPageState extends State<DetailPage> {
  Novel? novel;
  Catalog? catalog;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    widget.source.loadNovel(widget.novelId).then((novel) {
      setState(() {
        this.novel = novel;
      });
      widget.source.loadCatalog(novel).then((catalog) {
        setState(() {
          this.catalog = catalog;
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(),
    );
  }
}
