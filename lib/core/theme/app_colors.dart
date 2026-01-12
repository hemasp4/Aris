import 'package:flutter/material.dart';

/// Application color palette
class AppColors {
  AppColors._();

  // Primary colors
  static const Color primary = Color(0xFF4F46E5);  // Indigo
  static const Color primaryDark = Color(0xFF7C3AED);  // Purple
  static const Color secondary = Color(0xFF06B6D4);  // Cyan
  static const Color secondaryDark = Color(0xFF22D3EE);

  // Background colors
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF111827);

  // Surface colors
  static const Color surfaceLight = Color(0xFFF9FAFB);
  static const Color surfaceDark = Color(0xFF1F2937);

  // Text colors
  static const Color textLight = Color(0xFF111827);
  static const Color textDark = Color(0xFFF9FAFB);
  static const Color textMuted = Color(0xFF6B7280);

  // State colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Chat bubble colors
  static const Color userBubbleLight = Color(0xFF4F46E5);
  static const Color userBubbleDark = Color(0xFF7C3AED);
  static const Color aiBubbleLight = Color(0xFFF3F4F6);
  static const Color aiBubbleDark = Color(0xFF374151);

  // Gradient definitions
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [secondary, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
