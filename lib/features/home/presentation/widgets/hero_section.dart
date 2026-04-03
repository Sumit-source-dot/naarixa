import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class HeroSectionWidget extends StatelessWidget {
  const HeroSectionWidget({
    required this.userName,
    required this.isSafeZone,
    super.key,
  });

  final String userName;
  final bool isSafeZone;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 270,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            'https://static.vecteezy.com/system/resources/thumbnails/035/349/047/small_2x/ai-generated-a-girl-in-a-business-attire-posing-on-gray-background-free-photo.jpg',
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const ColoredBox(
                color: Color(0x1AFFFFFF),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: const Color(0xFF0B5D7A),
                alignment: Alignment.center,
                child: const Icon(Icons.image_not_supported_outlined, color: Colors.white70, size: 36),
              );
            },
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x66000000),
                  Color(0xBF0B5D7A),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Hi $userName',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Naarixa',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Text(
                  'Live a New Era',
                  style: TextStyle(
                    color: Color(0xFFF2F7FA),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your safety, your freedom',
                  style: TextStyle(
                    color: Color(0xFFE4EDF2),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  isSafeZone ? 'Safe Zone' : 'Risk Zone',
                  style: TextStyle(
                    color: isSafeZone ? AppColors.success : AppColors.danger,
                    fontWeight: FontWeight.w700,
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