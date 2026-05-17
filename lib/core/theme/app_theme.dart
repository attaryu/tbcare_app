import 'package:flutter/material.dart';
import 'app_color.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColor.primary,
        primary: AppColor.primary,
        surface: AppColor.white,
        background: AppColor.lightGray,
      ),
      scaffoldBackgroundColor: AppColor.lightGray,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColor.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColor.darkGray,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: AppColor.darkGray),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColor.lightGray.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        prefixIconColor: AppColor.neutralGray,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColor.white,
        indicatorColor: AppColor.primary.withOpacity(0.1),
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const TextStyle(
              fontWeight: FontWeight.bold, 
              fontSize: 12,
              color: AppColor.primary,
            );
          }
          return const TextStyle(fontSize: 12, color: AppColor.neutralGray);
        }),
      ),
    );
  }
}
