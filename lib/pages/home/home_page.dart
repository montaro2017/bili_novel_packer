import 'package:bili_novel_packer/foundation/app.dart';
import 'package:bili_novel_packer/pages/home/download/download_page.dart';
import 'package:bili_novel_packer/pages/home/explore/explore_page.dart';
import 'package:bili_novel_packer/pages/home/search/search_page.dart';
import 'package:bili_novel_packer/pages/home/settings/settings_page.dart';
import 'package:flutter/material.dart';

final List<_NavigationItem> _items = [
  _NavigationItem(Icons.explore, "探索", ExplorePage()),
  _NavigationItem(Icons.search, "搜索", SearchPage()),
  _NavigationItem(Icons.download_done, "下载", DownloadPage()),
  _NavigationItem(Icons.settings, "设置", SettingsPage()),
];

final List<NavigationDestination> _navigationDestinations = _items
    .map((item) => item.navigationDestination)
    .toList();
final List<NavigationRailDestination> _navigationRailDestinations = _items
    .map((item) => item.navigationRailDestination)
    .toList();

final List<Widget> _widgets = _items.map((item) => item.widget).toList();

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _HomePageState();
  }
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var breakPoint = App.breakPoint(context);
    bool mobileLayout = breakPoint < BreakPoint.sm;
    return Scaffold(
      bottomNavigationBar: mobileLayout ? _navigationBar() : null,
      body: Row(
        children: [
          if (!mobileLayout)
            Row(
              children: [
                NavigationRail(
                  destinations: _navigationRailDestinations,
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _setSelectedIndex,
                  labelType: .all,
                ),
                VerticalDivider(thickness: 1, width: 1),
              ],
            ),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: _widgets,
            ),
          ),
        ],
      ),
    );
  }

  Widget _navigationBar() {
    return NavigationBar(
      destinations: _navigationDestinations,
      selectedIndex: _selectedIndex,
      onDestinationSelected: _setSelectedIndex,
    );
  }

  void _setSelectedIndex(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}

class _NavigationItem {
  final IconData icon;
  final String label;

  final Widget widget;

  const _NavigationItem(this.icon, this.label, this.widget);

  NavigationDestination get navigationDestination =>
      NavigationDestination(icon: Icon(icon), label: label);

  NavigationRailDestination get navigationRailDestination =>
      NavigationRailDestination(icon: Icon(icon), label: Text(label));
}
