import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:history_manager/controller/clipboard_controller.dart';
import 'package:history_manager/views/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = true;

  // Register the controller ONCE globally
  Get.put(ClipboardController());

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(ClipboardController());
    final TextTheme poppinsTextTheme = GoogleFonts.poppinsTextTheme(
      Theme.of(context).textTheme,
    );
    return GetMaterialApp(
      title: 'Clipboard History',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: _buildLightTheme(poppinsTextTheme),

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
}
