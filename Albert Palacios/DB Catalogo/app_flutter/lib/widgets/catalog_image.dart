import 'package:flutter/material.dart';

// Widget para pintar imágenes reales de internet con loading y fallback.
class CatalogImage extends StatelessWidget {
  final String imageUrl;
  final double height;
  final BorderRadius borderRadius;

  const CatalogImage({
    super.key,
    required this.imageUrl,
    this.height = 180,
    this.borderRadius = const BorderRadius.vertical(top: Radius.circular(16)),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Image.network(
        imageUrl,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;

          return Container(
            height: height,
            alignment: Alignment.center,
            color: Colors.grey.shade200,
            child: const CircularProgressIndicator(),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: height,
            alignment: Alignment.center,
            color: Colors.grey.shade300,
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, size: 42),
                SizedBox(height: 8),
                Text("No se pudo cargar la imagen"),
              ],
            ),
          );
        },
      ),
    );
  }
}
