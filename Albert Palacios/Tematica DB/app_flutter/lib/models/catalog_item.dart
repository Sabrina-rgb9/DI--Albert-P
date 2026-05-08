// Modelo de cada elemento del catálogo.
// Cada item pertenece a una categoría mediante categoryId.
class CatalogItem {
  final int id;
  final int categoryId;
  final String name;
  final String description;
  final String image;

  CatalogItem({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.image,
  });

  factory CatalogItem.fromJson(Map<String, dynamic> json) {
    return CatalogItem(
      id: json['id'],
      categoryId: json['categoryId'],
      name: json['name'],
      description: json['description'],
      image: json['image'],
    );
  }
}
