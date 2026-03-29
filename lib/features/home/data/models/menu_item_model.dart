class MenuItemModel {
  final String title;
  final String? url;
  final List<MenuItemModel> children;

  const MenuItemModel({
    required this.title,
    this.url,
    this.children = const [],
  });

  bool get hasChildren => children.isNotEmpty;

  factory MenuItemModel.fromMap(Map<String, dynamic> map) {
    final rawChildren = map['children'];
    return MenuItemModel(
      title: (map['title'] ?? '').toString(),
      url: map['url']?.toString(),
      children: rawChildren is List
          ? rawChildren
          .map((e) => MenuItemModel.fromMap(Map<String, dynamic>.from(e)))
          .toList()
          : const [],
    );
  }
}

class MenuSectionModel {
  final String title;
  final List<MenuItemModel> items;

  const MenuSectionModel({
    required this.title,
    required this.items,
  });

  factory MenuSectionModel.fromMap(Map<String, dynamic> map) {
    final rawItems = map['items'];
    return MenuSectionModel(
      title: (map['title'] ?? '').toString(),
      items: rawItems is List
          ? rawItems
          .map((e) => MenuItemModel.fromMap(Map<String, dynamic>.from(e)))
          .toList()
          : const [],
    );
  }
}