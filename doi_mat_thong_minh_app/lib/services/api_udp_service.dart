import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';

/// Dịch vụ API để giao tiếp với máy chủ nhận dạng vật thể qua giao thức UDP.
class ApiUdpService {
  // --- CẤU HÌNH SERVER ---
  // ⚠️ THAY IP NÀY BẰNG IP MÁY CHẠY udp_server.py
  static const String _serverHost = "192.168.0.155";
  static const int _serverPort = 9999;

  // ===================================================================
  // 🔹 HÀM GỬI ẢNH DẠNG BYTES (JPEG) TỚI SERVER QUA UDP
  // ===================================================================
  Future<Map<String, dynamic>?> _sendImageBytesToUdpServer(
    Uint8List imageBytes,
  ) async {
    RawDatagramSocket? socket;
    final completer = Completer<Map<String, dynamic>?>();

    try {
      // 1️⃣ Tạo socket UDP (bind vào cổng ngẫu nhiên)
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      print("✅ UDP socket đã khởi tạo ở cổng ${socket.port}");

      // 2️⃣ Gửi dữ liệu ảnh sang server
      socket.send(imageBytes, InternetAddress(_serverHost), _serverPort);
      print(
        "📤 Đã gửi ${imageBytes.length} bytes tới $_serverHost:$_serverPort",
      );

      // 3️⃣ Lắng nghe phản hồi từ server
      socket.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket!.receive();
          if (datagram != null) {
            final response = String.fromCharCodes(datagram.data);
            print("📩 Nhận phản hồi từ server: $response");

            try {
              final jsonData = json.decode(response);
              if (!completer.isCompleted) completer.complete(jsonData);
            } catch (e) {
              if (!completer.isCompleted) {
                completer.completeError("❌ Lỗi parse JSON: $e");
              }
            } finally {
              socket.close();
            }
          }
        }
      });

      // 4️⃣ Timeout 5 giây
      return completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print("⚠️ Hết thời gian chờ server UDP phản hồi.");
          socket?.close();
          if (!completer.isCompleted) completer.complete(null);
          return null;
        },
      );
    } catch (e) {
      print("❌ Lỗi khi gửi UDP: $e");
      socket?.close();
      if (!completer.isCompleted) completer.completeError(e);
      return null;
    }
  }

  // ===================================================================
  // 🔹 HÀM CÔNG KHAI (PUBLIC)
  // ===================================================================

  /// Gửi ảnh dưới dạng `File` đến server UDP để predict
  Future<Map<String, dynamic>> predictImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final result = await _sendImageBytesToUdpServer(bytes);
    if (result != null) return result;
    throw Exception("Không nhận được phản hồi hợp lệ từ server UDP.");
  }

  /// Gửi ảnh dưới dạng bytes đến server UDP
  Future<Map<String, dynamic>> predictImageBytes(Uint8List imageBytes) async {
    final result = await _sendImageBytesToUdpServer(imageBytes);
    if (result != null) return result;
    throw Exception("Không nhận được phản hồi hợp lệ từ server UDP.");
  }

  // ===================================================================
  // 🔹 THÊM HÀM NÀY ĐỂ CAMERA STREAM GỌI TRỰC TIẾP
  // ===================================================================
  /// Gửi "raw frame" (JPEG bytes) sang server để xử lý real-time.
  ///
  /// Hàm này không chờ phản hồi JSON phức tạp, chỉ cần gửi frame đi.
  /// Dùng cho chế độ stream liên tục.
  Future<void> sendRawFrame(Uint8List jpegBytes) async {
    try {
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.send(jpegBytes, InternetAddress(_serverHost), _serverPort);
      socket.close();
      print(
        "📸 Frame (${jpegBytes.length} bytes) đã gửi tới $_serverHost:$_serverPort",
      );
    } catch (e) {
      print("❌ Lỗi khi gửi frame UDP: $e");
    }
  }
}
