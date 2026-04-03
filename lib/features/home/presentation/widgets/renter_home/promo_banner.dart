import 'package:flutter/material.dart';

class RenterPromoBanner extends StatelessWidget {
  const RenterPromoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 20),
      height: 140,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF0F3460)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1A2E).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -30,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE8703A).withOpacity(0.15),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxHeight < 110;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 8 : 10,
                        vertical: compact ? 3 : 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8703A),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        'New User Offer',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: compact ? 10 : 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(height: compact ? 6 : 10),
                    Text(
                      'First Month Rent\nAssistance Available',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 16 : 18,
                        fontWeight: FontWeight.w800,
                        height: compact ? 1.15 : 1.2,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: compact ? 6 : 10),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 12 : 14,
                        vertical: compact ? 6 : 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Explore Now ->',
                        style: TextStyle(
                          color: const Color(0xFF1A1A2E),
                          fontSize: compact ? 11 : 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}