// lib/screens/result_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'dart:io';

class ResultScreen extends StatelessWidget {
  final File imageFile;
  final List<dynamic> predictions;

  const ResultScreen({
    super.key,
    required this.imageFile,
    required this.predictions,
  });

  // HÀM MỚI: DỊCH TÊN VẬT THỂ SANG TIẾNG VIỆT ĐỂ MÔ TẢ TỰ NHIÊN HƠN
  String _translateLabel(String englishLabel) {
    switch (englishLabel) {
      case 'person':
        return 'người';
      case 'bicycle':
        return 'xe đạp';
      case 'car':
        return 'xe hơi';
      case 'motorbike':
        return 'xe máy';
      case 'aeroplane':
        return 'máy bay';
      case 'bus':
        return 'xe buýt';
      case 'train':
        return 'tàu hỏa';
      case 'truck':
        return 'xe tải';
      case 'boat':
        return 'thuyền';
      case 'traffic light':
        return 'đèn giao thông';
      case 'fire hydrant':
        return 'vòi cứu hỏa';
      case 'stop sign':
        return 'biển báo dừng';
      case 'parking meter':
        return 'máy đo giờ đỗ xe';
      case 'bench':
        return 'ghế dài';
      case 'bird':
        return 'con chim';
      case 'cat':
        return 'con mèo';
      case 'dog':
        return 'con chó';
      case 'horse':
        return 'con ngựa';
      case 'sheep':
        return 'con cừu';
      case 'cow':
        return 'con bò';
      case 'elephant':
        return 'con voi';
      case 'bear':
        return 'con gấu';
      case 'zebra':
        return 'ngựa vằn';
      case 'giraffe':
        return 'hươu cao cổ';
      case 'backpack':
        return 'balo';
      case 'umbrella':
        return 'cây dù';
      case 'handbag':
        return 'túi xách tay';
      case 'tie':
        return 'cà vạt';
      case 'suitcase':
        return 'vali';
      case 'frisbee':
        return 'đĩa bay';
      case 'skis':
        return 'ván trượt tuyết';
      case 'snowboard':
        return 'ván trượt tuyết kiểu xe đạp';
      case 'sports ball':
        return 'quả bóng thể thao';
      case 'kite':
        return 'diều';
      case 'baseball bat':
        return 'gậy bóng chày';
      case 'baseball glove':
        return 'găng tay bóng chày';
      case 'skateboard':
        return 'ván trượt ván';
      case 'surfboard':
        return 'ván lướt sóng';
      case 'tennis racket':
        return 'vợt tennis';
      case 'bottle':
        return 'chai nước';
      case 'wine glass':
        return 'ly rượu vang';
      case 'cup':
        return 'cốc';
      case 'fork':
        return 'nĩa';
      case 'knife':
        return 'dao';
      case 'spoon':
        return 'thìa';
      case 'bowl':
        return 'cái tô';
      case 'banana':
        return 'quả chuối';
      case 'apple':
        return 'quả táo';
      case 'sandwich':
        return 'bánh sandwich';
      case 'orange':
        return 'quả cam';
      case 'broccoli':
        return 'cây súp lơ';
      case 'carrot':
        return 'củ cà rốt';
      case 'hot dog':
        return 'xúc xích';
      case 'pizza':
        return 'bánh pizza';
      case 'donut':
        return 'bánh rán';
      case 'cake':
        return 'bánh ngọt';
      case 'chair':
        return 'cái ghế';
      case 'couch':
        return 'ghế sofa';
      case 'pottedplant':
        return 'cây cảnh trong chậu';
      case 'bed':
        return 'cái giường';
      case 'diningtable':
        return 'bàn ăn';
      case 'toilet':
        return 'nhà vệ sinh';
      case 'tvmonitor':
        return 'màn hình TV';
      case 'laptop':
        return 'máy tính xách tay';
      case 'mouse':
        return 'chuột máy tính';
      case 'remote':
        return 'điều khiển từ xa';
      case 'keyboard':
        return 'bàn phím';
      case 'cell phone':
        return 'điện thoại di động';
      case 'microwave':
        return 'lò vi sóng';
      case 'oven':
        return 'lò nướng';
      case 'toaster':
        return 'máy nướng bánh mì';
      case 'sink':
        return 'bồn rửa';
      case 'refrigerator':
        return 'tủ lạnh';
      case 'book':
        return 'quyển sách';
      case 'clock':
        return 'đồng hồ';
      case 'vase':
        return 'bình hoa';
      case 'scissors':
        return 'cái kéo';
      case 'teddy bear':
        return 'gấu bông';
      case 'hair drier':
        return 'máy sấy tóc';
      case 'toothbrush':
        return 'bàn chải đánh răng';
      default:
        return englishLabel; // Nếu không có trong danh sách, giữ nguyên
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F6F8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Symbols.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Kết quả',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildImageWithBoxes(context),
            ),
          ),
          _buildBottomSection(context),
        ],
      ),
    );
  }

  Widget _buildImageWithBoxes(BuildContext context) {
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              image: DecorationImage(
                image: FileImage(imageFile),
                fit: BoxFit.cover,
              ),
            ),
          ),
          ..._buildBoundingBoxes(context),
        ],
      ),
    );
  }

  List<Widget> _buildBoundingBoxes(BuildContext context) {
    const double originalImageWidth = 800.0;
    final double displayWidth = MediaQuery.of(context).size.width * 0.9;
    final double scale = displayWidth / originalImageWidth;

    List<Widget> boxes = [];
    for (final prediction in predictions) {
      final box = (prediction['box'] as List)
          .map((e) => (e as num).toDouble())
          .toList();
      final label = prediction['label'] as String;

      final left = box[0] * scale;
      final top = box[1] * scale;
      final width = (box[2] - box[0]) * scale;
      final height = (box[3] - box[1]) * scale;

      boxes.add(
        Positioned(
          left: left,
          top: top,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.cyan, width: 2),
              borderRadius: BorderRadius.circular(8),
              color: Colors.cyan.withOpacity(0.2),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: -25,
                  left: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.cyan,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _translateLabel(label), // Dùng nhãn đã dịch
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return boxes;
  }

  // HÀM NÀY ĐƯỢC VIẾT HOÀN TOÀN LẠI
  Widget _buildBottomSection(BuildContext context) {
    String description = "Mình không thấy gì đặc biệt.";
    if (predictions.isNotEmpty) {
      // 1. Tạo một Map để đếm số lượng của mỗi nhãn
      final Map<String, int> labelCounts = {};
      for (final prediction in predictions) {
        final label = (prediction as Map<String, dynamic>)['label'] as String;
        labelCounts[label] = (labelCounts[label] ?? 0) + 1;
      }

      // 2. Xây dựng câu mô tả từ Map
      if (labelCounts.isNotEmpty) {
        final descriptionParts = <String>[];
        final labels = labelCounts.keys.toList();

        // Xử lý tất cả các vật thể trừ vật thể cuối cùng
        for (int i = 0; i < labels.length - 1; i++) {
          final label = labels[i];
          final count = labelCounts[label]!;
          final vietnameseLabel = _translateLabel(label);
          descriptionParts.add('$count $vietnameseLabel');
        }

        // Xử lý vật thể cuối cùng
        final lastLabel = labels.last;
        final lastCount = labelCounts[lastLabel]!;
        final vietnameseLastLabel = _translateLabel(lastLabel);
        String lastPart;
        if (lastCount == 1) {
          lastPart = 'một $vietnameseLastLabel';
        } else {
          lastPart = '$lastCount $vietnameseLastLabel';
        }

        // Ghép các phần lại với nhau
        if (descriptionParts.isEmpty) {
          description = "Trong ảnh này có $lastPart.";
        } else {
          description =
              "Trong ảnh này có ${descriptionParts.join(', ')} và $lastPart.";
        }
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SpeechBubble(text: description),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                icon: Symbols.share,
                label: 'Chia sẻ',
                onPressed: () {},
              ),
              _buildActionButton(
                icon: Symbols.download,
                label: 'Lưu ảnh',
                onPressed: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            icon: const Icon(Symbols.cameraswitch),
            label: const Text('Chụp ảnh khác'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2b6cee),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(icon, color: Colors.black54),
          style: IconButton.styleFrom(
            backgroundColor: Colors.grey[200],
            padding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.black54,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

// ... (SpeechBubble và TrianglePainter giữ nguyên)
class SpeechBubble extends StatelessWidget {
  final String text;
  const SpeechBubble({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.black87,
              fontSize: 18,
              height: 1.5,
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 32,
          child: CustomPaint(
            size: const Size(15, 15),
            painter: TrianglePainter(Colors.white),
          ),
        ),
      ],
    );
  }
}

class TrianglePainter extends CustomPainter {
  final Color color;
  TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
