import 'package:bili_novel_packer/novel_source/base/novel_model.dart';
import 'package:bili_novel_packer/novel_source/base/novel_source.dart';
import 'package:bili_novel_packer/widget/error_widget.dart';
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
  bool loading = false;
  dynamic error;

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
      appBar: AppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (loading) _loading(),
          if (error != null) _error(),
        ],
      ),
    );
  }

  Widget _loading() {
    return const Expanded(
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _error() {
    return Expanded(
      child: ErrorRetryWidget(
        error: error,
        retry: _loadData,
      ),
    );
  }
}
