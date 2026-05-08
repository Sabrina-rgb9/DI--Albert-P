import 'package:flutter/material.dart';

import 'config.dart';
import 'models/catalog_item.dart';

class ItemDetailPage extends StatelessWidget {
  final CatalogItem item;

  const ItemDetailPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    // Reutilizamos la función de config.dart para aceptar imágenes locales o URLs reales.
    final imageUrl = buildImageUrl(item.image);

    return Scaffold(
      appBar: AppBar(title: Text(item.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Hero(
                tag: 'item-image-${item.id}',
                child: // InteractiveViewer permite hacer zoom y mover la imagen en la pantalla de detalle.
                InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Image.network(
                    imageUrl,
                    width: double.infinity,
                    height: 260,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(item.name, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            Text(item.description, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 24),
            Text('ID: ${item.id} · Categoría: ${item.categoryId}'),
          ],
        ),
      ),
    );
  }
}
