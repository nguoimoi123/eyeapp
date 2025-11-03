// lib/screens/create_quiz_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'quiz_challenge_screen.dart'; // Import màn hình chính của quiz

class CreateQuizScreen extends StatelessWidget {
  const CreateQuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9FB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Symbols.close, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Tạo Quiz Mới',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0D0D0D),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          // <<< THAY ĐỔI: Bọc Column trong SingleChildScrollView
          child: Column(
            children: [
              // Phần nội dung chính
              // <<< XÓA widget Expanded
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40), // Thêm khoảng trống trên cùng
                  // Icon lớn nhiều lớp
                  Container(
                    width: 160,
                    height: 160,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEBF5FF),
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: const Color(0xFF007AFF).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Symbols.movie,
                        size: 64,
                        color: Color(0xFF007AFF),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Bắt đầu trò chơi!',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0D0D0D),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text(
                      'Tải lên một video ngắn hoặc chọn video có sẵn để Đôi Mắt Thông Minh tạo câu đố cho bạn nhé!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        color: const Color(0xFF6C6C70),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 40,
                  ), // Thêm khoảng trống giữa nội dung và nút bấm
                ],
              ),
              // Phần nút bấm ở dưới
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Gợi ý: Video nên dưới 20 giây',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: const Color(0xFF6C6C70),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Nút chính
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const QuizChallengeScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007AFF),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Tải Video Lên',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Nút phụ
                    OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const QuizChallengeScreen(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFFEBF5FF),
                        foregroundColor: const Color(0xFF007AFF),
                        minimumSize: const Size(double.infinity, 48),
                        side: const BorderSide(color: Color(0xFFEBF5FF)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Chọn từ Thư viện',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20), // Thêm khoảng trống ở cuối
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
