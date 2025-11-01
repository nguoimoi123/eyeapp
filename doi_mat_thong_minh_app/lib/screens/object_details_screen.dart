// lib/screens/object_details_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import '../data/object_details_data.dart'; // <<<< IMPORT DỮ LIỆU

class ObjectDetailsScreen extends StatelessWidget {
  final String label; // <<<< NHẬN LABEL TỪ MÀN HÌNH TRƯỚC

  const ObjectDetailsScreen({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    // Tra cứu thông tin từ "bách khoa toàn thư"
    final details = ObjectDetailsData.getDetails(label);

    // Nếu không có thông tin, hiển thị màn hình trống
    if (details == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Chi tiết')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Xin lỗi, mình chưa có thông tin cho vật thể này.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
          ),
        ),
      );
    }

    // Nếu có thông tin, hiển thị
    return Scaffold(
      body: Stack(
        children: [
          // Ảnh nền làm mờ, dùng Image.asset
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                    details!['imageUrl']!,
                  ), // <<<< DÙNG IMAGE.ASSET
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          // Panel nội dung trượt lên
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.65,
              decoration: const BoxDecoration(
                color: Color(0xFFF8F9FA),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Thanh cầm
                      Center(
                        child: Container(
                          height: 5,
                          width: 36,
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Tiêu đề
                      Text(
                        details!['title']!, // <<<< DÙNG TIÊU ĐỘ DỮ LIỆU
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0D0D0D),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Mô tả
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            details!['description']!, // <<<< DÙNG MÔ TẢ DỮ LIỆU
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              height: 1.5,
                              color: const Color(0xFF6C6C70),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Các nút hành động
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2b6cee),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Đã hiểu',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
