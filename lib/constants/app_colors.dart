import 'package:flutter/material.dart';

class AppColors {
  // Brand & Accents
  static const Color primary = Color(0xFF10B981); // Emerald
  static const Color primaryDark = Color(0xFF059669);
  static const Color primaryLight = Color(0xFF34D399);

  // Status Colors
  static const Color win = Color(0xFF10B981);
  static const Color winBg = Color(0x2610B981); // 15% opacity
  static const Color winText = Color(0xFF059669);

  static const Color lose = Color(0xFFEF4444);
  static const Color loseBg = Color(0x24EF4444); // 14% opacity
  static const Color loseText = Color(0xFFEF4444);

  static const Color be = Color(0xFFD97706); // Break Even (Amber)
  static const Color beBg = Color(0x29D97706); // 16% opacity
  static const Color beText = Color(0xFFD97706);

  // Light Theme
  static const Color lightBg = Color(0xFFF3F5F9);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF0D1B2A);
  static const Color lightMuted = Color(0xFF6B7A90);
  static const Color lightBorder = Color(0xFFE5E9F0);
  static const Color lightSoft = Color(0xFFEEF2F7);

  // Dark Theme
  static const Color darkBg = Color(0xFF0A111C);
  static const Color darkCard = Color(0xFF121B2B);
  static const Color darkText = Color(0xFFE8EDF5);
  static const Color darkMuted = Color(0xFF8B9AB0);
  static const Color darkBorder = Color(0xFF1F2B40);
  static const Color darkSoft = Color(0xFF1A2539);

  // Hero Card Gradient
  static const List<Color> heroGradient = [
    Color(0xFF0B1B2B),
    Color(0xFF0E3B36),
  ];
  static const Color heroSubtitle = Color(0xFF8FE3C3);
  static const Color heroLabel = Color(0xFF9FB4C4);
}
