import 'package:flutter/material.dart';

/// Application color palette - ChatGPT-EXACT dark theme
/// All hex values match ChatGPT UI precisely
class AppColors {
  AppColors._();

  // ═══════════════════════════════════════════════════════════════
  //                    CHATGPT EXACT COLOR SYSTEM
  // ═══════════════════════════════════════════════════════════════

  // === BACKGROUNDS ===
  static const Color background = Color(0xFF000000);           // Pure black main bg
  static const Color backgroundMain = Color(0xFF000000);       // Alias
  static const Color surface = Color(0xFF1A1A1A);              // Cards, AI bubbles
  static const Color surfaceVariant = Color(0xFF1E1E1E);       // Input fields, buttons
  static const Color surfaceElevated = Color(0xFF2E2E2E);      // Elevated surfaces
  static const Color sidebarBackground = Color(0xFF000000);    // Sidebar bg (same as main)

  // === BORDERS & DIVIDERS ===
  static const Color border = Color(0xFF2E2E2E);               // Primary dividers
  static const Color borderLight = Color(0xFF3E3E3E);          // Hover states, subtle
  static const Color borderSubtle = Color(0xFF2E2E2E);         // Alias

  // === BRAND COLORS ===
  static const Color primary = Color(0xFF10A37F);              // ChatGPT green
  static const Color primaryDark = Color(0xFF0D8A6A);          // Darker green
  static const Color secondary = Color(0xFF9333EA);            // Purple accent
  static const Color secondaryLight = Color(0xFFA855F7);       // Light purple
  
  // === ACCENT COLORS ===
  static const Color accent = Color(0xFF10A37F);               // Same as primary
  static const Color accentBlue = Color(0xFF0084FF);           // Send button blue
  static const Color danger = Color(0xFFFF4444);               // Danger/error red
  static const Color warning = Color(0xFFF59E0B);              // Warning orange
  static const Color success = Color(0xFF10B981);              // Success green
  static const Color info = Color(0xFF3B82F6);                 // Info blue

  // === TEXT COLORS ===
  static const Color textPrimary = Color(0xFFFFFFFF);          // Pure white
  static const Color textSecondary = Color(0xFFA0A0A0);        // Gray secondary
  static const Color textMuted = Color(0xFF707070);            // Placeholder text
  static const Color textTertiary = Color(0xFF888888);         // Very subtle

  // Legacy aliases
  static const Color primaryText = Color(0xFFFFFFFF);
  static const Color secondaryText = Color(0xFFA0A0A0);
  static const Color textLight = Color(0xFF111827);
  static const Color textDark = Color(0xFFE5E7EB);

  // === CHAT BUBBLES ===
  static const Color userBubble = Color(0xFF2E2E2E);           // User message bg
  static const Color userBubbleDark = Color(0xFF2E2E2E);       // Alias
  static const Color aiBubble = Colors.transparent;             // AI message (transparent)
  static const Color aiBubbleDark = Colors.transparent;         // Alias
  static const Color userBubbleLight = Color(0xFFF0F0F0);      // Light theme user
  static const Color aiBubbleLight = Colors.white;              // Light theme AI

  // === INPUT BAR ===
  static const Color inputBackground = Color(0xFF2E2E2E);      // Input field bg
  static const Color inputBorder = Color(0xFF3E3E3E);          // Input border

  // === QUICK ACTION CHIP COLORS ===
  static const Color chipGreen = Color(0xFF10B981);            // Create image
  static const Color chipOrange = Color(0xFFF59E0B);           // Summarize text
  static const Color chipPurple = Color(0xFFA855F7);           // Code
  static const Color chipBlue = Color(0xFF3B82F6);             // Analyze data
  static const Color chipPink = Color(0xFFC084FC);             // Analyze images
  static const Color chipGray = Color(0xFF6B7280);             // More

  // === SIDEBAR ===
  static const Color sidebarHover = Color(0xFF1E1E1E);         // Hover state
  static const Color sidebarActive = Color(0xFF2E2E2E);        // Active/selected

  // === CODE BLOCKS ===
  static const Color codeBackground = Color(0xFF0D0D0D);       // Code block body
  static const Color codeHeader = Color(0xFF1A1A1A);           // Code block header

  // === TOGGLE SWITCH ===
  static const Color toggleTrackOff = Color(0xFF3E3E3E);       // Track when off
  static const Color toggleTrackOn = Color(0xFF10A37F);        // Track when on
  static const Color toggleThumb = Color(0xFFFFFFFF);          // Thumb (always white)

  // === VOICE INPUT ===
  static const Color waveformPurple = Color(0xFF9333EA);       // Recording waveform
  static const Color waveformGray = Color(0xFF3E3E3E);         // Static waveform

  // === SPECIAL ===

  static const Color error = Color(0xFFEF4444);                // Error state
  static const Color avatarOrange = Color(0xFFE87D3E);         // Default avatar

  // === GRADIENTS ===
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [secondary, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // === LIGHT THEME ===
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF9F9F9);         // Slightly off-white for cards
  static const Color surfaceElevatedLight = Color(0xFFFFFFFF); // White for dropdowns/modals
  static const Color dividerLight = Color(0xFFE5E5E5);
  static const Color textPrimaryLight = Color(0xFF0D0D0D);     // Near black
  static const Color textSecondaryLight = Color(0xFF6B7280);   // Gray 500
  static const Color borderLightMode = Color(0xFFE5E5E5);      // Light mode borders
  static const Color inputBackgroundLight = Color(0xFFFFFFFF); // White input
  static const Color sidebarBackgroundLight = Color(0xFFF9F9F9); // Light sidebar

  // === DIVIDERS ===
  static const Color dividerDark = Color(0xFF2E2E2E);
  
  // === SETTINGS ===
  static const Color settingsCard = Color(0xFF2E2E2E);         // Settings card bg

  // ═══════════════════════════════════════════════════════════════
  //                    LEGACY ALIASES (for backward compatibility)
  // ═══════════════════════════════════════════════════════════════
  
  static const Color backgroundDark = Color(0xFF000000);        // Alias for background
  static const Color surfaceDark = Color(0xFF1A1A1A);           // Alias for surface
  static const Color surfaceDarkElevated = Color(0xFF2E2E2E);   // Alias for surfaceElevated
  static const Color hoverBackground = Color(0x0AFFFFFF);       // rgba(255,255,255,0.04)
  static const Color chipYellow = Color(0xFFEAB308);            // Yellow chip
  static const Color chipCyan = Color(0xFF06B6D4);              // Cyan chip
  static const Color chipRed = Color(0xFFEF4444);               // Red chip
  static const Color waveformWhite = Color(0xD9FFFFFF);         // ~85% opacity white
  static const Color privateSpace = Color(0xFF9333EA);          // Private space accent (purple)
}
