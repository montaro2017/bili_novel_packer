import 'package:bili_novel_packer/foundation/app.dart';
import 'package:bili_novel_packer/pages/home/search/search_result_page.dart';
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
  final GlobalKey<_SearchViewState> _searchViewKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    super.build(context);
    var breakPoint = App.breakPoint(context);
    var useSplitView = breakPoint > BreakPoint.sm;
    Widget searchView = _SearchView(key: _searchViewKey);
    searchView = useSplitView
        ? SizedBox(width: 375, child: searchView)
        : Expanded(child: searchView);
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          searchView,
          if (useSplitView) VerticalDivider(width: 1),
          if (useSplitView) SearchResultPage(),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _SearchView extends StatefulWidget {
  const _SearchView({super.key});

  @override
  State<StatefulWidget> createState() {
    return _SearchViewState();
  }
}

class _SearchViewState extends State<_SearchView>
    with AutomaticKeepAliveClientMixin {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    var colorScheme = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: SearchBar(
          controller: _controller,
          constraints: BoxConstraints(maxHeight: 56),
          trailing: [
            if (_controller.text.isNotEmpty)
              IconButton(
                onPressed: () {
                  _controller.clear();
                },
                icon: Icon(Icons.clear),
              ),
            IconButton(onPressed: () {}, icon: Icon(Icons.search)),
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
      body: Container(),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
