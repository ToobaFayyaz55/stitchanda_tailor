import 'package:flutter/material.dart';

/// 🎨 Main Color Palette (from your Figma UI)
class AppColors {
  static const Color caramel = Color(0xFFD49649); // main accent button color
  static const Color gold = Color(0xFFDEA666); // lighter gold tone
  static const Color coffee = Color(0xFFBB7A49); // lighter gold tone
  static const Color beige = Color(0xFFE6BA88); // secondary soft tone
  static const Color deepBrown = Color(0xFF8E7051); // text & icon color
  static const Color chocolate = Color(0xFF5B4632); // darker brown for accents
  static const Color grey = Color(0xFFE5E7EB); // grey for accents
  static const Color darkgrey = Color(0xFF757575); // darker grey for accents
  static const Color green = Color(0xFF43A047); // darker green for accents

  static const Color background = Color(0xFFFFFDF9); // creamy white background
  static const Color surface = Color(0xFFFFFFFF); // card & field background
  static const Color outline = Color(0xFFE5E1DA); // soft border
  static const Color error = Color(0xFFDC2626);
  static const Color success = Color(0xFF3FA34D);

  static const Color textBlack = Color(0xFF2A2A2A); // for main headings
  static const Color textGrey = Color(0xFF7B7B7B);  // for placeholders & subtitles
  static const Color iconGrey = Color(0xFF8E8E8E);  // for input icons
}

/// 🌈 Theme builder function
ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: false,
    brightness: Brightness.light,

    /// 🪄 Base colors
    primaryColor: AppColors.caramel,
    scaffoldBackgroundColor: AppColors.background,
    cardColor: AppColors.surface,

    /// 🧁 AppBar
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.deepBrown,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.deepBrown,
        fontFamily: 'Poppins',
      ),
    ),

    /// ✏️ Input Fields
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      prefixIconColor: AppColors.iconGrey,
      suffixIconColor: AppColors.iconGrey,

      labelStyle: const TextStyle(
        color: AppColors.textGrey,
        fontSize: 14,
      ),
      hintStyle: const TextStyle(
        color: AppColors.textGrey,
        fontSize: 13,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.caramel, width: 1.4),
      ),
    ),

    /// 🍮 Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.caramel,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: AppColors.caramel.withOpacity(0.2),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          fontFamily: 'Poppins',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),

    /// 🍩 Text Buttons (like “Create an account”)
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.caramel,
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
      ),
    ),

    /// 🧁 Text
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        color: AppColors.textBlack,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        fontFamily: 'Poppins',
      ),
      bodyMedium: TextStyle(
        color: AppColors.textGrey,
        fontSize: 14,
        fontFamily: 'Poppins',
      ),
      bodyLarge: TextStyle(
        color: AppColors.textBlack,
        fontSize: 16,
        fontFamily: 'Poppins',
      ),
    ),


    /// 🍫 Color Scheme
    colorScheme: const ColorScheme.light(
      primary: AppColors.caramel,
      secondary: AppColors.beige,
      background: AppColors.background,
      surface: AppColors.surface,
      outline: AppColors.outline,
      error: AppColors.error,
    ),
  );
}
