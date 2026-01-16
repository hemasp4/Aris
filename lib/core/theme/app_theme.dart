import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Application theme configuration - ChatGPT-EXACT
/// All dimensions, fonts, and styling match ChatGPT precisely
class AppTheme {
  AppTheme._();

  // ═══════════════════════════════════════════════════════════════
  //                    TYPOGRAPHY CONSTANTS
  // ═══════════════════════════════════════════════════════════════

  // Font sizes (sp)
  static const double displayLargeSize = 28;
  static const double displayMediumSize = 24;
  static const double titleLargeSize = 20;
  static const double titleMediumSize = 18;
  static const double bodyLargeSize = 16;
  static const double bodyMediumSize = 14;
  static const double labelSmallSize = 12;

  // Line heights
  static const double displayLineHeight = 1.2;
  static const double titleLineHeight = 1.3;
  static const double bodyLineHeight = 1.5;
  static const double labelLineHeight = 1.4;

  // Message text (ChatGPT-exact)
  static const double messageTextSize = 16;
  static const double messageLineHeight = 1.5;

  // ═══════════════════════════════════════════════════════════════
  //                    TEXT STYLES
  // ═══════════════════════════════════════════════════════════════

  /// Message text style (Inter, 16sp, 1.5 line height)
  static TextStyle get messageTextStyle => GoogleFonts.inter(
    fontSize: messageTextSize,
    height: messageLineHeight,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  /// Code block text style (JetBrains Mono, 14sp)
  static TextStyle get codeTextStyle => GoogleFonts.jetBrainsMono(
    fontSize: 14,
    height: 1.5,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  /// Placeholder/hint text style
  static TextStyle get hintTextStyle => GoogleFonts.inter(
    fontSize: bodyLargeSize,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );

  // ═══════════════════════════════════════════════════════════════
  //                    DIMENSION CONSTANTS
  // ═══════════════════════════════════════════════════════════════

  // Border radius values
  static const double radiusSmall = 8;
  static const double radiusMedium = 12;
  static const double radiusLarge = 16;
  static const double radiusXLarge = 18;       // Message bubbles
  static const double radiusPill = 28;         // Input bar, buttons
  static const double radiusCircle = 24;       // Circular buttons

  // Spacing
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 12;
  static const double spacingLg = 16;
  static const double spacingXl = 20;
  static const double spacingXxl = 24;

  // Component sizes
  static const double inputBarHeight = 56;
  static const double iconButtonSize = 48;
  static const double avatarSize = 40;
  static const double chipHeight = 44;
  
  // Animation durations
  static const Duration animFast = Duration(milliseconds: 100);
  static const Duration animNormal = Duration(milliseconds: 200);
  static const Duration animMedium = Duration(milliseconds: 250);
  static const Duration animSlow = Duration(milliseconds: 300);

  // ═══════════════════════════════════════════════════════════════
  //                    LIGHT THEME
  // ═══════════════════════════════════════════════════════════════

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surfaceLight,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textLight,
      ),
      scaffoldBackgroundColor: AppColors.backgroundLight,
      textTheme: _buildTextTheme(Brightness.light),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textLight),
        titleTextStyle: GoogleFonts.inter(
          fontSize: titleMediumSize,
          fontWeight: FontWeight.w600,
          color: AppColors.textLight,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
      ),
      inputDecorationTheme: _buildInputDecoration(Brightness.light),
      elevatedButtonTheme: _buildElevatedButton(Brightness.light),
      iconTheme: const IconThemeData(color: AppColors.textLight, size: 24),
      dividerTheme: DividerThemeData(
        color: AppColors.dividerLight,
        thickness: 1,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //                    DARK THEME (ChatGPT-EXACT)
  // ═══════════════════════════════════════════════════════════════

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: _buildTextTheme(Brightness.dark),
      
      // App Bar - ChatGPT style
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 24),
        titleTextStyle: GoogleFonts.inter(
          fontSize: titleMediumSize,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        margin: EdgeInsets.zero,
      ),

      // List Tiles
      listTileTheme: ListTileThemeData(
        tileColor: AppColors.settingsCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        titleTextStyle: GoogleFonts.inter(
          fontSize: bodyLargeSize,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
        subtitleTextStyle: GoogleFonts.inter(
          fontSize: bodyMediumSize,
          color: AppColors.textSecondary,
        ),
      ),

      // Input fields - ChatGPT input bar style
      inputDecorationTheme: _buildInputDecoration(Brightness.dark),

      // Buttons
      elevatedButtonTheme: _buildElevatedButton(Brightness.dark),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusPill),
          ),
          textStyle: GoogleFonts.inter(fontSize: bodyLargeSize),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.inter(fontSize: bodyLargeSize),
        ),
      ),

      // Icons
      iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 24),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
        ),
      ),

      // Dividers
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      // Bottom Sheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surfaceElevated,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusLarge)),
        ),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: titleMediumSize,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),

      // Snack Bar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceElevated,
        contentTextStyle: GoogleFonts.inter(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Drawer
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.background,
      ),

      // Popup Menu
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: bodyMediumSize,
          color: AppColors.textPrimary,
        ),
      ),

      // Chips - ChatGPT quick action style
      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        labelStyle: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontSize: bodyMediumSize,
        ),
        side: const BorderSide(color: AppColors.borderLight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22), // Fully rounded
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(AppColors.toggleThumb),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.toggleTrackOn;
          }
          return AppColors.toggleTrackOff;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //                    HELPER METHODS
  // ═══════════════════════════════════════════════════════════════

  static TextTheme _buildTextTheme(Brightness brightness) {
    final color = brightness == Brightness.dark
        ? AppColors.textPrimary
        : AppColors.textLight;
    final secondaryColor = brightness == Brightness.dark
        ? AppColors.textSecondary
        : AppColors.textMuted;

    return TextTheme(
      displayLarge: GoogleFonts.inter(
        fontSize: displayLargeSize,
        fontWeight: FontWeight.w700,
        height: displayLineHeight,
        color: color,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: displayMediumSize,
        fontWeight: FontWeight.w700,
        height: displayLineHeight,
        color: color,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: titleLargeSize,
        fontWeight: FontWeight.w600,
        height: titleLineHeight,
        color: color,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: titleMediumSize,
        fontWeight: FontWeight.w500,
        height: titleLineHeight,
        color: color,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: bodyLargeSize,
        fontWeight: FontWeight.w400,
        height: bodyLineHeight,
        color: color,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: bodyMediumSize,
        fontWeight: FontWeight.w400,
        height: bodyLineHeight,
        color: secondaryColor,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: labelSmallSize,
        fontWeight: FontWeight.w400,
        height: labelLineHeight,
        color: secondaryColor,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: bodyMediumSize,
        fontWeight: FontWeight.w500,
        color: color,
      ),
    );
  }

  static InputDecorationTheme _buildInputDecoration(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    
    return InputDecorationTheme(
      filled: true,
      fillColor: isDark ? AppColors.inputBackground : AppColors.surfaceLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusPill),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusPill),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusPill),
        borderSide: isDark 
            ? BorderSide.none 
            : const BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      hintStyle: GoogleFonts.inter(
        color: AppColors.textMuted,
        fontSize: bodyLargeSize,
      ),
    );
  }

  static ElevatedButtonThemeData _buildElevatedButton(Brightness brightness) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(double.infinity, 56),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusPill),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: bodyLargeSize,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
