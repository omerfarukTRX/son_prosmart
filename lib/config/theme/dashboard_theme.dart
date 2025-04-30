import 'package:flutter/material.dart';

class DashboardColors {
  // Ana Renkler
  static const Color sidebar = Color(0xFF1A1A2E);
  static const Color background = Color(0xFFF8F9FA);
  static const Color cardBackground = Colors.white;
  static const Color accent = Color(0xFF2CD9C5);

  // Metin Renkleri
  static const Color primaryText = Color(0xFF2C3E50);
  static const Color secondaryText = Color(0xFF95A5A6);
  static const Color sidebarText = Color(0xFF95A5A6);
  static const Color activeText = Colors.white;

  // Sosyal Medya Renkleri
  static const Color facebook = Color(0xFF1877F2);
  static const Color twitter = Color(0xFF1DA1F2);

  // Grafik Renkleri
  static const Color chartLine = Color(0xFF2CD9C5);
  static const Color chartFill = Color(0x152CD9C5);
}

class DashboardTheme {
  static ThemeData theme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: DashboardColors.accent,
        secondary: DashboardColors.accent,
        surface: DashboardColors.cardBackground,
      ),

      scaffoldBackgroundColor: DashboardColors.background,

      // AppBar Teması
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: DashboardColors.primaryText,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(
          color: DashboardColors.primaryText,
        ),
      ),

      // Drawer Teması
      drawerTheme: const DrawerThemeData(
        backgroundColor: DashboardColors.sidebar,
        width: 260,
      ),

      // Card Teması
      cardTheme: CardTheme(
        color: DashboardColors.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),

      // Text Teması
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: DashboardColors.primaryText,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: DashboardColors.primaryText,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: DashboardColors.primaryText,
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: DashboardColors.secondaryText,
        ),
        bodyLarge: TextStyle(
          fontSize: 14,
          color: DashboardColors.primaryText,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          color: DashboardColors.secondaryText,
        ),
      ),
    );
  }
}
