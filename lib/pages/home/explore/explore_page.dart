import 'dart:io';

import 'package:bili_novel_packer/exception.dart';
import 'package:bili_novel_packer/foundation/app.dart';
import 'package:bili_novel_packer/novel_source/base/novel_model.dart';
import 'package:bili_novel_packer/novel_source/base/novel_source.dart';
import 'package:bili_novel_packer/pages/detail/detail_page.dart';
import 'package:bili_novel_packer/pages/home/novel_section_widget.dart';
import 'package:flutter/material.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _ExplorePageState();
  }
}

class _ExplorePageState extends State<ExplorePage>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  late final TabController _controller;
  late final Map<NovelSource, GlobalKey<_NovelSourceHomeWidgetState>> _keyMap;

  @override
  void initState() {
    super.initState();
    _controller = TabController(
      length: NovelSource.sources.length,
      vsync: this,
    );
    _keyMap = {};
    for (var s in NovelSource.sources) {
      _keyMap[s] = GlobalKey<_NovelSourceHomeWidgetState>();
    }
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    var sources = NovelSource.sources;
    return Scaffold(
      appBar: AppBar(
        title: TabBar(
          controller: _controller,
          tabs: sources.map((s) => _toTab(s)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _controller,
        children: sources
            .map((s) => _NovelSourceHomeWidget(s, key: _keyMap[s]))
            .toList(),
      ),
      // 桌面端无法使用下拉刷新 添加一个刷新按钮
      floatingActionButton: App.isDesktop
          ? FloatingActionButton(
              onPressed: () {
                var currentSource = NovelSource.sources.elementAtOrNull(
                  _controller.index,
                );
                var key = _keyMap[currentSource];
                key?.currentState?._loadData();
              },
              child: Icon(Icons.refresh),
            )
          : null,
    );
  }

  Tab _toTab(NovelSource source) {
    return Tab(text: source.name);
  }

  @override
  bool get wantKeepAlive => true;
}

class _NovelSourceHomeWidget extends StatefulWidget {
  final NovelSource source;

  const _NovelSourceHomeWidget(this.source, {super.key});

  @override
  State<StatefulWidget> createState() {
    return _NovelSourceHomeWidgetState();
  }
}

class _NovelSourceHomeWidgetState extends State<_NovelSourceHomeWidget>
    with AutomaticKeepAliveClientMixin {
  String? errorMsg;
  bool? retryAble;
  List<NovelSection>? sections;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (loading) {
      return _buildLoadingWidget();
    } else if (errorMsg != null) {
      return _buildErrorWidget();
    } else {
      return _buildExploreWidget();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      loading = true;
    });
    try {
      var explore = await widget.source.explore();
      setState(() {
        sections = explore;
      });
    } on NotRetryableException catch (e) {
      setState(() {
        errorMsg = e.message;
        retryAble = false;
      });
    } catch (e) {
      setState(() {
        errorMsg = e.toString();
        retryAble = true;
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorWidget() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(errorMsg ?? ''),
            if (retryAble ?? false)
              Padding(
                padding: EdgeInsetsGeometry.only(top: 10),
                child: ElevatedButton(
                  onPressed: _loadData,
                  child: Text('重试'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExploreWidget() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        itemCount: sections!.length,
        itemBuilder: (context, index) {
          var section = sections![index];
          var sectionWidget = NovelSectionWidget(
            source: widget.source,
            section: section,
            onTap: onTap,
          );
          if (index == 0) {
            return Padding(
              padding: EdgeInsetsGeometry.only(top: 8),
              child: sectionWidget,
            );
          } else {
            return sectionWidget;
          }
        },
      ),
    );
  }

  void onTap(Novel novel) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DetailPage(
          source: widget.source,
          novelId: novel.id,
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
