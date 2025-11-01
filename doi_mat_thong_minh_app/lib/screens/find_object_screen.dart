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
  // THAY ĐỔI 1: Lưu danh sách các vật thể thay vì chỉ một
  List<Map<String, dynamic>> _detectedObjects = [];
  Timer? _detectionTimer;
  bool _isTakingPicture = false;

  // THAY ĐỔI 2: Thêm biến để lưu vật thể đang được chọn
  String? _selectedObjectLabel;

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

  // THAY ĐỔI 3: Cập nhật logic để xử lý tất cả các vật thể
  void _startRealTimeDetection() {
    const duration = Duration(seconds: 5);
    _detectionTimer = Timer.periodic(duration, (timer) async {
      if (!mounted ||
          _controller == null ||
          !_controller!.value.isInitialized) {
        timer.cancel();
        return;
      }

      if (_isTakingPicture) return;

      _isTakingPicture = true;
      try {
        final image = await _controller!.takePicture();
        final responseData = await _apiService.predictImage(File(image.path));

        if (responseData['objects'] != null &&
            responseData['objects'].isNotEmpty) {
          // Xử lý tất cả các vật thể trả về
          final List<Map<String, dynamic>> detected = [];
          for (var obj in responseData['objects']) {
            detected.add({
              'label': obj['label'],
              'box': Rect.fromLTRB(
                obj['box'][0].toDouble(),
                obj['box'][1].toDouble(),
                obj['box'][2].toDouble(),
                obj['box'][3].toDouble(),
              ),
              'icon': _getIconForLabel(obj['label']),
              'color': Colors.cyan,
            });
          }

          if (mounted) {
            setState(() {
              _isScanning = false;
              _detectedObjects = detected; // Lưu danh sách
            });
            timer.cancel(); // Dừng quét sau khi đã xử lý xong
          }
        }
      } catch (e) {
        print("Lỗi khi gửi ảnh đến server: $e");
      } finally {
        _isTakingPicture = false;
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

  // THAY ĐỔI 4: Cập nhật hàm reset để xóa danh sách và lựa chọn
  void _resetScanning() {
    setState(() {
      _isScanning = true;
      _detectedObjects = [];
      _selectedObjectLabel = null;
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
          if (!_isScanning && _detectedObjects.isNotEmpty)
            _buildDetectedObjectsUI(context),
          _buildBackButton(context),
          // THAY ĐỔI 5: Thêm nút "Tìm hiểu thêm" chung cho màn hình
          if (!_isScanning && _selectedObjectLabel != null)
            _buildLearnMoreButton(context),
        ],
      ),
    );
  }

  // THAY ĐỔI 6: Vẽ tất cả các hộp và cho phép chạm để chọn
  Widget _buildDetectedObjectsUI(BuildContext context) {
    final previewSize = _controller!.value.previewSize!;
    final screenSize = MediaQuery.of(context).size;
    // Lấy hướng của thiết bị
    final orientation = MediaQuery.of(context).orientation;

    double scaleX = screenSize.width / previewSize.height;
    double scaleY = screenSize.height / previewSize.width;

    // Hệ số thu nhỏ chiều cao khi ở chế độ ngang. Bạn có thể điều chỉnh giá trị này.
    const double landscapeHeightScale = 0.8;

    return Stack(
      children: _detectedObjects.map((obj) {
        final box = obj['box'] as Rect;
        final label = obj['label'] as String;
        final icon = obj['icon'] as IconData;
        final color = obj['color'] as Color;

        // Đổi màu nếu vật thể được chọn
        final finalColor = (_selectedObjectLabel == label)
            ? Colors.yellow
            : color;

        final double left = box.left * scaleX;
        final double top = box.top * scaleY;
        double width = (box.width) * scaleX;
        double height = (box.height) * scaleY;

        // === ĐIỀU KIỆN ĐẶC BIỆT ===
        // Kiểm tra xem thiết bị có đang ở chế độ ngang không
        // VÀ hộp có phải là hộp dọc (chiều cao lớn hơn chiều rộng) không
        if (orientation == Orientation.landscape && height > width) {
          // Nếu đúng, thu nhỏ chiều cao của hộp lại
          height = height * landscapeHeightScale;
          // (Tùy chọn) Dịch chuyển hộp lên một chút để nó không bị lệch về dưới sau khi thu nhỏ
          // top = top - (box.height * scaleY * (1 - landscapeHeightScale) / 2);
        }

        return Positioned(
          left: left,
          top: top,
          child: GestureDetector(
            onTap: () {
              // Cập nhật vật thể được chọn khi chạm vào
              setState(() {
                _selectedObjectLabel = label;
              });
            },
            child: Container(
              width: width,
              height: height, // Sử dụng chiều cao đã được điều chỉnh
              decoration: BoxDecoration(
                border: Border.all(color: finalColor, width: 2.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: -35,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: finalColor,
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
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // THAY ĐỔI 7: Nút "Tìm hiểu thêm" được tách ra và nằm ở dưới màn hình
  Widget _buildLearnMoreButton(BuildContext context) {
    return Positioned(
      bottom: 50,
      left: 20,
      right: 20,
      child: ElevatedButton.icon(
        onPressed: () {
          if (_selectedObjectLabel != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ObjectDetailsScreen(label: _selectedObjectLabel!),
              ),
            );
          }
        },
        icon: const Icon(Icons.info_outline),
        label: const Text('Tìm hiểu thêm'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.cyan,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
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
