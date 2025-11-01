// lib/screens/result_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'dart:io';
import 'dart:ui' as ui;

// Chuyển từ StatelessWidget sang StatefulWidget
class ResultScreen extends StatefulWidget {
  final File imageFile;
  final List<dynamic> predictions;

  const ResultScreen({
    super.key,
    required this.imageFile,
    required this.predictions,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  // Biến trạng thái để lưu kích thước ảnh
  int? _imageWidth;
  int? _imageHeight;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Gọi hàm bất đồng bộ để lấy kích thước ảnh khi màn hình được khởi tạo
    _getImageDimensions();
  }

  // Hàm bất đồng bộ để lấy kích thước thật của ảnh
  Future<void> _getImageDimensions() async {
    final Uint8List bytes = await widget.imageFile.readAsBytes();
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final ui.Image image = frameInfo.image;

    // Cập nhật trạng thái với kích thước thật và tắt loading
    setState(() {
      _imageWidth = image.width;
      _imageHeight = image.height;
      _isLoading = false;
    });
  }

  // HÀM DỊCH NHÃN ĐỐI TƯỢNG SANG TIẾNG VIỆT
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

  // ... (các phần khác của class _ResultScreenState giữ nguyên)

  @override
  Widget build(BuildContext context) {
    // Hiển thị vòng tròn tải trong khi chờ lấy kích thước ảnh
    if (_isLoading) {
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
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Kiểm tra xem ảnh có phải là ảnh ngang không
    final isLandscapeImage = _imageWidth! > _imageHeight!;

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
      // === THAY ĐỔI CHÍNH: SỬ DỤNG ORIENTATIONBUILDER ===
      body: OrientationBuilder(
        builder: (context, orientation) {
          // Nếu màn hình đang ở chế độ dọc
          if (orientation == Orientation.portrait) {
            return _buildPortraitLayout(isLandscapeImage);
          }
          // Nếu màn hình đang ở chế độ ngang
          else {
            return _buildLandscapeLayout();
          }
        },
      ),
    );
  }

  // Bố cục cho màn hình dọc (Column)
  Widget _buildPortraitLayout(bool isLandscapeImage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Nếu là ảnh ngang, cho nó chiếm 3/5 không gian
        if (isLandscapeImage)
          Flexible(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              // === THAY ĐỔI: BỌC TRONG SINGLECHILDSCROLLVIEW ===
              child: SingleChildScrollView(
                child: _buildImageWithBoxes(context),
              ),
            ),
          )
        // Nếu là ảnh dọc, cho nó chiếm 4/5 không gian
        else
          Flexible(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              // === THAY ĐỔI: BỌC TRONG SINGLECHILDSCROLLVIEW ===
              child: SingleChildScrollView(
                child: _buildImageWithBoxes(context),
              ),
            ),
          ),
        // Phần mô tả bên dưới (giữ nguyên)
        Flexible(
          flex: isLandscapeImage ? 2 : 1,
          child: _buildBottomSection(context),
        ),
      ],
    );
  }

  // Bố cục cho màn hình ngang (Row)
  Widget _buildLandscapeLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Ảnh chiếm 3/5 chiều rộng
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            // === THAY ĐỔI: BỌC TRONG SINGLECHILDSCROLLVIEW ===
            child: SingleChildScrollView(child: _buildImageWithBoxes(context)),
          ),
        ),
        // Phần mô tả chiếm 2/5 chiều rộng (giữ nguyên)
        Expanded(flex: 2, child: _buildBottomSection(context)),
      ],
    );
  }

  Widget _buildImageWithBoxes(BuildContext context) {
    // Tính toán tỷ lệ khung hình từ kích thước ảnh gốc
    final double aspectRatio = _imageWidth! / _imageHeight!;
    // Lấy hướng của thiết bị để truyền vào hàm vẽ hộp
    final orientation = MediaQuery.of(context).orientation;

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double displayWidth = constraints.maxWidth;
          final double displayHeight = constraints.maxHeight;

          return Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                  image: DecorationImage(
                    image: FileImage(widget.imageFile),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Truyền hướng vào hàm _buildBoundingBoxes
              ..._buildBoundingBoxes(displayWidth, displayHeight, orientation),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildBoundingBoxes(
    double displayWidth,
    double displayHeight,
    Orientation orientation,
  ) {
    // Đảm bảo đã có kích thước ảnh gốc
    if (_imageWidth == null || _imageHeight == null) {
      return [];
    }

    // Tính toán tỷ lệ co giãn riêng cho trục X và Y
    final double scaleX = displayWidth / _imageWidth!;
    final double scaleY = displayHeight / _imageHeight!;

    // Hệ số thu nhỏ chiều cao khi ở chế độ ngang với ảnh dọc
    const double landscapeHeightScale = 0.8;

    // === ĐIỀU KIỆN ĐẶC BIỆT ===
    // Kiểm tra xem thiết bị có đang ở chế độ ngang VÀ ảnh có phải là ảnh dọc không
    final bool shouldScaleBoxHeight =
        (orientation == Orientation.landscape && _imageHeight! > _imageWidth!);

    List<Widget> boxes = [];
    for (final prediction in widget.predictions) {
      final box = (prediction['box'] as List)
          .map((e) => (e as num).toDouble())
          .toList();
      final label = prediction['label'] as String;

      // Áp dụng tỷ lệ co giãn để tính toán vị trí và kích thước trên màn hình
      final left = box[0] * scaleX;
      double top = box[1] * scaleY; // Đặt 'top' là mutable để có thể điều chỉnh
      final width = (box[2] - box[0]) * scaleX;
      double height = (box[3] - box[1]) * scaleY; // Đặt 'height' là mutable

      double finalHeight = height;
      if (shouldScaleBoxHeight) {
        // Nếu đúng điều kiện, thu nhỏ chiều cao của hộp lại
        finalHeight = height * landscapeHeightScale;
        // Dịch chuyển hộp lên một chút để nó được căn giữa trong vùng ban đầu
        top = top + (height - finalHeight) / 2;
      }

      boxes.add(
        Positioned(
          left: left,
          top: top, // Sử dụng vị trí 'top' đã điều chỉnh
          child: Container(
            width: width,
            height: finalHeight, // Sử dụng chiều cao đã điều chỉnh
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
                      _translateLabel(label),
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

  Widget _buildBottomSection(BuildContext context) {
    String description = "Mình không thấy gì đặc biệt.";
    if (widget.predictions.isNotEmpty) {
      // 1. Tạo một Map để đếm số lượng của mỗi nhãn
      final Map<String, int> labelCounts = {};
      for (final prediction in widget.predictions) {
        final label = (prediction as Map<String, dynamic>)['label'] as String;
        labelCounts[label] = (labelCounts[label] ?? 0) + 1;
      }

      // 2. Xây dựng câu mô tả từ Map
      if (labelCounts.isNotEmpty) {
        final descriptionParts = <String>[];
        final labels = labelCounts.keys.toList();

        for (int i = 0; i < labels.length - 1; i++) {
          final label = labels[i];
          final count = labelCounts[label]!;
          final vietnameseLabel = _translateLabel(label);
          descriptionParts.add('$count $vietnameseLabel');
        }

        final lastLabel = labels.last;
        final lastCount = labelCounts[lastLabel]!;
        final vietnameseLastLabel = _translateLabel(lastLabel);
        String lastPart;
        if (lastCount == 1) {
          lastPart = 'một $vietnameseLastLabel';
        } else {
          lastPart = '$lastCount $vietnameseLastLabel';
        }

        if (descriptionParts.isEmpty) {
          description = "Trong ảnh này có $lastPart.";
        } else {
          description =
              "Trong ảnh này có ${descriptionParts.join(', ')} và $lastPart.";
        }
      }
    }

    return SingleChildScrollView(
      // Thêm padding để nội dung không bị dính vào mép
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Cho cột tự co lại theo nội dung
        children: [
          SpeechBubble(text: description),
          const SizedBox(height: 16),
          Row(
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
          const SizedBox(height: 16),
          ElevatedButton.icon(
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
          // Thêm khoảng trống ở dưới cùng
          const SizedBox(height: 24),
        ],
      ),
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
