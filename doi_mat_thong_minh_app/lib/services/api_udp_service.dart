import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';

/// Dịch vụ API để giao tiếp với máy chủ nhận dạng vật thể qua giao thức UDP.
class ApiUdpService {
  // --- CẤU HÌNH SERVER ---
  static const String _serverHost = "192.168.1.70"; // THAY IP NÀY
  static const int _serverPort = 9999;

  // Giới hạn kích thước gói UDP để tránh lỗi "Message too long"
  static const int _maxPacketSize = 60000;

  RawDatagramSocket? _socket;
  StreamController<Map<String, dynamic>>? _responseController;
  bool _isInitialized = false;
  bool _isDisposed = false;

  // ===================================================================
  // 🔹 KHỞI TẠO VÀ LẮNG NGHE PHẢN HỒI
  // ===================================================================
  Future<void> initialize() async {
    if (_isInitialized || _isDisposed) return;

    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      _responseController = StreamController<Map<String, dynamic>>.broadcast();

      print("✅ UDP socket đã khởi tạo ở cổng ${_socket!.port}");
      print("👂 Đang lắng nghe phản hồi JSON từ server...");

      _socket!.listen(
        (RawSocketEvent event) {
          if (event == RawSocketEvent.read && !_isDisposed) {
            final datagram = _socket!.receive();
            if (datagram != null) {
              final response = String.fromCharCodes(datagram.data);
              print("📨 [RAW SERVER RESPONSE] JSON nhận được:");
              print(response);
              print("=" * 50);

              try {
                final jsonData = json.decode(response);
                if (_responseController != null &&
                    !_responseController!.isClosed) {
                  _responseController!.add(jsonData);
                }
              } catch (e) {
                print("❌ Lỗi parse JSON: $e");
              }
            }
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          print("❌ Lỗi socket: $error");
          print("Stack trace: $stackTrace");
        },
        onDone: () {
          print("🔌 Socket đã đóng.");
        },
      );

      _isInitialized = true;
    } catch (e) {
      print("❌ Lỗi khi khởi tạo UDP socket: $e");
      _isInitialized = false;
    }
  }

  // ===================================================================
  // 🔹 GỬI "RAW FRAME" (JPEG BYTES) SANG SERVER
  // ===================================================================
  Future<void> sendRawFrame(Uint8List jpegBytes) async {
    if (_isDisposed) return;

    if (!_isInitialized) {
      await initialize();
    }

    try {
      Uint8List bytesToSend = jpegBytes;
      if (jpegBytes.length > _maxPacketSize) {
        print(
          "⚠️ Frame quá lớn (${jpegBytes.length} bytes), giảm chất lượng...",
        );
        bytesToSend = await _reduceImageQuality(jpegBytes);
      }

      _socket!.send(bytesToSend, InternetAddress(_serverHost), _serverPort);

      // Chỉ in log mỗi 20 frame để giảm spam log
      if (DateTime.now().millisecond % 500 < 20) {
        print("📸 Frame (${bytesToSend.length} bytes) đã gửi tới server");
      }
    } catch (e) {
      print("❌ Lỗi khi gửi frame UDP: $e");
    }
  }

  // ===================================================================
  // 🔹 GIẢM CHẤT LƯỢNG ẢNH NẾU QUÁ LỚN
  // ===================================================================
  Future<Uint8List> _reduceImageQuality(Uint8List originalBytes) async {
    try {
      double scale = _maxPacketSize / originalBytes.length;
      int newLength = (originalBytes.length * scale * 0.9).floor();
      return Uint8List.fromList(originalBytes.sublist(0, newLength));
    } catch (e) {
      print("❌ Lỗi khi giảm chất lượng ảnh: $e");
      return originalBytes;
    }
  }

  // ===================================================================
  // 🔹 LẮNG NGHE KẾT QUẢ JSON TỪ SERVER
  // ===================================================================
  Stream<Map<String, dynamic>> listenForServerResults() {
    if (!_isInitialized && !_isDisposed) {
      initialize();
    }
    return _responseController?.stream ?? Stream.empty();
  }

  // ===================================================================
  // 🔹 ĐÓNG KẾT NỐI
  // ===================================================================
  void dispose() {
    if (_isDisposed) return;

    _isDisposed = true;
    _socket?.close();
    _responseController?.close();
    print("🔒 Đã đóng kết nối UDP");
  }
}
