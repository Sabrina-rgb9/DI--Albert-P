class CatalogItem {
  final int id;
  final String title;
  final String description;
  final int categoryId;
  final String image;

  CatalogItem({
    required this.id,
    required this.title,
    required this.description,
    required this.categoryId,
    required this.image,
  });

  factory CatalogItem.fromJson(Map<String, dynamic> json) {
    return CatalogItem(
      id: json["id"],
      title: json["title"],
      description: json["description"],
      categoryId: json["categoryId"],
      image: json["image"],
    );
  }
}
