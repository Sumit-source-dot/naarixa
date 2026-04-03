import 'package:flutter/material.dart';

class RenterHowItWorks extends StatelessWidget {
  const RenterHowItWorks({super.key});

  static const _steps = [
    {
      'icon': Icons.search_rounded,
      'title': 'Search',
      'desc': 'Find verified properties near you',
      'color': Color(0xFF6366F1),
      'bg': Color(0xFFEDE9FE),
    },
    {
      'icon': Icons.calendar_today_outlined,
      'title': 'Schedule',
      'desc': 'Book a visit at your convenience',
      'color': Color(0xFF10B981),
      'bg': Color(0xFFD1FAE5),
    },
    {
      'icon': Icons.home_outlined,
      'title': 'Move In',
      'desc': 'Sign digitally and get keys',
      'color': Color(0xFFE8703A),
      'bg': Color(0xFFFFF4EE),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth < 360 ? 150.0 : 170.0;

    return SizedBox(
      height: 170,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _steps.length,
        separatorBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Icon(Icons.arrow_forward, size: 14, color: Colors.grey.shade300),
        ),
        itemBuilder: (context, i) {
          final s = _steps[i];
          return SizedBox(
            width: cardWidth,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: s['bg'] as Color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      s['icon'] as IconData,
                      color: s['color'] as Color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s['title'] as String,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    s['desc'] as String,
                    style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                    textAlign: TextAlign.center,
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
