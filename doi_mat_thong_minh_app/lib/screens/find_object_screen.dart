import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'dart:convert';

import '../services/api_udp_service.dart';
import 'object_details_screen.dart'; // Thêm import cho màn hình chi tiết

class FindObjectScreen extends StatefulWidget {
  const FindObjectScreen({super.key});

  @override
  State<FindObjectScreen> createState() => _FindObjectScreenState();
}

class _FindObjectScreenState extends State<FindObjectScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isTakingPicture = false;
  bool _isStreaming = false;
  int _frameCount = 0;

  final ApiUdpService _apiService = ApiUdpService();
  StreamSubscription<Map<String, dynamic>>? _serverResponseSubscription;

  // 🔹 Dữ liệu phản hồi từ server
  int _objectCount = 0;
  String _lastLabel = "";
  double _lastScore = 0;
  List<Map<String, dynamic>> _detections = [];
  DateTime _lastUpdateTime = DateTime.now();

  // 🔹 Thêm biến để theo dõi đối tượng được chọn
  int? _selectedObjectIndex;

  // 🔹 Màu sắc cho các class khác nhau
  final Map<String, Color> _classColors = {
    "person": Colors.red,
    "car": Colors.blue,
    "bicycle": Colors.green,
    "motorbike": Colors.orange,
    "bus": Colors.purple,
    "cat": Colors.pink,
    "dog": Colors.brown,
    "aeroplane": Colors.teal,
    "bird": Colors.lime,
    "boat": Colors.indigo,
    "bottle": Colors.amber,
    "chair": Colors.cyan,
    "cow": Colors.deepOrange,
    "diningtable": Colors.brown,
    "horse": Colors.brown.shade300,
    "pottedplant": Colors.green.shade700,
    "sheep": Colors.grey,
    "sofa": Colors.purple.shade300,
    "train": Colors.blue.shade700,
    "tvmonitor": Colors.blueGrey,
  };

  // 🔹 FPS calculation
  int _framesProcessed = 0;
  DateTime _fpsStartTime = DateTime.now();
  double _currentFPS = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    print("🚀 [INIT] Bắt đầu khởi tạo màn hình FindObject...");
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _serverResponseSubscription?.cancel();
    _controller?.dispose();
    _apiService.dispose();
    print("🧹 [DISPOSE] Dừng camera và giải phóng tài nguyên.");
    super.dispose();
  }

  // -----------------------------------------------------------------
  // 🔹 Khởi tạo camera
  // -----------------------------------------------------------------
  Future<void> _initializeCamera() async {
    print("📸 [CAMERA] Xin quyền truy cập camera...");
    await Permission.camera.request();

    _cameras = await availableCameras();
    if (_cameras.isEmpty) {
      print("❌ [CAMERA] Không tìm thấy camera nào trên thiết bị.");
      return;
    }

    final backCamera = _cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => _cameras.first,
    );

    print("✅ [CAMERA] Đã chọn camera: ${backCamera.name}");

    _controller = CameraController(
      backCamera,
      ResolutionPreset
          .low, // Thay đổi từ medium sang low để giảm kích thước frame
      enableAudio: false,
    );

    print("⚙️ [CAMERA] Đang khởi tạo camera...");
    await _controller!.initialize();
    await _controller!.setFlashMode(FlashMode.off);

    if (mounted) {
      setState(() => _isCameraInitialized = true);
      print("🎥 [CAMERA] Camera đã sẵn sàng, bắt đầu stream frame...");

      // Khởi tạo UDP service và bắt đầu lắng nghe
      _initializeUdpAndListen();

      // Bắt đầu stream frame
      _startFrameStream();
    }
  }

  // -----------------------------------------------------------------
  // 🔹 Khởi tạo UDP và lắng nghe phản hồi
  // -----------------------------------------------------------------
  void _initializeUdpAndListen() async {
    print("🔌 [UDP] Khởi tạo kết nối UDP...");
    await _apiService.initialize();

    // Hủy bỏ subscription cũ nếu có
    _serverResponseSubscription?.cancel();

    // Lắng nghe phản hồi từ server
    _serverResponseSubscription = _apiService.listenForServerResults().listen(
      (data) {
        // 🔥 CHỈ IN RA JSON mà server trả về
        final jsonString = JsonEncoder.withIndent('  ').convert(data);
        print("📨 [SERVER RESPONSE] JSON nhận được:");
        print(jsonString);
        print("=" * 50);

        final count = data["object_count"] ?? 0;
        final detections = data["detections"] ?? [];

        // Cập nhật state trên main thread
        if (mounted) {
          setState(() {
            _objectCount = count;
            _detections = List<Map<String, dynamic>>.from(detections);
            _lastUpdateTime = DateTime.now();

            if (detections.isNotEmpty) {
              _lastLabel = detections[0]["label"].toString();
              _lastScore = (detections[0]["score"] ?? 0.0).toDouble();
            }

            // Tính FPS
            _framesProcessed++;
            final now = DateTime.now();
            final elapsed = now.difference(_fpsStartTime).inSeconds;
            if (elapsed >= 2) {
              _currentFPS = _framesProcessed / elapsed;
              _framesProcessed = 0;
              _fpsStartTime = now;
            }
          });
        }
      },
      onError: (error) {
        print("❌ [STREAM ERROR] Lỗi khi lắng nghe server: $error");
      },
      onDone: () {
        print("🔚 [STREAM DONE] Stream đã kết thúc");
      },
    );

    print("👂 [UDP] Đã bắt đầu lắng nghe JSON từ server...");
  }

  // -----------------------------------------------------------------
  // 🔹 Stream frame và gửi qua UDP
  // -----------------------------------------------------------------
  void _startFrameStream() async {
    if (_isStreaming) return;
    if (_controller == null || !_controller!.value.isInitialized) return;

    _isStreaming = true;
    _frameCount = 0;

    await _controller!.stopImageStream().catchError((_) {});
    print("▶️ [STREAM] Bắt đầu gửi frame liên tục qua UDP...");

    _controller!.startImageStream((CameraImage image) async {
      if (_isTakingPicture) return;
      _isTakingPicture = true;

      try {
        _frameCount++;

        // Gửi 1 frame trên 5 để giảm tải (thay đổi từ 3)
        if (_frameCount % 5 != 0) {
          _isTakingPicture = false;
          return;
        }

        final jpegBytes = await _convertCameraImageToJpeg(image);
        await _apiService.sendRawFrame(jpegBytes);

        // 🔥 In thông tin gửi frame (tùy chọn)
        if (_frameCount % 10 == 0) {
          print("📤 [SEND] Gửi frame $_frameCount (${jpegBytes.length} bytes)");
        }
      } catch (e) {
        print("❌ [ERROR] Lỗi xử lý/gửi frame: $e");
      } finally {
        _isTakingPicture = false;
      }
    });
  }

  // -----------------------------------------------------------------
  // 🔹 Chuyển frame camera sang JPEG - GIẢM CHẤT LƯỢNG
  // -----------------------------------------------------------------
  Future<Uint8List> _convertCameraImageToJpeg(CameraImage image) async {
    try {
      final imgRgb = await _convertYUV420toImageColor(image);
      // Giảm chất lượng ảnh để tránh lỗi "Message too long"
      final jpg = img.encodeJpg(imgRgb, quality: 50); // Giảm từ 75 xuống 50
      return Uint8List.fromList(jpg);
    } catch (e) {
      print("💥 [CONVERT] Lỗi khi chuyển frame sang JPEG: $e");
      rethrow;
    }
  }

  // -----------------------------------------------------------------
  // 🔹 Chuyển định dạng YUV420 → RGB
  // -----------------------------------------------------------------
  Future<img.Image> _convertYUV420toImageColor(CameraImage image) async {
    final width = image.width;
    final height = image.height;
    final uvRowStride = image.planes[1].bytesPerRow;
    final uvPixelStride = image.planes[1].bytesPerPixel ?? 1;

    final img.Image imgRgb = img.Image(width: width, height: height);

    final yPlane = image.planes[0].bytes;
    final uPlane = image.planes[1].bytes;
    final vPlane = image.planes[2].bytes;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int uvIndex = uvPixelStride * (x ~/ 2) + uvRowStride * (y ~/ 2);

        final int yp = yPlane[y * image.planes[0].bytesPerRow + x];
        final int up = uPlane[uvIndex];
        final int vp = vPlane[uvIndex];

        int r = (yp + vp * 1436 / 1024 - 179).clamp(0, 255).toInt();
        int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91)
            .clamp(0, 255)
            .toInt();
        int b = (yp + up * 1814 / 1024 - 227).clamp(0, 255).toInt();

        imgRgb.setPixelRgb(x, y, r, g, b);
      }
    }

    return imgRgb;
  }

  // -----------------------------------------------------------------
  // 🔹 Lấy màu cho class
  // -----------------------------------------------------------------
  Color _getColorForClass(String className) {
    return _classColors[className.toLowerCase()] ?? Colors.yellow;
  }

  // -----------------------------------------------------------------
  // 🔹 Giao diện hiển thị
  // -----------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final screenSize = MediaQuery.of(context).size;
    final previewSize = _controller!.value.previewSize!;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          Center(
            child: Transform.scale(
              scale: screenSize.width / previewSize.height,
              child: CameraPreview(_controller!),
            ),
          ),

          // Vẽ box + label - LUÔN HIỂN THỊ KỂ KHI KHÔNG CÓ OBJECT
          CustomPaint(
            size: screenSize,
            painter: DetectionPainter(
              detections: _detections,
              previewSize: previewSize,
              screenSize: screenSize,
              getColorForClass: _getColorForClass,
              selectedIndex: _selectedObjectIndex, // Thêm index được chọn
            ),
          ),

          // Nút quay lại
          _buildBackButton(context),

          // Danh sách objects phát hiện
          _buildObjectList(),

          // Nút tìm hiểu chi tiết (chỉ hiển thị khi có đối tượng được chọn)
          if (_selectedObjectIndex != null) _buildDetailButton(),
        ],
      ),
    );
  }

  Widget _buildObjectList() {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white30),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Phát hiện vật thể (${_detections.length})",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _detections.length,
                itemBuilder: (context, index) {
                  final det = _detections[index];
                  final label = det["label"] ?? "Unknown";
                  final score = (det["score"] ?? 0.0).toDouble();
                  final color = _getColorForClass(label);
                  final isSelected = _selectedObjectIndex == index;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedObjectIndex = isSelected ? null : index;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withOpacity(0.5)
                            : color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? color : color.withOpacity(0.5),
                          width: isSelected ? 2.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          Text(
                            "${(score * 100).toStringAsFixed(0)}%",
                            style: TextStyle(
                              color: color,
                              fontSize: 10,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailButton() {
    return Positioned(
      bottom: 150,
      left: 20,
      right: 20,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: MaterialButton(
          onPressed: () {
            if (_selectedObjectIndex != null) {
              final selectedObject = _detections[_selectedObjectIndex!];
              final label = selectedObject["label"] ?? "Unknown";

              // Chuyển đến màn hình chi tiết
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ObjectDetailsScreen(label: label),
                ),
              ).then((_) {
                // Reset selection khi quay lại
                setState(() {
                  _selectedObjectIndex = null;
                });
              });
            }
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.info_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text(
                "Tìm hiểu chi tiết",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Positioned(
      top: 50,
      right: 20,
      child: FloatingActionButton(
        mini: true,
        onPressed: () {
          print("↩️ [UI] Quay lại màn hình trước.");
          Navigator.pop(context);
        },
        backgroundColor: Colors.black.withOpacity(0.7),
        child: const Icon(Icons.arrow_back, color: Colors.white),
      ),
    );
  }
}

// -----------------------------------------------------------------
// 🔹 Custom Painter để vẽ box + label
// -----------------------------------------------------------------
class DetectionPainter extends CustomPainter {
  final List<Map<String, dynamic>> detections;
  final Size previewSize;
  final Size screenSize;
  final Color Function(String) getColorForClass;
  final int? selectedIndex; // Thêm index được chọn

  DetectionPainter({
    required this.detections,
    required this.previewSize,
    required this.screenSize,
    required this.getColorForClass,
    this.selectedIndex, // Thêm index được chọn
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Tính toán tỷ lệ chuyển đổi từ tọa độ ảnh sang tọa độ màn hình
    final scaleX = screenSize.width / previewSize.height;
    final scaleY = screenSize.height / previewSize.width;
    final offsetX = (screenSize.width - previewSize.height * scaleX) / 2;
    final offsetY = (screenSize.height - previewSize.width * scaleY) / 2;

    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.bold,
      shadows: [
        Shadow(
          color: Colors.black.withOpacity(0.8),
          blurRadius: 4,
          offset: const Offset(1, 1),
        ),
      ],
    );

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // In thông tin debug
    print("🎨 [PAINTER] Vẽ ${detections.length} detection boxes");
    print(
      "📏 [PAINTER] Preview size: ${previewSize.width}x${previewSize.height}",
    );
    print("📱 [PAINTER] Screen size: ${screenSize.width}x${screenSize.height}");
    print("📐 [PAINTER] Scale: X=$scaleX, Y=$scaleY");

    for (int i = 0; i < detections.length; i++) {
      final det = detections[i];
      final bbox = det["box"];
      if (bbox == null || bbox.length < 4) continue;

      final label = det["label"]?.toString() ?? "Unknown";
      final score = (det["score"] ?? 0.0).toDouble();
      final color = getColorForClass(label);
      final isSelected = selectedIndex == i; // Kiểm tra có được chọn không

      // Chuyển đổi tọa độ box từ server sang tọa độ màn hình
      final x1 = bbox[0] * scaleX + offsetX;
      final y1 = bbox[1] * scaleY + offsetY;
      final x2 = bbox[2] * scaleX + offsetX;
      final y2 = bbox[3] * scaleY + offsetY;

      // Đảm bảo box nằm trong màn hình
      final rect = Rect.fromLTWH(
        x1.clamp(0.0, screenSize.width),
        y1.clamp(0.0, screenSize.height),
        (x2 - x1).clamp(0.0, screenSize.width),
        (y2 - y1).clamp(0.0, screenSize.height),
      );

      print(
        "📦 [PAINTER] Vẽ box cho $label: ${rect.left},${rect.top},${rect.right},${rect.bottom}",
      );

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected
            ? 5.0
            : 3.0 // Đậm hơn nếu được chọn
        ..color = color;

      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = isSelected
            ? color.withOpacity(0.3) // Đậm hơn nếu được chọn
            : color.withOpacity(0.15);

      // Vẽ box filled + border
      canvas.drawRect(rect, fillPaint);
      canvas.drawRect(rect, paint);

      // Vẽ góc box
      _drawBoxCorners(canvas, rect, color, isSelected);

      // Vẽ label background
      final labelText = "$label ${(score * 100).toStringAsFixed(0)}%";
      textPainter.text = TextSpan(text: labelText, style: textStyle);
      textPainter.layout();

      final labelRect = Rect.fromLTWH(
        rect.left,
        rect.top - 20,
        textPainter.width + 8,
        18,
      );

      final labelBackgroundPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = color;

      canvas.drawRect(labelRect, labelBackgroundPaint);

      // Vẽ text
      textPainter.paint(canvas, Offset(rect.left + 4, rect.top - 18));
    }
  }

  void _drawBoxCorners(Canvas canvas, Rect rect, Color color, bool isSelected) {
    final cornerPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color;

    final cornerLength = isSelected ? 15.0 : 12.0; // Dài hơn nếu được chọn

    // Top-left corner
    canvas.drawRect(
      Rect.fromLTWH(rect.left, rect.top, 3, cornerLength),
      cornerPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(rect.left, rect.top, cornerLength, 3),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawRect(
      Rect.fromLTWH(rect.right - 3, rect.top, 3, cornerLength),
      cornerPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(rect.right - cornerLength, rect.top, cornerLength, 3),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawRect(
      Rect.fromLTWH(rect.left, rect.bottom - cornerLength, 3, cornerLength),
      cornerPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(rect.left, rect.bottom - 3, cornerLength, 3),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawRect(
      Rect.fromLTWH(
        rect.right - 3,
        rect.bottom - cornerLength,
        3,
        cornerLength,
      ),
      cornerPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        rect.right - cornerLength,
        rect.bottom - 3,
        cornerLength,
        3,
      ),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant DetectionPainter oldDelegate) {
    return oldDelegate.detections != detections ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}
