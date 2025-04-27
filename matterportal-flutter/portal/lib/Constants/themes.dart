import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:portal/Constants/fonts.dart';

class Themes {
  static final lightTheme = ThemeData(
    fontFamily: "Medium",
    useMaterial3: true,
    appBarTheme: const AppBarTheme(
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),
    scaffoldBackgroundColor: Colors.white,
    primaryColor: Colors.black,
    shadowColor: Colors.grey[350],
    cardColor: const Color.fromARGB(255, 27, 27, 34), // Desired card color
    dividerColor: Colors.grey[500],
    highlightColor: const Color(0xFFC9C9C9),
    hintColor: const Color(0xFFF3F3F3),
    primaryColorDark: Colors.grey[500],
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontFamily: fontNameBold, color: Colors.black),
      displayMedium:
          TextStyle(fontFamily: fontNameSemiBold, color: Colors.black),
      displaySmall:
          TextStyle(fontFamily: fontNameSemiBold, color: Colors.black),
      headlineLarge: TextStyle(fontFamily: fontNameBold, color: Colors.black),
      headlineMedium: TextStyle(fontFamily: fontNameBold, color: Colors.black),
      headlineSmall: TextStyle(fontFamily: fontNameBold, color: Colors.black),
      titleLarge: TextStyle(fontFamily: fontNameBold, color: Colors.black),
      titleMedium: TextStyle(fontFamily: fontNameBold, color: Colors.black),
      titleSmall: TextStyle(fontFamily: fontNameBold, color: Colors.black),
      bodyLarge: TextStyle(fontFamily: fontNameBold, color: Colors.black),
      bodyMedium: TextStyle(fontFamily: fontNameBold, color: Colors.black),
      bodySmall: TextStyle(fontFamily: fontNameBold, color: Colors.black),
      labelLarge: TextStyle(fontFamily: fontNameBold, color: Colors.black),
      labelMedium: TextStyle(fontFamily: fontNameBold, color: Colors.black),
      labelSmall: TextStyle(fontFamily: fontNameBold, color: Colors.black),
    ),
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: Colors.blue,
    ).copyWith(
      secondary: const Color(0xFF6A5ACD), // Purple-blueish color
      surface: Colors.white,
    ),
  );

  static final darkTheme = ThemeData(
    fontFamily: "Medium",
    useMaterial3: true,
    appBarTheme: const AppBarTheme(
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),
    scaffoldBackgroundColor: const Color.fromARGB(255, 5, 0, 29),
    primaryColor: Colors.white,
    shadowColor: const Color.fromARGB(255, 35, 35, 36),
    cardColor: const Color.fromARGB(255, 27, 27, 34),
    highlightColor: const Color(0xFF323232),
    dividerColor: Colors.grey[800],
    primaryColorDark: Colors.grey[500],
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontFamily: fontNameBold, color: Colors.white),
      displayMedium: TextStyle(fontFamily: fontNameBold, color: Colors.white),
      displaySmall: TextStyle(fontFamily: fontNameBold, color: Colors.white),
      headlineLarge: TextStyle(fontFamily: fontNameBold, color: Colors.white),
      headlineMedium: TextStyle(fontFamily: fontNameBold, color: Colors.white),
      headlineSmall: TextStyle(fontFamily: fontNameBold, color: Colors.white),
      titleLarge: TextStyle(fontFamily: fontNameBold, color: Colors.white),
      titleMedium: TextStyle(fontFamily: fontNameBold, color: Colors.white),
      titleSmall: TextStyle(fontFamily: fontNameBold, color: Colors.white),
      bodyLarge: TextStyle(fontFamily: fontNameBold, color: Colors.white),
      bodyMedium: TextStyle(fontFamily: fontNameBold, color: Colors.white),
      bodySmall: TextStyle(fontFamily: fontNameBold, color: Colors.white),
      labelLarge: TextStyle(fontFamily: fontNameBold, color: Colors.white),
      labelMedium: TextStyle(fontFamily: fontNameBold, color: Colors.white),
      labelSmall: TextStyle(fontFamily: fontNameBold, color: Colors.white),
    ),
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: Colors.deepPurple,
    ).copyWith(
      secondary: const Color(0xFF6A5ACD), // Purple-blueish color
      surface: const Color.fromARGB(255, 35, 35, 36),
    ),
  );
}
