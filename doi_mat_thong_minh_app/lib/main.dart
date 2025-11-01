// lib/main.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Đôi Mắt Thông Minh',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Áp dụng font Google Fonts cho toàn bộ ứng dụng
        fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}