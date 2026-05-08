import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'config.dart';
import 'models/category.dart';
import 'models/catalog_item.dart';
import 'view_item.dart';

void main() {
  runApp(const CatalogApp());
}

class CatalogApp extends StatelessWidget {
  const CatalogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Catálogo Temático',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      routes: {
        '/': (_) => const CategoriesPage(),
        '/items': (_) => const ItemsPage(),
      },
    );
  }
}

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final TextEditingController _searchController = TextEditingController();

  List<Category> _categories = [];
  List<CatalogItem> _searchResults = [];
  bool _loadingCategories = true;
  bool _searching = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Carga las categorías desde el backend Node mediante HTTP GET.
  Future<void> _loadCategories() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/categories'));

      if (response.statusCode != 200) {
        throw Exception('Error al cargar categorías');
      }

      final List<dynamic> data = jsonDecode(response.body);

      setState(() {
        _categories = data.map((json) => Category.fromJson(json)).toList();
        _loadingCategories = false;
      });
    } catch (e) {
      setState(() {
        _error = 'No se pudo conectar con el servidor.';
        _loadingCategories = false;
      });
    }
  }

  // Envía el texto del buscador al endpoint /search y pinta los resultados.
  Future<void> _searchItems() async {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _searching = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/search'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'query': query}),
      );

      final List<dynamic> data = jsonDecode(response.body);

      setState(() {
        _searchResults = data.map((json) => CatalogItem.fromJson(json)).toList();
        _searching = false;
      });
    } catch (e) {
      setState(() => _searching = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo realizar la búsqueda')),
      );
    }
  }

  void _openItem(CatalogItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ItemDetailPage(item: item)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catálogo Temático')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              onSubmitted: (_) => _searchItems(),
              decoration: InputDecoration(
                labelText: 'Buscar en todo el catálogo',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchItems,
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_loadingCategories)
              const Center(child: CircularProgressIndicator())
            else if (_error.isNotEmpty)
              Text(_error, style: const TextStyle(color: Colors.red))
            else ...[
              const Text('Categorías', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _categories.map((category) {
                  return FilledButton.tonal(
                    onPressed: () {
                      Navigator.pushNamed(context, '/items', arguments: category);
                    },
                    child: Text(category.name),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 20),
            if (_searching)
              const Center(child: CircularProgressIndicator())
            else if (_searchResults.isNotEmpty) ...[
              const Text('Resultados de búsqueda', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final item = _searchResults[index];
                    return Card(
                      child: ListTile(
                        leading: Hero(
                          tag: 'item-image-${item.id}',
                          child: Image.network(buildImageUrl(item.image), width: 60, height: 60, fit: BoxFit.cover),
                        ),
                        title: Text(item.name),
                        subtitle: Text(item.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                        onTap: () => _openItem(item),
                      ),
                    );
                  },
                ),
              ),
            ] else
              const Text('Selecciona una categoría o escribe una búsqueda.'),
          ],
        ),
      ),
    );
  }
}

class ItemsPage extends StatefulWidget {
  const ItemsPage({super.key});

  @override
  State<ItemsPage> createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> {
  final ScrollController _scrollController = ScrollController();

  Category? _category;
  final List<CatalogItem> _items = [];
  int _page = 1;
  final int _pageSize = 6;
  int _total = 0;
  bool _loading = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_initialized) {
      _category = ModalRoute.of(context)!.settings.arguments as Category;
      _loadItems();
      _scrollController.addListener(_checkScrollPosition);
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Detecta cuándo el usuario llega casi al final de la lista.
  // En ese momento pide la siguiente página al servidor.
  void _checkScrollPosition() {
    final nearBottom = _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 150;

    if (nearBottom && !_loading && _items.length < _total) {
      _page++;
      _loadItems();
    }
  }

  // Carga una página de items de la categoría seleccionada.
  // La paginación evita cargar todos los datos de golpe.
  Future<void> _loadItems() async {
    setState(() => _loading = true);

    try {
      final uri = Uri.parse(
        '$baseUrl/items?categoryId=${_category!.id}&page=$_page&pageSize=$_pageSize',
      );

      final response = await http.get(uri);
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic> rawItems = data['items'];

      setState(() {
        _total = data['total'];
        _items.addAll(rawItems.map((json) => CatalogItem.fromJson(json)));
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cargar items')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_category?.name ?? 'Items')),
      body: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        itemCount: _items.length + (_loading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final item = _items[index];

          return Card(
            child: ListTile(
              leading: Hero(
                tag: 'item-image-${item.id}',
                child: Image.network(buildImageUrl(item.image), width: 70, height: 70, fit: BoxFit.cover),
              ),
              title: Text(item.name),
              subtitle: Text(item.description, maxLines: 2, overflow: TextOverflow.ellipsis),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ItemDetailPage(item: item)),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
