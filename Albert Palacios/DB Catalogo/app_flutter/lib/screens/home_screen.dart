import 'package:flutter/material.dart';
import '../models/category.dart';
import '../services/api_service.dart';
import 'items_screen.dart';
import 'search_screen.dart';

/// Pantalla principal de la aplicación.
///
/// Carga la lista de categorías y permite navegar a los items de cada una.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService api = ApiService();
  late Future<List<Category>> categoriesFuture;

  @override
  void initState() {
    super.initState();
    categoriesFuture = api.getCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Catálogo Real"),
        actions: [
          IconButton(
            tooltip: "Buscar",
            icon: const Icon(Icons.search),
            onPressed: () {
              // Abre la pantalla de búsqueda.
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Category>>(
        future: categoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Muestra un loader mientras se obtienen las categorías.
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            // Mensaje de error si la API no responde.
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  "No se pudo conectar con el servidor.\n\n${snapshot.error}",
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final categories = snapshot.data ?? [];

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 14),
                child: ListTile(
                  title: Text(category.name),
                  subtitle: Text(category.description),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Navega a la pantalla de items de esta categoría.
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ItemsScreen(category: category),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
