import 'package:flutter/material.dart';

import 'section_header.dart';

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key});

  static const _actions = [
    {
      'icon': Icons.add_home_outlined,
      'label': 'List Property',
      'color': Color(0xFF6366F1),
      'bg': Color(0xFFEDE9FE),
    },
    {
      'icon': Icons.chat_bubble_outline_rounded,
      'label': 'Messages',
      'color': Color(0xFF10B981),
      'bg': Color(0xFFD1FAE5),
    },
    {
      'icon': Icons.bar_chart_rounded,
      'label': 'Analytics',
      'color': Color(0xFFE8703A),
      'bg': Color(0xFFFFF4EE),
    },
    {
      'icon': Icons.verified_user_outlined,
      'label': 'Verify Tenant',
      'color': Color(0xFFF59E0B),
      'bg': Color(0xFFFEF3C7),
    },
    {
      'icon': Icons.receipt_long_outlined,
      'label': 'Leases',
      'color': Color(0xFF3B82F6),
      'bg': Color(0xFFDBEAFE),
    },
    {
      'icon': Icons.support_agent_outlined,
      'label': 'Support',
      'color': Color(0xFF8B5CF6),
      'bg': Color(0xFFF3E8FF),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SectionHeader(title: 'Quick Actions', actionLabel: null),
          const SizedBox(height: 12),
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: _actions.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.1,
            ),
            itemBuilder: (context, i) {
              final a = _actions[i];
              return GestureDetector(
                onTap: () {},
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: a['bg'] as Color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          a['icon'] as IconData,
                          color: a['color'] as Color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        a['label'] as String,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A2E),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
