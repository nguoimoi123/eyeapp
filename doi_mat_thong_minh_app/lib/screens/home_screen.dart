// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'camera_screen.dart'; // Chúng ta sẽ tạo file này sau
import 'create_quiz_screen.dart'; // Và cả file này
import 'find_object_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Hàm để xây dựng một thẻ lựa chọn, giúp code gọn gàng hơn
  Widget _buildOptionCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    return Scaffold(
      backgroundColor: isDarkMode
          ? const Color(0xFF121212)
          : const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: isDarkMode
            ? const Color(0xFF121212)
            : const Color(0xFFF8F9FA),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              isDarkMode ? Symbols.light_mode : Symbols.dark_mode,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
            onPressed: () {
              // Chuyển đổi giao diện Dark/Light
              themeProvider.toggleTheme();
            },
          ),
        ],
      ),
      // --- SỬA ĐỔI CHỖ NÀY ---
      // Bọc toàn bộ nội dung trong SingleChildScrollView
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Text(
                'Đôi Mắt Thông Minh',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF212529),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Hãy để mình kể cho bạn nghe về thế giới xung quanh!',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  color: const Color(0xFF6C757D), // slate-600
                ),
              ),
              const SizedBox(height: 40),
              // Thẻ 1: Tôi thấy gì
              _buildOptionCard(
                context: context,
                title: 'Tôi thấy gì trong ảnh này?',
                description: 'Phân tích và mô tả nội dung của một bức ảnh.',
                icon: Symbols.photo_camera,
                color: const Color(0xFF3880FF), // card-blue
                onTap: () {
                  // Điều hướng đến màn hình Camera (Chế độ khám phá)
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CameraScreen()),
                  );
                },
              ),
              const SizedBox(height: 16),
              // Thẻ 2: Đoán xem nào
              _buildOptionCard(
                context: context,
                title: 'Đoán xem nào!',
                description: 'Chơi một trò chơi đoán đồ vật thú vị với AI.',
                icon: Symbols.lightbulb,
                color: const Color(0xFFA259FF), // card-purple
                onTap: () {
                  // Điều hướng đến màn hình Tạo Quiz
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateQuizScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              // Thẻ 3: Tìm giúp tôi
              _buildOptionCard(
                context: context,
                title: 'Tìm giúp tôi...',
                description: 'Tìm một vật thể cụ thể qua ống kính của bạn.',
                icon: Symbols.search,
                color: const Color(0xFF30D158), // card-green
                onTap: () {
                  // TODO: Điều hướng đến màn hình Tìm kiếm
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => FindObjectScreen()),
                  );
                },
              ),
              // Thêm một khoảng trống ở cuối để cuộn được mượt mà hơn
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      // --- KẾT THÚC SỬA ĐỔI ---
    );
  }
}
