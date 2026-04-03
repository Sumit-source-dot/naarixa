import 'package:flutter/material.dart';

import '../../../../shared/models/accommodation_property.dart';

class PropertyDetailScreen extends StatelessWidget {
  const PropertyDetailScreen({required this.property, super.key});

  final AccommodationProperty property;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Property Details')),
      body: ListView(
        children: [
          AspectRatio(
            aspectRatio: 16 / 10,
            child: Image.network(
              property.imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const Center(child: CircularProgressIndicator(strokeWidth: 2));
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFFF1F3F5),
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image_outlined, size: 34, color: Color(0xFF6C757D)),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  property.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(property.priceLabel),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.place_outlined),
                    const SizedBox(width: 6),
                    Expanded(child: Text('${property.location}, ${property.city}')),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber),
                    const SizedBox(width: 6),
                    Text('Safety rating: ${property.safetyRating.toStringAsFixed(1)}'),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Demo detail screen for future advanced rental view (amenities, map, filters, booking).',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}