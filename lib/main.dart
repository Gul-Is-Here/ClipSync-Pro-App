import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:history_manager/controller/clipboard_controller.dart';
import 'package:history_manager/views/home_page.dart';
import 'package:history_manager/views/splash_screen.dart';

void main() {
  // Ensure Flutter binding is initialized before using GoogleFonts
  WidgetsFlutterBinding.ensureInitialized();

  // Optional: Pre-load the Poppins font to avoid flash of unstyled text
  GoogleFonts.config.allowRuntimeFetching = true;

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Get.put(ClipboardController());

    // Define the base text style with Poppins
    final TextTheme poppinsTextTheme = GoogleFonts.poppinsTextTheme(
      Theme.of(context).textTheme,
    );

    return GetMaterialApp(
      title: 'Clipboard History',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: _buildLightTheme(poppinsTextTheme),
      darkTheme: _buildDarkTheme(poppinsTextTheme),
      home: const SplashScreen(),
    );
  }

  ThemeData _buildLightTheme(TextTheme poppinsTextTheme) {
    return ThemeData.light().copyWith(
      textTheme: poppinsTextTheme,
      primaryTextTheme: poppinsTextTheme,
      colorScheme: const ColorScheme.light(
        primary: Colors.deepPurple,
        secondary: Colors.deepPurpleAccent,
        surface: Colors.white,
        background: Color(0xFFF5F5F5),
      ),
      appBarTheme: AppBarTheme(
        elevation: 1,
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        titleTextStyle: poppinsTextTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardTheme(
        elevation: 1,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      // Apply Poppins to dialog texts
      dialogTheme: DialogTheme(
        titleTextStyle: poppinsTextTheme.titleLarge,
        contentTextStyle: poppinsTextTheme.bodyMedium,
      ),
      // Apply to button texts
      buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color.fromRGBO(103, 58, 183, 1),
          textStyle: poppinsTextTheme.labelLarge,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          textStyle: poppinsTextTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.deepPurple,
          textStyle: poppinsTextTheme.labelLarge,
        ),
      ),
      // Apply to input fields
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: poppinsTextTheme.bodyLarge,
        hintStyle: poppinsTextTheme.bodyLarge?.copyWith(
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme(TextTheme poppinsTextTheme) {
    return ThemeData.dark().copyWith(
      textTheme: poppinsTextTheme,
      primaryTextTheme: poppinsTextTheme,
      colorScheme: ColorScheme.dark(
        primary: Colors.blue.shade300,
        secondary: Colors.blue.shade200,
        surface: Colors.grey.shade900,
        background: Colors.grey.shade800,
      ),
      appBarTheme: AppBarTheme(
        elevation: 1,
        centerTitle: true,
        backgroundColor: Colors.grey.shade900,
        titleTextStyle: poppinsTextTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Colors.blue.shade300,
        foregroundColor: Colors.black,
      ),
      cardTheme: CardTheme(
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        color: Colors.grey.shade700,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Colors.grey.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      // Apply the same text styles as light theme but with dark colors
      dialogTheme: DialogTheme(
        titleTextStyle: poppinsTextTheme.titleLarge,
        contentTextStyle: poppinsTextTheme.bodyMedium,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.blue.shade300,
          textStyle: poppinsTextTheme.labelLarge,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade300,
          textStyle: poppinsTextTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.blue.shade300,
          textStyle: poppinsTextTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: poppinsTextTheme.bodyLarge,
        hintStyle: poppinsTextTheme.bodyLarge?.copyWith(
          color: Colors.grey.shade400,
        ),
      ),
    );
  }
}
