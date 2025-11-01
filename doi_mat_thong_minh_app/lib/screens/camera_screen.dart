// lib/screens/camera_screen.dart
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart'; // Thêm lại để chọn từ thư viện
import 'package:image/image.dart' as img;
import 'dart:io';
import 'dart:typed_data';
import 'loading_screen.dart';
import 'package:exif/exif.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  int _currentCameraIndex = 0; // 0 là camera sau, 1 là camera trước
  FlashMode _flashMode = FlashMode.off; // Trạng thái flash

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
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    await Permission.camera.request();
    _cameras = await availableCameras();
    if (_cameras.isEmpty) {
      print('No cameras found');
      return;
    }
    await _setupCamera(_cameras[_currentCameraIndex]);
  }

  Future<void> _setupCamera(CameraDescription cameraDescription) async {
    _controller = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _controller!.initialize();
    if (mounted) {
      setState(() {
        _isCameraInitialized = true;
      });
    }
  }

  // Hàm xử lý ảnh (từ camera hoặc thư viện)
  Future<void> _handleImage(File imageFile) async {
    try {
      final Uint8List resizedImageBytes = await _resizeImage(imageFile.path);
      final Directory tempDir = Directory.systemTemp;
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final File resizedFile = File('${tempDir.path}/$fileName');
      await resizedFile.writeAsBytes(resizedImageBytes);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LoadingScreen(imageFile: resizedFile),
          ),
        );
      }
    } catch (e) {
      print(e);
    }
  }

  // Chụp ảnh
  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    final XFile photo = await _controller!.takePicture();
    await _handleImage(File(photo.path));
  }

  // Chọn ảnh từ thư viện
  Future<void> _pickImageFromGallery() async {
    final XFile? pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      await _handleImage(File(pickedFile.path));
    }
  }

  // Resize ảnh và xử lý xoay theo EXIF
  Future<Uint8List> _resizeImage(String filePath) async {
    final File imageFile = File(filePath);
    final Uint8List imageBytes = await imageFile.readAsBytes();

    // Giải mã ảnh để lấy dữ liệu gốc
    final img.Image? originalImage = img.decodeImage(imageBytes);
    if (originalImage == null) return imageBytes;

    // Đọc dữ liệu EXIF từ byte của ảnh
    final exifData = await readExifFromBytes(imageBytes);
    img.Image orientedImage = originalImage; // Bắt đầu với ảnh gốc

    if (exifData != null && exifData.containsKey('Image Orientation')) {
      // Lấy giá trị hướng từ EXIF
      final orientationValue = exifData['Image Orientation']?.printable;

      // Áp dụng xoay dựa trên hướng EXIF
      switch (orientationValue) {
        case '6': // Xoay 90 độ theo chiều kim đồng hồ
          orientedImage = img.copyRotate(originalImage, angle: 90);
          break;
        case '8': // Xoay 90 độ ngược chiều kim đồng hồ
          orientedImage = img.copyRotate(originalImage, angle: -90);
          break;
        case '3': // Xoay 180 độ
          orientedImage = img.copyRotate(originalImage, angle: 180);
          break;
        // '1' là bình thường, không cần xoay
      }
    }

    // Giờ thì resize ảnh đã được xoay đúng chiều
    final img.Image resizedImage = img.copyResize(orientedImage, width: 800);

    // Mã hóa và trả về. Ảnh mới sẽ có hướng mặc định (1).
    return Uint8List.fromList(img.encodeJpg(resizedImage, quality: 85));
  }

  // Lật camera
  Future<void> _flipCamera() async {
    if (_cameras.length < 2) return;
    _currentCameraIndex = (_currentCameraIndex + 1) % _cameras.length;
    await _setupCamera(_cameras[_currentCameraIndex]);
  }

  // Bật/Tắt flash
  Future<void> _toggleFlash() async {
    if (_controller == null) return;
    FlashMode newFlashMode;
    switch (_flashMode) {
      case FlashMode.off:
        newFlashMode = FlashMode.auto;
        break;
      case FlashMode.auto:
        newFlashMode = FlashMode.always;
        break;
      case FlashMode.always:
        newFlashMode = FlashMode.off;
        break;
      default:
        newFlashMode = FlashMode.off;
    }
    await _controller!.setFlashMode(newFlashMode);
    setState(() {
      _flashMode = newFlashMode;
    });
  }

  // Lấy icon cho flash
  IconData _getFlashIcon() {
    switch (_flashMode) {
      case FlashMode.off:
        return Icons.flash_off;
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.always:
        return Icons.flash_on;
      default:
        return Icons.flash_off;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [CameraPreview(_controller!), _buildOverlay()],
      ),
    );
  }

  Widget _buildOverlay() {
    return Column(
      children: [
        SafeArea(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Nút Flash
                IconButton(
                  icon: Icon(_getFlashIcon(), color: Colors.white),
                  onPressed: _toggleFlash,
                ),
                // Nút Cài đặt
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        Container(
          color: Colors.black.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Nút Thư viện
              IconButton(
                icon: const Icon(Icons.photo_library, color: Colors.white),
                onPressed: _pickImageFromGallery,
              ),
              // Nút Chụp
              GestureDetector(
                onTap: _takePicture,
                child: Container(
                  height: 70,
                  width: 70,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 40,
                    color: Colors.black,
                  ),
                ),
              ),
              // Nút Lật camera
              IconButton(
                icon: const Icon(
                  Icons.flip_camera_android,
                  color: Colors.white,
                ),
                onPressed: _flipCamera,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
