import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/category.dart';
import '../models/catalog_item.dart';

// Servicio centralizado para conectar Flutter con el backend Node.
class ApiService {
  Future<List<Category>> getCategories() async {
    final response = await http.get(Uri.parse("$baseUrl/categories"));

    if (response.statusCode != 200) {
      throw Exception("Error cargando categorías");
    }

    final List data = jsonDecode(response.body);
    return data.map((json) => Category.fromJson(json)).toList();
  }

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
