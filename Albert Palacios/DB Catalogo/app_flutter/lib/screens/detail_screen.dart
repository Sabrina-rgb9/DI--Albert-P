import 'package:flutter/material.dart';
import '../models/catalog_item.dart';
import '../widgets/catalog_image.dart';

/// Pantalla de detalle que muestra la información completa de un item.
///
/// Recibe un `CatalogItem` y muestra su imagen, título, descripción y una
/// vista con zoom de la imagen.
class DetailScreen extends StatelessWidget {
  final CatalogItem item;

  const DetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar con el título del item.
      appBar: AppBar(title: Text(item.title)),
      body: ListView(
        children: [
          // Hero para animar la transición desde la lista de items.
          Hero(
            tag: "item-${item.id}",
            child: CatalogImage(
              imageUrl: item.image,
              height: 330,
              borderRadius: BorderRadius.zero,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título del item.
                Text(
                  item.title,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                // Descripción del item.
                Text(
                  item.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                const Text(
                  "Imagen con zoom",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                // Imagen ampliable con InteractiveViewer.
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 280,
                    child: InteractiveViewer(
                      minScale: 1,
                      maxScale: 4,
                      child: Image.network(
                        item.image,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
