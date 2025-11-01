// lib/screens/find_object_screen.dart
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:io';
import '../services/api_service.dart';
import 'object_details_screen.dart';

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

  bool _isScanning = true;
  Map<String, dynamic>? _detectedObject;
  Timer? _detectionTimer;
  bool _isTakingPicture = false; // ✅ Thêm cờ kiểm soát chụp ảnh

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _detectionTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    await Permission.camera.request();
    _cameras = await availableCameras();
    if (_cameras.isEmpty) return;

    final firstCamera = _cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => _cameras.first,
    );

    _controller = CameraController(
      firstCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _controller!.initialize();
    await _controller!.setFlashMode(FlashMode.off);
    if (mounted) {
      setState(() {
        _isCameraInitialized = true;
      });
      _startRealTimeDetection();
    }
  }

  // ✅ Dò vật thể liên tục bằng timer, có kiểm tra isTakingPicture
  void _startRealTimeDetection() {
    const duration = Duration(seconds: 5);
    _detectionTimer = Timer.periodic(duration, (timer) async {
      if (!mounted ||
          _controller == null ||
          !_controller!.value.isInitialized) {
        timer.cancel();
        return;
      }

      if (_isTakingPicture) return; // ✅ Ngăn chụp trùng

      _isTakingPicture = true;
      try {
        final image = await _controller!.takePicture();
        final responseData = await _apiService.predictImage(File(image.path));

        if (responseData['objects'] != null &&
            responseData['objects'].isNotEmpty) {
          final firstObject = responseData['objects'].reduce(
            (a, b) => a['score'] > b['score'] ? a : b,
          );

          if (mounted) {
            setState(() {
              _isScanning = false;
              _detectedObject = {
                'label': firstObject['label'],
                'box': Rect.fromLTRB(
                  firstObject['box'][0].toDouble(),
                  firstObject['box'][1].toDouble(),
                  firstObject['box'][2].toDouble(),
                  firstObject['box'][3].toDouble(),
                ),
                'icon': _getIconForLabel(firstObject['label']),
                'color': Colors.cyan,
              };
            });
            timer.cancel(); // ✅ Dừng quét khi phát hiện vật thể
          }
        }
      } catch (e) {
        print("Lỗi khi gửi ảnh đến server: $e");
      } finally {
        _isTakingPicture = false; // ✅ Mở lại sau khi hoàn thành
      }
    });
  }

  IconData _getIconForLabel(String label) {
    switch (label.toLowerCase()) {
      case 'aeroplane':
        return Icons.flight;
      case 'bicycle':
        return Icons.pedal_bike;
      case 'bird':
        return Icons.flutter_dash;
      case 'boat':
        return Icons.directions_boat;
      case 'bottle':
        return Icons.local_drink;
      case 'bus':
        return Icons.airport_shuttle;
      case 'car':
        return Icons.directions_car;
      case 'cat':
        return Icons.pets;
      case 'chair':
        return Icons.chair;
      case 'cow':
        return Icons.agriculture;
      case 'diningtable':
        return Icons.table_restaurant;
      case 'dog':
        return Icons.pets;
      case 'horse':
        return Icons.directions_run;
      case 'motorbike':
        return Icons.motorcycle;
      case 'person':
        return Icons.person;
      case 'pottedplant':
        return Icons.local_florist;
      case 'sheep':
        return Icons.cruelty_free;
      case 'sofa':
        return Icons.chair_alt;
      case 'train':
        return Icons.train;
      case 'tvmonitor':
        return Icons.tv;
      default:
        return Icons.help_outline;
    }
  }

  void _resetScanning() {
    setState(() {
      _isScanning = true;
      _detectedObject = null;
    });
    _startRealTimeDetection();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_controller!),
          if (!_isScanning && _detectedObject != null)
            _buildDetectedObjectUI(context),
          _buildBackButton(context),
        ],
      ),
    );
  }

  Widget _buildDetectedObjectUI(BuildContext context) {
    final box = _detectedObject!['box'] as Rect;
    final label = _detectedObject!['label'] as String;
    final icon = _detectedObject!['icon'] as IconData;
    final color = _detectedObject!['color'] as Color;

    // --- Tính toán scale và offset giữa ảnh thật & camera preview ---
    final previewSize = _controller!.value.previewSize!;
    final screenSize = MediaQuery.of(context).size;

    // Kích thước preview có thể khác tỷ lệ màn hình
    double scaleX = screenSize.width / previewSize.height;
    double scaleY = screenSize.height / previewSize.width;

    // Điều chỉnh scale cho đúng hướng (vì camera xoay ngang)
    final double left = box.left * scaleX;
    final double top = box.top * scaleY;
    final double width = (box.width) * scaleX;
    final double height = (box.height) * scaleY;

    return Center(
      // left: left,
      // top: top,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 2.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Label
            Positioned(
              top: -35,
              left: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Nút "Tìm hiểu thêm"
            Positioned(
              bottom: -35,
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ObjectDetailsScreen(label: label),
                      ),
                    );
                  },
                  icon: const Icon(Icons.info_outline),
                  label: const Text('Tìm hiểu thêm'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Positioned(
      top: 50,
      left: 20,
      child: FloatingActionButton(
        mini: true,
        onPressed: () {
          if (_isScanning) {
            Navigator.pop(context);
          } else {
            _resetScanning();
          }
        },
        backgroundColor: Colors.black.withOpacity(0.5),
        child: Icon(
          _isScanning ? Icons.arrow_back : Icons.refresh,
          color: Colors.white,
        ),
      ),
    );
  }
}
