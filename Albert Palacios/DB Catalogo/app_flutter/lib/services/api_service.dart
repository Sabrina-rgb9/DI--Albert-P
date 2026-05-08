import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/category.dart';
import '../models/catalog_item.dart';

// Servicio centralizado para conectar Flutter con el backend Node.
//
// Todas las llamadas a la API del catálogo se agrupan aquí, de modo que
// el resto de la app puede pedir datos sin preocuparse por los detalles
// de las peticiones HTTP.
class ApiService {
  /// Obtiene la lista de categorías desde el backend.
  ///
  /// Llama a la ruta `/categories` y convierte la respuesta JSON
  /// en una lista de objetos `Category`.
  Future<List<Category>> getCategories() async {
    final response = await http.get(Uri.parse("$baseUrl/categories"));

    if (response.statusCode != 200) {
      // Si el servidor devuelve un error, lanzamos una excepción.
      throw Exception("Error cargando categorías");
    }

    final List data = jsonDecode(response.body);
    return data.map((json) => Category.fromJson(json)).toList();
  }

  /// Obtiene los items de una categoría concreta.
  ///
  /// Envía el parámetro `categoryId` en la URL como query string y devuelve
  /// una lista de `CatalogItem` creada a partir de la respuesta JSON.
  Future<List<CatalogItem>> getItemsByCategory(int categoryId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/items?categoryId=$categoryId"),
    );

    if (response.statusCode != 200) {
      throw Exception("Error cargando items");
    }

    final List data = jsonDecode(response.body);
    return data.map((json) => CatalogItem.fromJson(json)).toList();
  }

  /// Busca items que coincidan con la consulta del usuario.
  ///
  /// Envía un POST a `/search` con el texto de búsqueda en el cuerpo.
  /// Devuelve una lista de `CatalogItem` con los resultados.
  Future<List<CatalogItem>> searchItems(String query) async {
    final response = await http.post(
      Uri.parse("$baseUrl/search"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"query": query}),
    );

    if (response.statusCode != 200) {
      throw Exception("Error buscando items");
    }

    final List data = jsonDecode(response.body);
    return data.map((json) => CatalogItem.fromJson(json)).toList();
  }
}
