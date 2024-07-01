   import 'package:flutter/material.dart';
   import 'colors.dart';

   final ThemeData appTheme = ThemeData(
     primaryColor: AppColors.primary,
     scaffoldBackgroundColor: AppColors.background,
     textTheme: TextTheme(
       headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
       bodyMedium: TextStyle(fontSize: 16, color: AppColors.textSecondary),
     ),
     elevatedButtonTheme: ElevatedButtonThemeData(
       style: ElevatedButton.styleFrom(
         backgroundColor: AppColors.primary,
         foregroundColor: Colors.white,
         padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
         shape: RoundedRectangleBorder(
           borderRadius: BorderRadius.circular(8),
         ),
       ),
     ),
     colorScheme: ColorScheme.fromSwatch().copyWith(
       secondary: AppColors.secondary,
     ),
   );