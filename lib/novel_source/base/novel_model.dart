class Novel {
  // id
  late String id;

  late String url;

  // 书名
  late String title;

  // 别名
  String? alias;

  // 作者
  String? author;

  // 连载状态
  String? status;

  // 封面图片
  String? coverUrl;

  // 标签
  List<String>? tags;

  // 文库
  String? publisher;

  // 简介
  String? description;
}

class Catalog {
  List<Volume> volumes = [];
}

class Volume {
  dynamic id;
  late String name;
  String? coverUrl;
  List<Chapter> chapters = [];

  Volume({this.id});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Volume &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          id == other.id;

  @override
  int get hashCode => Object.hash(id, name);
}

class Chapter {
  dynamic id;
  String name;

  Chapter({
    required this.name,
    this.id,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Chapter &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => [name, id].hashCode;
}

class NovelSection {
  String? name;
  List<Novel> novels;

  NovelSection([this.name, this.novels = const []]);
}
