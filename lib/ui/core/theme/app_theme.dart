import 'package:flutter/material.dart';

abstract final class AppColors {
  /// Sampled from the Figma "Chats" frame (Blue/blue-500).
  static const brandBlue = Color(0xFF135CAF);
  static const brandBlueLight = Color(0xFF13B0F7);
  static const accent = Color(0xFF40C4FF);
  static const canvas = Color(0xFFF7FAFC);
  static const shell = Color(0xFF2C2D3A);
  static const textPrimary = shell;
  static const textSecondary = Color(0xFF9A9BB1);
  static const messageBackground = Color(0xFFF4F7FB);
  static const incoming = Color(0xFFFFFFFF);
  static const outgoing = brandBlue;
  static const secondaryText = Color(0xFFD0D1DB);
  static const mutedText = textSecondary;
  static const send = brandBlueLight;
  static const border = Color(0xFFE9EEF5);
  static const divider = Color(0xFFF2F4F7);
  static const hint = Color(0xFFA0A6B2);
  static const danger = Color(0xFFB5443D);
  static const success = Color(0xFF35B883);
  static const surface = Colors.white;
}

ThemeData buildAppTheme() => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.brandBlue,
    primary: AppColors.brandBlue,
    surface: Colors.white,
  ),
  scaffoldBackgroundColor: Colors.white,
  fontFamily: 'Roboto',
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.brandBlue,
    foregroundColor: AppColors.incoming,
    centerTitle: true,
  ),
  textTheme: const TextTheme(
    titleLarge: TextStyle(
      color: AppColors.textPrimary,
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
    titleMedium: TextStyle(
      color: AppColors.textPrimary,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
    bodyMedium: TextStyle(color: AppColors.textSecondary, fontSize: 13),
    bodySmall: TextStyle(color: AppColors.textSecondary, fontSize: 11),
  ),
  listTileTheme: const ListTileThemeData(
    titleTextStyle: TextStyle(
      color: AppColors.textPrimary,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
    subtitleTextStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13),
  ),
);
