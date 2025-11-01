// lib/screens/create_quiz_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'quiz_challenge_screen.dart'; // Chúng ta sẽ tạo file này sau

class CreateQuizScreen extends StatelessWidget {
  const CreateQuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB), // background-light
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
            color: const Color(0xFF0D0D0D), // text-light-primary
          ),
        ),
        centerTitle: true,
      ),
      // Dùng Column để căn giữa nội dung và đẩy nút xuống dưới
      body: Column(
        children: [
          // Phần nội dung chính
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon lớn nhiều lớp
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBF5FF), // secondary-blue
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: const Color(0xFF007AFF).withOpacity(0.2), // primary/20
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Symbols.movie,
                      size: 64,
                      color: Color(0xFF007AFF), // primary
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
                      color: const Color(0xFF6C6C70), // text-light-secondary
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Phần nút bấm ở dưới
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  'Gợi ý: Video nên dưới 60 giây',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: const Color(0xFF6C6C70),
                  ),
                ),
                const SizedBox(height: 12),
                // Nút chính
                ElevatedButton(
                  onPressed: () {
                    // TODO: Chức năng tải video lên
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
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                // Nút phụ
                OutlinedButton(
                  onPressed: () {
                    // Điều hướng đến màn hình Thử thách
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
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}