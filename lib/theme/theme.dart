import 'package:flutter/material.dart';

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Color(0xFF1E88E5),
    primary: Color(0xFF1E88E5),
    secondary: Color(0xFFFF9800),
    background: Color(0xFFF5F5F5),
    surface: Color(0xFFFFFFFF),
    onPrimary: Color(0xFFFFFFFF),
    onSecondary: Color(0xFF000000),
    onBackground: Color(0xFF212121),
    onSurface: Color(0xFF212121),
    error: Color(0xFFD32F2F),
  ),
  textTheme: TextTheme(
    headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF212121)),
    bodyMedium: TextStyle(fontSize: 16, color: Color(0xFF757575)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
  ),
);