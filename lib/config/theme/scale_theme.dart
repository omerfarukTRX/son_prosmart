import 'package:flutter/material.dart';

class ScaleColors {
  // Ana Renkler
  static const Color sidebar = Color(0xFF1A1A2E);
  static const Color background = Color(0xFFF7F9FC);
  static const Color surface = Colors.white;
  static const Color accent = Color(0xFF2CD9C5);

  // Metin Renkleri
  static const Color textPrimary = Color(0xFF2C3E50);
  static const Color textSecondary = Color(0xFF8392A5);
  static const Color sidebarText = Color(0xFF8392A5);
  static const Color sidebarActiveText = Colors.white;

  // Border ve Gölge
  static const Color border = Color(0xFFE9EDF4);
  static const Color shadow = Color(0x0A000000);
}

class ScaleTheme {
  // Sabit Ölçüler
  static const double sidebarWidth = 240.0;
  static const double appBarHeight = 64.0;
  static const double drawerHeaderHeight = 70.0;

  static ThemeData theme() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: ScaleColors.background,

      // Renk Şeması
      colorScheme: const ColorScheme.light(
        primary: ScaleColors.accent,
        secondary: ScaleColors.accent,
        surface: ScaleColors.surface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: ScaleColors.textPrimary,
      ),

      // AppBar Teması
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        toolbarHeight: appBarHeight,
        titleTextStyle: TextStyle(
          color: ScaleColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(
          color: ScaleColors.textSecondary,
          size: 20,
        ),
      ),

      // Drawer Teması
      drawerTheme: const DrawerThemeData(
        backgroundColor: ScaleColors.sidebar,
        width: sidebarWidth,
        elevation: 0,
        shape: RoundedRectangleBorder(),
      ),

      // ListTile Teması (Drawer menü öğeleri için)
      listTileTheme: ListTileThemeData(
        selectedColor: ScaleColors.sidebarActiveText,
        iconColor: ScaleColors.sidebarText,
        textColor: ScaleColors.sidebarText,
        selectedTileColor: ScaleColors.accent.withOpacity(0.1),
        minLeadingWidth: 0,
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        dense: true,
      ),

      // Divider Teması
      dividerTheme: const DividerThemeData(
        color: Color(0xFF2A2F42),
        thickness: 1,
        space: 1,
      ),

      // Card Teması
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(
            color: ScaleColors.border,
            width: 1,
          ),
        ),
        margin: EdgeInsets.zero,
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ScaleColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(
          color: ScaleColors.textSecondary,
          fontSize: 14,
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),

      // Text Theme
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
          color: ScaleColors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
          color: ScaleColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          color: ScaleColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.2,
          color: ScaleColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: ScaleColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.normal,
          color: ScaleColors.textSecondary,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: ScaleColors.textSecondary,
        ),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        size: 20,
        color: ScaleColors.textSecondary,
      ),

      // Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ScaleColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
