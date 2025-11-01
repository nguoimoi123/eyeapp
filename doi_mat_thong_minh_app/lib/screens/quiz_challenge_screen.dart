// lib/screens/quiz_challenge_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart'; // <-- THÊM DÒNG NÀY
class QuizChallengeScreen extends StatefulWidget {
  const QuizChallengeScreen({super.key});

  @override
  State<QuizChallengeScreen> createState() => _QuizChallengeScreenState();
}

class _QuizChallengeScreenState extends State<QuizChallengeScreen> {
  int? _selectedAnswerIndex; // Lưu index của đáp án được chọn
  final int _correctAnswerIndex = 1; // Giả sửích đáp án đúng là B (index 1)
  final List<String> _answers = ['2', '3', '4', '5'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC), // background-light
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Thử thách video',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Câu hỏi 1/4',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: LinearProgressIndicator(
                    value: 0.25, // 1/4
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4A90E2)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Khung video và câu hỏi
            Expanded(
              flex: 2,
              child: _buildVideoPlayerSection(),
            ),
            const SizedBox(height: 24),
            // Danh sách đáp án
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  ...List.generate(_answers.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: _buildAnswerButton(index),
                    );
                  }),
                ],
              ),
            ),
            // Nút xác nhận
            ElevatedButton(
              onPressed: _selectedAnswerIndex != null ? _confirmAnswer : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A90E2),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Xác nhận',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget xây dựng khung video
  Widget _buildVideoPlayerSection() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: const DecorationImage(
          image: NetworkImage(
            'https://lh3.googleusercontent.com/aida-public/AB6AXuDGyQynxZF1pJY260mYBLq16A6zb2sKg5UJ9e8jblaEabC-EAfiyTXUoSHNOMD4ER5VVoVP6dEmSfSz6Xjx7yEJ5J7Xm7VjCkq9_nuE041dg1CsdK_mDtvBgSChh_WhLTXRI6tDRkSDdYt8EWdnbvExdawMSHebXuH2ky5gNPxvn36E59G-MeSFzVsnkM1YM8hwAp0vkuYIIMtZOvptQiLBi6ZJIdOYKUsWxYdftuZTW2g03Rokmjf3CWOuJkXAiujBtaN9OwB5IVw',
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          // Lớp phủ mờ
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.black.withOpacity(0.2),
            ),
          ),
          // Nút play và câu hỏi
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {
                      // TODO: Phát video
                    },
                    icon: Icon(
                      Symbols.play_arrow,
                      fill: 1,
                      color: Colors.white,
                      size: 64,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.3),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Có bao nhiêu chú chó đã xuất hiện trong video này?',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget xây dựng nút đáp án
  Widget _buildAnswerButton(int index) {
    final isSelected = _selectedAnswerIndex == index;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedAnswerIndex = index;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? const Color(0xFF4A90E2).withOpacity(0.1) : Colors.white,
        foregroundColor: Colors.black87,
        side: BorderSide(
          color: isSelected ? const Color(0xFF4A90E2) : Colors.transparent,
          width: 2,
        ),
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        'A. ${_answers[index]}'.replaceFirst('A', String.fromCharCode(65 + index)),
        style: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  // Hàm xử lý khi xác nhận đáp án
  void _confirmAnswer() {
    if (_selectedAnswerIndex == null) return;

    bool isCorrect = _selectedAnswerIndex == _correctAnswerIndex;
    
    // Hiển thị dialog kết quả
    showDialog(
      context: context,
      barrierDismissible: false, // Không cho đóng dialog bằng cách tap bên ngoài
      builder: (context) => AlertDialog(
        title: Text(isCorrect ? 'Chính xác!' : 'Chưa đúng!'),
        content: Text(isCorrect ? 'Bạn thật tinh mắt!' : 'Đáp án đúng là 3. Cố gắng lần sau nhé!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Đóng dialog
              // TODO: Chuyển đến câu hỏi tiếp theo hoặc kết thúc game
            },
            child: const Text('Tiếp tục'),
          ),
        ],
      ),
    );
  }
}