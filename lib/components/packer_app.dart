import 'package:bili_novel_packer/colors.dart';
import 'package:bili_novel_packer/components/novel_item.dart';
import 'package:bili_novel_packer/const.dart';
import 'package:bili_novel_packer/light_novel/base/light_novel_source.dart';
import 'package:nocterm/nocterm.dart';

class PackerApp extends StatefulComponent {
  @override
  State<StatefulComponent> createState() => _PackerAppState();
}

class _PackerAppState extends State<PackerApp> {
  List<NovelLink> links = [];
  List<NovelItem> items = [];
  List<WorkStatus> statuses = [];
  bool focused = true;
  dynamic errMsg;
  WorkMode mode = .manual;
  ScrollController scrollController = ScrollController();
  TextEditingController textController = TextEditingController();

  int get numberOfQueues {
    if (links.isEmpty) return 0;
    return links.length - items.length;
  }

  WorkStatus get status {
    if (items.isEmpty) return .idle;
    if (statuses.any((s) => s == .working)) return .working;
    if (statuses.every((s) => s == .complted || s == .error)) return .idle;
    return .idle;
  }

  NovelItem? get lastItem => items.lastOrNull;

  @override
  void dispose() {
    textController.dispose();
    scrollController.dispose();
  }

  @override
  Component build(BuildContext context) {
    return Column(
      mainAxisAlignment: .start,
      crossAxisAlignment: .stretch,
      children: [
        _title(),
        _wrapper(),
        _input(),
      ],
    );
  }

  Component _title() {
    return Padding(
      padding: EdgeInsets.all(1),
      child: Row(
        children: [
          Text("📚 Bili Novel Packer"),
          Text(" "),
          Text(
            "($version)",
            style: TextStyle(color: mutedColor),
          ),
        ],
      ),
    );
  }

  Component _wrapper() {
    if (items.isEmpty) {
      return Expanded(child: Container());
    }
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(left: 4, bottom: 1),
        child: ListView.separated(
          controller: scrollController,
          itemCount: items.length,
          itemBuilder: (context, index) {
            return Expanded(child: items[index]);
          },
          separatorBuilder: (context, index) {
            return SizedBox(height: 1);
          },
        ),
      ),
    );
  }

  Component _input() {
    return Column(
      crossAxisAlignment: .start,
      children: [
        Container(
          color: backgroundColor,
          padding: EdgeInsets.all(1),
          child: Row(
            children: [
              Text("› "),
              Expanded(
                child: TextField(
                  controller: textController,
                  showCursor: false,
                  focused: focused,
                  onKeyEvent: (event) {
                    if (event.logicalKey == LogicalKey.tab) {
                      toggleWorkMode();
                      return true;
                    }
                    if (event.logicalKey == LogicalKey.pageUp) {
                      scrollController.pageUp();
                      return true;
                    }
                    if (event.logicalKey == LogicalKey.pageDown) {
                      scrollController.pageDown();
                      return true;
                    }
                    return false;
                  },
                  placeholder: "请输入链接，多个链接使用空格分开",
                  onSubmitted: onSubmitted,
                  onChanged: (_) {
                    setState(() {
                      errMsg = null;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: 3),
          child: Text(
            errMsg ?? "",
            style: TextStyle(color: destructiveColor),
          ),
        ),
        // 状态栏
        Padding(
          padding: EdgeInsets.only(left: 3),
          child: Row(
            children: [
              Text(status.label),
              Text(
                "($numberOfQueues 在队列)",
                style: TextStyle(color: mutedColor),
              ),
              Text(" · "),
              Text(mode.label),
              Text(
                "(Tab 切换 | ${mode.desc})",
                style: TextStyle(color: mutedColor),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void toggleWorkMode() {
    setState(() {
      mode = mode == .manual ? .auto : .manual;
      items = items.map((item) => item.copyWith(mode: mode)).toList();
    });
  }

  void onSubmitted(String input) {
    try {
      var addLinks = _parse(input);
      textController.clear();
      setState(() {
        links.addAll(addLinks);
        workNext();
      });
    } catch (e) {
      setState(() {
        errMsg = e.toString();
      });
    }
  }

  void onStatusChanged(int idx, WorkStatus status) {
    setState(() {
      statuses[idx] = status;
    });
    workNext();
  }

  void onChildRequestFocus(bool requestFocus) {
    setState(() {
      focused = !requestFocus;
    });
  }

  void workNext() {
    if (links.isEmpty) {
      return;
    }
    if (links.length <= items.length) {
      return;
    }
    int? idx;
    if (links.isNotEmpty && items.isEmpty) {
      idx = 0;
    } else if (<WorkStatus>[.complted, .error].contains(statuses.lastOrNull)) {
      idx = items.length;
    }
    if (idx != null) {
      setState(() {
        statuses.add(.working);
        items.add(
          NovelItem(
            link: links[idx!],
            mode: mode,
            onStatusChanged: (s) {
              onStatusChanged(idx!, s);
            },
            onRequestFocus: (requestFocus) => onChildRequestFocus(requestFocus),
          ),
        );
        SchedulerBinding.instance.addPostFrameCallback((_) {
          scrollController.scrollToEnd();
        });
      });
    }
  }

  List<NovelLink> _parse(String value) {
    value = value.trim();
    var parts = value.split(RegExp("\\s+"));
    List<NovelLink> links = [];
    for (var url in parts) {
      url = url.trim();
      if (url.isEmpty) continue;
      var s = _detectSource(url);
      if (s == null) {
        throw "不支持此链接: $url";
      } else {
        links.add(NovelLink(url, s));
      }
    }
    return links;
  }

  LightNovelSource? _detectSource(String url) {
    for (var source in sources) {
      if (source.supportUrl(url)) {
        return source;
      }
    }
    return null;
  }
}

class NovelLink {
  const NovelLink(this.url, this.source);

  final String url;
  final LightNovelSource source;
}

enum WorkMode {
  manual("手动模式", "每次需手动选择参数"),
  auto("自动模式", "每次自动使用默认参数");

  const WorkMode(this.label, this.desc);

  final String label;
  final String desc;
}

enum WorkStatus {
  idle("空闲中"),
  working("工作中"),
  complted("已完成"),
  error("错误");

  const WorkStatus(this.label);
  final String label;
}

enum ProxyType {
  none,
  system,
  custom,
}

class ProxyConfig {
  const ProxyConfig(this.host, this.port);

  final String host;
  final int port;
}
