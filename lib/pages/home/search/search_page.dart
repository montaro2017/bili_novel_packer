import 'package:bili_novel_packer/foundation/app.dart';
import 'package:bili_novel_packer/novel_source/base/novel_model.dart';
import 'package:bili_novel_packer/novel_source/base/novel_source.dart';
import 'package:bili_novel_packer/widget/exception_widget.dart';
import 'package:bili_novel_packer/widget/novel_card_grid.dart';
import 'package:bili_novel_packer/widget/placeholder_widget.dart';
import 'package:bili_novel_packer/widget/split_view.dart';
import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _SearchPageState();
  }
}

class _SearchPageState extends State<SearchPage>
    with AutomaticKeepAliveClientMixin {
  late final TextEditingController _textController;
  late final SplitViewController _viewController;
  final GlobalKey<_SearchResultViewState> _resultKey = GlobalKey();

  bool _defaultRightView = true;

  NovelSource? _source;
  String? _keyword;
  int _searchId = 0;

  bool _showResult = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _viewController = SplitViewController();
  }

  @override
  void dispose() {
    super.dispose();
    _textController.dispose();
    _viewController.dispose();
  }

  void _onSearch(NovelSource source, String keyword) {
    setState(() {
      _source = source;
      _keyword = keyword;
      _searchId++;
      _showResult = true;
      if (_viewController.layout == .left) {
        _viewController.switchToRight();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    var breakPoint = App.breakPoint(context);
    SplitViewLayout layout = breakPoint >= .sm
        ? .all
        : (_defaultRightView ? .left : .right);
    return SplitView(
      layout: layout,
      controller: _viewController,
      leftConstraints: const BoxConstraints(maxWidth: 350),
      leftBuilder: (context, _) => _SearchInputView(
        controller: _textController,
        onSearchCallback: _onSearch,
      ),
      rightBuilder: _buildSearchResult,
    );
  }

  Widget _buildSearchResult(BuildContext ctx, bool showAll) {
    Widget child;
    if (_showResult) {
      _defaultRightView = false;
      child = _SearchResultView(
        key: _resultKey,
        source: _source!,
        keyword: _keyword!,
        searchId: _searchId,
        showBack: !showAll,
        onClose: () => {
          setState(() {
            _showResult = false;
          }),
        },
      );
    } else {
      _defaultRightView = true;
      child = PlaceholderWidget();
    }
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: child,
    );
  }

  @override
  bool get wantKeepAlive => true;
}

typedef OnSearchCallback = void Function(NovelSource source, String keyword);

class _SearchInputView extends StatefulWidget {
  final TextEditingController controller;
  final OnSearchCallback? onSearchCallback;

  const _SearchInputView({
    required this.controller,
    this.onSearchCallback,
  });

  @override
  State<StatefulWidget> createState() => _SearchInputViewState();
}

class _SearchInputViewState extends State<_SearchInputView> {
  NovelSource? _source = null;

  TextEditingController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: SearchBar(
          controller: controller,
          constraints: const BoxConstraints(maxHeight: 56),
          onSubmitted: (_) {
            _emitCallback();
          },
          trailing: [
            ListenableBuilder(
              listenable: controller,
              builder: (context, _) => controller.text.isNotEmpty
                  ? IconButton(
                      key: const ValueKey('clear_button'),
                      onPressed: () => controller.clear(),
                      icon: const Icon(Icons.clear),
                    )
                  : const SizedBox.shrink(),
            ),
            IconButton(
              key: const ValueKey('search_button'),
              onPressed: _emitCallback,
              icon: const Icon(Icons.search),
            ),
          ],
          hintText: "关键字 / 链接 / ID",
          textStyle: WidgetStateProperty.all(
            TextStyle(
              color: colorScheme.onSurface,
              fontSize: textTheme.bodyMedium?.fontSize,
            ),
          ),
          textInputAction: TextInputAction.search,
          keyboardType: TextInputType.webSearch,
          backgroundColor: WidgetStateProperty.all(
            colorScheme.primaryContainer,
          ),
          elevation: WidgetStateProperty.all(0),
        ),
      ),
      body: _buildBody(),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    );
  }

  Widget _buildBody() {
    return Column(
      crossAxisAlignment: .start,
      children: [
        Divider(height: 1),
        Padding(
          padding: EdgeInsets.all(8),
          child: Column(
            spacing: 8,
            crossAxisAlignment: .start,
            children: [
              Text(
                "源",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              _sourceChips(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sourceChips() {
    return Wrap(
      spacing: 8,
      children: NovelSource.sources.map((source) {
        return ChoiceChip(
          selected: _source == source,
          label: Text(source.name),
          onSelected: (bool value) {
            if (value) {
              setState(() {
                _source = source;
              });
            }
          },
        );
      }).toList(),
    );
  }

  void _emitCallback() {
    if (controller.text.isNotEmpty && _source != null) {
      widget.onSearchCallback?.call(_source!, controller.text);
    }
  }
}

class _SearchResultView extends StatefulWidget {
  final NovelSource source;
  final String keyword;
  final int searchId;
  final bool showBack;
  final Function()? onClose;

  const _SearchResultView({
    super.key,
    required this.source,
    required this.keyword,
    required this.searchId,
    required this.showBack,
    this.onClose,
  });

  @override
  State<StatefulWidget> createState() => _SearchResultViewState();
}

class _SearchResultViewState extends State<_SearchResultView> {
  SearchIterator<Novel>? _iterator;
  List<Novel> _novels = [];
  bool _loading = false;
  bool _loadingMore = false;
  dynamic _error;

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void didUpdateWidget(covariant _SearchResultView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchId != widget.searchId) {
      _search();
    }
  }

  void _search() async {
    setState(() {
      _loading = true;
      _loadingMore = false;
    });
    try {
      _iterator = widget.source.search(widget.keyword);
      _novels = await _iterator!.next();
      _error = null;
    } catch (e) {
      _error = e;
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var child = _buildChild();
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: widget.showBack
            ? BackButton()
            : IconButton(
                onPressed: widget.onClose,
                icon: Icon(Icons.close),
              ),
        title: Text("搜索结果"),
      ),
      body: child,
    );
  }

  Widget _buildChild() {
    if (_loading) {
      return _buildLoadingWidget();
    }
    if (_error != null) {
      return _buildErrorWidget();
    }
    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          children: [
            NovelCardGridView(source: widget.source, novels: _novels),
            if (_loadingMore) _buildLoadMoreIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(child: _buildLoadMoreIndicator());
  }

  Widget _buildErrorWidget() {
    return ExceptionWidget(
      e: _error,
      retry: _search,
    );
  }

  bool _onScrollNotification(ScrollNotification scrollNotification) {
    if (scrollNotification.metrics.extentAfter < 200 &&
        !_loading &&
        !_loadingMore &&
        (_iterator?.hasNext ?? false)) {
      _loadMore();
    }
    return false;
  }

  void _loadMore() async {
    setState(() {
      _loadingMore = true;
    });
    try {
      var newNovels = await _iterator!.next();
      setState(() {
        _novels = [..._novels, ...newNovels];
      });
    } catch (e) {
      setState(() {
        _error = e;
      });
    } finally {
      setState(() {
        _loadingMore = false;
      });
    }
  }

  Widget _buildLoadMoreIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
