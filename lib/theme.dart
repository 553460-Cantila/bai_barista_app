import 'package:flutter/material.dart';

class BaiColors {
  static const ink = Color(0xFF6B4A3A);
  static const pink = Color(0xFFFFD6DE);
  static const mint = Color(0xFFC1E1C1);
  static const butter = Color(0xFFFCE883);
  static const card = Color(0xFFFFFAF5);
  static const red = Color(0xFFFFCDD2);
  static const lavender = Color(0xFFDCD3F5);

  static const butterShadow = Color(0xFFE2C86F);
  static const mintShadow = Color(0xFF97C9B3);
  static const pinkShadow = Color(0xFFE6B0BD);
  static const whiteShadow = Color(0xFFE6D3D8);
}

ThemeData baiTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: BaiColors.pink,
    colorScheme: ColorScheme.fromSeed(
      seedColor: BaiColors.butter,
      primary: BaiColors.ink,
      surface: BaiColors.card,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withOpacity(.6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
    ),
  );
}

const TextStyle baiHeading = TextStyle(
  fontSize: 28,
  fontWeight: FontWeight.bold,
  color: Colors.white,
  shadows: [Shadow(offset: Offset(0, 3), color: Color(0xFFA8683F))],
);