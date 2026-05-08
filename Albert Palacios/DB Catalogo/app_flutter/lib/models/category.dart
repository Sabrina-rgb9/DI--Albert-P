// Modelo de una categoría.
// Sirve para convertir el JSON que llega del servidor en un objeto Dart.
class Category {
  final int id;
  final String name;

  Category({required this.id, required this.name});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
    );
  }
}
