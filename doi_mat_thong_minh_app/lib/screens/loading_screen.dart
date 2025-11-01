// lib/screens/loading_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import '../services/api_service.dart';
import 'result_screen.dart';

class LoadingScreen extends StatefulWidget {
  final File imageFile;
  const LoadingScreen({super.key, required this.imageFile});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scanAnimation;
  late Animation<double> _blinkAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _scanAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _blinkAnimation = Tween<double>(begin: 1.0, end: 0.1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.8, 0.85, curve: Curves.easeInOut),
      ),
    );

    // Gọi hàm xử lý ảnh ngay lập tức
    _processImage();
  }

  // SỬA HÀM _processImage ĐỂ GỌI /PREDICT
  Future<void> _processImage() async {
    try {
      // Gọi API /predict để lấy bounding boxes
      final result = await ApiService().predictImage(widget.imageFile);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(
              imageFile: widget.imageFile,
              predictions: result['objects'], // TRUYỀN DANH SÁCH CÁC OBJECT
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        print(e.toString());
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã có lỗi xảy ra, vui lòng thử lại.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      body: Stack(
        children: [
          _buildBackgroundBlob(
            Alignment(-1.2, -0.5),
            Colors.blue.withOpacity(0.3),
          ),
          _buildBackgroundBlob(
            Alignment(1.5, -0.8),
            Colors.cyan.withOpacity(0.3),
          ),
          _buildBackgroundBlob(
            Alignment(0.8, 1.5),
            Colors.indigo.withOpacity(0.2),
          ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scanAnimation.value,
                      child: Container(
                        width: 192,
                        height: 192,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2b6cee),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2b6cee).withOpacity(0.3),
                              blurRadius: 24,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Transform.scale(
                          scale: _blinkAnimation.value,
                          alignment: Alignment.center,
                          child: Container(
                            margin: const EdgeInsets.all(32),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Container(
                              margin: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                color: Colors.black87,
                                shape: BoxShape.circle,
                              ),
                              child: const Align(
                                alignment: Alignment(-0.5, -0.5),
                                child: CircleAvatar(
                                  radius: 8,
                                  backgroundColor: Colors.white70,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 48),
                Text(
                  'Để mình xem nào...',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF111318),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: 200,
                  child: LinearProgressIndicator(
                    color: const Color(0xFF2b6cee),
                    backgroundColor: const Color(0xFF2b6cee).withOpacity(0.2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundBlob(Alignment alignment, Color color) {
    return Align(
      alignment: alignment,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}
