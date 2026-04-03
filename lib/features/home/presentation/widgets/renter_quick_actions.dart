import 'package:flutter/material.dart';

import 'section_header.dart';

class RenterQuickActions extends StatelessWidget {
  const RenterQuickActions({super.key});

  static const _items = [
    {
      'icon': Icons.favorite_border,
      'label': 'Saved',
      'color': Color(0xFFEF4444),
      'bg': Color(0xFFFEE2E2),
    },
    {
      'icon': Icons.chat_bubble_outline,
      'label': 'Chats',
      'color': Color(0xFF10B981),
      'bg': Color(0xFFD1FAE5),
    },
    {
      'icon': Icons.description_outlined,
      'label': 'Applications',
      'color': Color(0xFF6366F1),
      'bg': Color(0xFFE0E7FF),
    },
    {
      'icon': Icons.history,
      'label': 'Visits',
      'color': Color(0xFFF59E0B),
      'bg': Color(0xFFFEF3C7),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SectionHeader(title: 'User Tools', actionLabel: null),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.3,
            ),
            itemBuilder: (context, index) {
              final item = _items[index];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: item['bg'] as Color,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        item['icon'] as IconData,
                        color: item['color'] as Color,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item['label'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
