import 'package:flutter/material.dart';

import '../providers/accommodation_provider.dart';

class OwnerPropertyDetailScreen extends StatefulWidget {
  const OwnerPropertyDetailScreen({required this.property, super.key});

  final OwnerProperty property;

  @override
  State<OwnerPropertyDetailScreen> createState() => _OwnerPropertyDetailScreenState();
}

class _OwnerPropertyDetailScreenState extends State<OwnerPropertyDetailScreen> {
  late PageController _pageController;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final property = widget.property;
    final hasImages = property.images.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Property Details'),
        elevation: 0,
      ),
      body: ListView(
        children: [
          // Image Gallery
          if (hasImages)
            Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentImageIndex = index);
                  },
                  itemCount: property.images.length,
                  itemBuilder: (context, index) {
                    return AspectRatio(
                      aspectRatio: 16 / 10,
                      child: Image.network(
                        property.images[index],
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFFF1F3F5),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.broken_image_outlined,
                              size: 34,
                              color: Color(0xFF6C757D),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                // Image Counter
                if (property.images.length > 1)
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${_currentImageIndex + 1}/${property.images.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            )
          else
            AspectRatio(
              aspectRatio: 16 / 10,
              child: Container(
                color: const Color(0xFFF1F3F5),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.home_outlined,
                  size: 34,
                  color: Color(0xFF6C757D),
                ),
              ),
            ),
          // Details Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + Badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        property.title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    if (property.verificationStatus == 1)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6F7EF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          'Verified',
                          style: TextStyle(
                            color: Color(0xFF1E7D4F),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Price
                Text(
                  'INR ${property.budget.toStringAsFixed(0)} / month',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2F9E44),
                      ),
                ),
                const SizedBox(height: 16),
                // Location + Rating
                Row(
                  children: [
                    const Icon(Icons.place_outlined),
                    const SizedBox(width: 6),
                    Expanded(child: Text(property.location)),
                  ],
                ),
                const SizedBox(height: 8),
                if (property.safetyScore > 0)
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber),
                      const SizedBox(width: 6),
                      Text('Safety Score: ${property.safetyScore}'),
                    ],
                  ),
                const SizedBox(height: 16),
                // Property Details Grid
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      if (property.propertyType.isNotEmpty)
                        _DetailRow(
                          label: 'Property Type',
                          value: property.propertyType,
                        ),
                      if (property.bedrooms != null)
                        _DetailRow(
                          label: 'Bedrooms',
                          value: '${property.bedrooms}',
                        ),
                      if (property.bathrooms != null)
                        _DetailRow(
                          label: 'Bathrooms',
                          value: '${property.bathrooms}',
                        ),
                      if (property.area != null)
                        _DetailRow(
                          label: 'Area',
                          value: '${property.area} sq.ft',
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Features
                if (property.womenFriendly || property.isActive)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Features',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (property.womenFriendly)
                            _FeatureChip(label: '👩 Women Friendly'),
                          if (property.isActive)
                            _FeatureChip(label: '✓ Active'),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                // Amenities
                if (property.amenities.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Amenities',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: property.amenities
                            .map((amenity) => _AmenityChip(label: amenity))
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                // Description
                if (property.description.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Description',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        property.description,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF6C757D),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F7EF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF1E7D4F),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _AmenityChip extends StatelessWidget {
  const _AmenityChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE7F5FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF1971C2),
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }
}
