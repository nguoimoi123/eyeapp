// lib/screens/find_object_screen.dart
//
// Mô tả:
//  - Màn hình này mở camera, lấy frame liên tục (camera image stream), chuyển mỗi frame
//    sang JPEG bytes và gửi qua UDP đến server (ApiService.sendRawFrame).
//  - Thiết kế để dễ tích hợp vào các dự án demo / prototyping nơi server xử lý ảnh (ví dụ: Python).
//
// Lưu ý về hiệu năng & mạng:
//  - UDP không reliable; có thể mất frame. Nếu cần reliability, xem hướng dẫn chuyển sang TCP / chunking.
//  - Để giảm băng thông & tránh fragmentation, chúng ta gửi 1 frame/5 frame và nén JPEG quality ~80.
//  - Nếu gặp lỗi decode trên server -> giảm quality hoặc độ phân giải.

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'package:image/image.dart' as img;

import '../services/api_service.dart';
import '../services/api_udp_service.dart';

class FindObjectScreen extends StatefulWidget {
  const FindObjectScreen({super.key});

  @override
  State<FindObjectScreen> createState() => _FindObjectScreenState();
}

class _FindObjectScreenState extends State<FindObjectScreen>
    with WidgetsBindingObserver {
  CameraController? _controller; // Controller camera chính
  List<CameraDescription> _cameras = []; // Danh sách camera có trên thiết bị
  bool _isCameraInitialized = false; // Cờ đã init camera thành công chưa
  bool _isTakingPicture = false; // Đồng bộ tránh gửi nhiều request cùng lúc
  bool _isStreaming = false; // Đang ở chế độ stream frame từ camera
  int _frameCount = 0; // Đếm frame đã lấy (dùng để throttle)

  final ApiUdpService _apiService =
      ApiUdpService(); // Service UDP (đã định nghĩa ở lib/services)

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Giải phóng tài nguyên camera khi thoát màn hình
    _controller?.dispose();
    super.dispose();
  }

  /// Khởi tạo camera: request permission, lấy camera back, init controller
  Future<void> _initializeCamera() async {
    // Yêu cầu quyền camera (nếu chưa có)
    await Permission.camera.request();

    // Lấy danh sách camera có sẵn trên thiết bị
    _cameras = await availableCameras();
    if (_cameras.isEmpty) return;

    // Chọn camera sau (back) ưu tiên
    final backCamera = _cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => _cameras.first,
    );

    // Tạo controller với ResolutionPreset.medium (đủ rõ & tiết kiệm băng thông)
    _controller = CameraController(
      backCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    // Khởi tạo controller (async)
    await _controller!.initialize();

    // Tắt flash (mặc định)
    await _controller!.setFlashMode(FlashMode.off);

    // Khi đã sẵn sàng, cập nhật UI và bắt đầu stream frame
    if (mounted) {
      setState(() {
        _isCameraInitialized = true;
      });
      _startFrameStream();
    }
  }

  // 🔹 Bắt đầu stream frame camera và gửi qua UDP (ApiService.sendRawFrame)
  //
  // Thiết kế:
  //  - stopImageStream() trước khi start để đảm bảo không có luồng cũ
  //  - dùng `_frameCount % 5 == 0` để gửi 1/5 frame (throttle)
  //  - `_isTakingPicture` để tránh race condition / gửi nhiều frame cùng 1 lúc
  void _startFrameStream() async {
    if (_isStreaming) return;
    if (_controller == null || !_controller!.value.isInitialized) return;

    _isStreaming = true;
    _frameCount = 0;

    // Nếu trước đó đang stream, dừng để tránh lỗi
    await _controller!.stopImageStream().catchError((_) {});

    print(" Bắt đầu lấy frame từ camera...");
    // startImageStream cung cấp CameraImage (YUV420) liên tục
    _controller!.startImageStream((CameraImage image) async {
      // Nếu đang trong quá trình gửi frame hoặc xử lý, bỏ qua
      if (_isTakingPicture) return;
      _isTakingPicture = true;

      try {
        _frameCount++;

        // GỬI 1 FRAME = mỗi 5 frame (bạn có thể điều chỉnh frame skip để tăng/giảm băng thông)
        // Ví dụ: nếu camera chạy ~30 FPS, skip 5 -> ~6 FPS; tuy nhiên encode+send thực tế còn chậm hơn.
        if (_frameCount % 5 != 0) {
          _isTakingPicture = false;
          return;
        }

        // --- 1️⃣ Chuyển CameraImage (YUV420) sang JPEG bytes ---
        // Vì camera trả YUV, chúng ta cần convert sang RGB để encode JPEG.
        final jpegBytes = await _convertCameraImageToJpeg(image);

        // --- 2️⃣ Gửi JPEG bytes qua UDP ---
        // ApiService.sendRawFrame chỉ gửi bytes qua UDP tới server đã cấu hình.
        await _api_service_send(jpegBytes);

        print("📤 Đã gửi frame #$_frameCount (${jpegBytes.length} bytes)");
      } catch (e) {
        // debug print (trong production, dùng logging)
        print("❌ Lỗi xử lý frame: $e");
      } finally {
        _isTakingPicture = false;
      }
    });
  }

  // Wrapper gọi service để tách dependency, dễ unit-test
  Future<void> _api_service_send(Uint8List jpegBytes) async {
    try {
      await _apiService.sendRawFrame(jpegBytes);
    } catch (e) {
      print("Lỗi khi gửi frame qua ApiService: $e");
    }
  }

  // 🔹 Chuyển CameraImage (YUV420) → JPEG Uint8List
  //  - Convert YUV -> RGB bằng thuật toán cơ bản
  //  - Encode RGB -> JPEG bằng package `image`
  Future<Uint8List> _convertCameraImageToJpeg(CameraImage image) async {
    try {
      // Convert YUV -> RGB (trả về image.Image từ package:image)
      final imgRgb = await _convertYUV420toImageColor(image);

      // Encode sang JPEG (quality có thể điều chỉnh để giảm payload)
      final jpg = img.encodeJpg(imgRgb, quality: 80);

      // Trả về Uint8List (dễ gửi qua socket)
      return Uint8List.fromList(jpg);
    } catch (e) {
      print("Lỗi khi chuyển frame sang JPEG: $e");
      rethrow;
    }
  }

  // 🔹 Convert YUV420 (CameraImage) -> RGB (package:image.Image)
  // Giải thích:
  //  - CameraImage.planes: [Y, U, V] theo chuẩn YUV420
  //  - uvPixelStride và uvRowStride dùng để index U/V tương ứng pixel (subsample 2x2)
  //  - Công thức chuyển đổi YUV -> RGB ở đây là dạng xấp xỉ (đủ cho hiển thị)
  Future<img.Image> _convertYUV420toImageColor(CameraImage image) async {
    final width = image.width;
    final height = image.height;
    final uvRowStride = image.planes[1].bytesPerRow;
    final uvPixelStride = image.planes[1].bytesPerPixel ?? 1;

    final img.Image imgRgb = img.Image(width: width, height: height);

    final yPlane = image.planes[0].bytes;
    final uPlane = image.planes[1].bytes;
    final vPlane = image.planes[2].bytes;

    // Lặp qua mọi pixel để tính RGB
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int uvIndex = uvPixelStride * (x ~/ 2) + uvRowStride * (y ~/ 2);

        // Lấy giá trị Y/U/V (lưu ý indexing theo bytesPerRow)
        final int yp = yPlane[y * image.planes[0].bytesPerRow + x];
        final int up = uPlane[uvIndex];
        final int vp = vPlane[uvIndex];

        // Công thức chuyển đổi (đã scale & trừ offset)
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

  @override
  Widget build(BuildContext context) {
    // Nếu camera chưa init xong, hiển thị loading
    if (!_isCameraInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    // Giao diện chính: preview camera + status + nút back
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Hiển thị preview trực tiếp từ camera
          CameraPreview(_controller!),

          // Thông báo trạng thái ở dưới
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "Đang gửi frame UDP...",
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.cyanAccent,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Nút back góc trái trên
          _buildBackButton(context),
        ],
      ),
    );
  }

  // Nút back đơn giản
  Widget _buildBackButton(BuildContext context) {
    return Positioned(
      top: 50,
      left: 20,
      child: FloatingActionButton(
        mini: true,
        onPressed: () {
          // Khi quay lại, ta chỉ pop màn hình. Có thể mở rộng: dừng stream, v.v.
          Navigator.pop(context);
        },
        backgroundColor: Colors.black.withOpacity(0.5),
        child: const Icon(Icons.arrow_back, color: Colors.white),
      ),
    );
  }
}
