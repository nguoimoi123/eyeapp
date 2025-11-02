// lib/services/api_service.dart
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  // THAY THẾ <YOUR_IP_ADDRESS> BẰNG ĐỊA CHỈ IP CỦA BẠN
  static const String _baseUrl = "http://192.168.0.155:8000";

  // --- CÁC HÀM CŨ CHO ẢNH ---
  // Hàm gửi ảnh đến endpoint /describe
  Future<Map<String, dynamic>> describeImage(File imageFile) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/describe'),
    );
    request.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path),
    );

    var res = await request.send();
    var responseBody = await res.stream.bytesToString();

    if (res.statusCode == 200) {
      // Parse JSON thành Map
      return json.decode(responseBody);
    } else {
      throw Exception('Failed to load description: ${res.statusCode}');
    }
  }

  // Hàm gửi ảnh đến endpoint /predict
  Future<Map<String, dynamic>> predictImage(File imageFile) async {
    var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/predict'));
    request.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path),
    );

    var res = await request.send();
    var responseBody = await res.stream.bytesToString();

    if (res.statusCode == 200) {
      return json.decode(responseBody);
    } else {
      throw Exception('Failed to get predictions: ${res.statusCode}');
    }
  }

  // --- HÀM MỚI CHO VIDEO ---
  /// Gửi video lên server để phân tích và tạo câu hỏi quiz
  Future<Map<String, dynamic>> analyzeVideo(File videoFile) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/analyze_video'), // Endpoint mới cho video
    );

    // Thêm file video vào request. Tên field 'file' phải khớp với server.
    request.files.add(
      await http.MultipartFile.fromPath('file', videoFile.path),
    );

    try {
      // Gửi request và đặt timeout dài hơn cho video (ví dụ: 5 phút)
      var streamedResponse = await request.send().timeout(
        const Duration(minutes: 5),
      );

      var responseBody = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode == 200) {
        // Server trả về JSON chứa danh sách các câu hỏi
        return json.decode(responseBody);
      } else {
        throw Exception(
          'Failed to analyze video. Status code: ${streamedResponse.statusCode}',
        );
      }
    } catch (e) {
      // Bắt lỗi timeout hoặc các lỗi mạng khác
      throw Exception('Failed to analyze video: $e');
    }
  }
}
