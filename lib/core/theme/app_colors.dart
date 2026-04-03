import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // 🌌 Background - soft premium gradient base (not boring white)
  static const Color background = Color(0xFFF4F6FB);

  // 🧾 Cards & surfaces
  static const Color surface = Color(0xFFFFFFFF);

  // 🟣 Primary - Deep Royal Purple (empowerment + premium feel)
  static const Color primary = Color(0xFF6C4AB6);

  // 🔵 Secondary - Trust Blue (security + calmness)
  static const Color secondary = Color(0xFF4A90E2);

  // 🌸 Accent - Soft Pink Glow (warmth + feminine touch, not childish)
  static const Color accent = Color(0xFFFF6F91);

  // 🚨 Danger / SOS - Bright Alert Red (high visibility)
  static const Color danger = Color(0xFFFF3B3B);

  // ✅ Success - Safe Green (clear safety signal)
  static const Color success = Color(0xFF2ECC71);

  // 📝 Text colors (modern dark UI readability)
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6C757D);

  // 🔲 Borders (soft, not harsh)
  static const Color border = Color(0xFFE3E8F0);

  // 🌟 Optional Gradient (for buttons / hero sections)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [
      Color(0xFF6C4AB6), // purple
      Color(0xFF4A90E2), // blue
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // 💖 Accent Gradient (for highlights / cards)
  static const LinearGradient accentGradient = LinearGradient(
    colors: [
      Color(0xFFFF6F91), // pink
      Color(0xFFFF9671), // soft orange-pink
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // 🔁 Legacy aliases (for compatibility)
  static const Color button = primary;
  static const Color sos = danger;
  static const Color safe = success;
  static const Color card = surface;
  static const Color cardShadow = Color(0x14000000);
}