import 'package:flutter/material.dart';
import '../models/catalog_item.dart';
import '../services/api_service.dart';
import '../widgets/catalog_image.dart';
import 'detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ApiService api = ApiService();
  final TextEditingController controller = TextEditingController();

  List<CatalogItem> results = [];
  bool loading = false;

  Future<void> search(String query) async {
    setState(() => loading = true);

    final data = await api.searchItems(query);

    setState(() {
      results = data;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Buscar")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: "Buscar por título, descripción o categoría",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => search(controller.text),
                ),
              ),
              onSubmitted: search,
            ),
          ),
          if (loading) const LinearProgressIndicator(),
          Expanded(
            child: results.isEmpty && !loading
                ? const Center(child: Text("Busca algo para ver resultados"))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final item = results[index];

                      return Card(
                        clipBehavior: Clip.antiAlias,
                        margin: const EdgeInsets.only(bottom: 14),
                        child: ListTile(
                          leading: SizedBox(
                            width: 90,
                            child: CatalogImage(
                              imageUrl: item.image,
                              height: 70,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          title: Text(item.title),
                          subtitle: Text(item.description),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailScreen(item: item),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
