import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/catalog_item.dart';
import '../services/api_service.dart';
import '../widgets/catalog_image.dart';
import 'detail_screen.dart';

class ItemsScreen extends StatefulWidget {
  final Category category;

  const ItemsScreen({super.key, required this.category});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  final ApiService api = ApiService();
  final ScrollController scrollController = ScrollController();

  List<CatalogItem> allItems = [];
  List<CatalogItem> visibleItems = [];
  bool loading = true;

  int visibleCount = 0;
  final int pageSize = 3;

  @override
  void initState() {
    super.initState();
    loadItems();
    scrollController.addListener(handleScroll);
  }

  Future<void> loadItems() async {
    final items = await api.getItemsByCategory(widget.category.id);

    setState(() {
      allItems = items;
      visibleCount = pageSize;
      visibleItems = allItems.take(visibleCount).toList();
      loading = false;
    });
  }

  // Scroll infinito simple: va mostrando más elementos al llegar abajo.
  void handleScroll() {
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 80) {
      if (visibleCount < allItems.length) {
        setState(() {
          visibleCount += pageSize;
          visibleItems = allItems.take(visibleCount).toList();
        });
      }
    }
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.category.name)),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: visibleItems.length,
              itemBuilder: (context, index) {
                final item = visibleItems[index];

                return Card(
                  clipBehavior: Clip.antiAlias,
                  margin: const EdgeInsets.only(bottom: 18),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetailScreen(item: item),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Hero(
                          tag: "item-${item.id}",
                          child: CatalogImage(imageUrl: item.image),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 6),
                              Text(item.description),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
