// lib/services/api_service.dart
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert'; // Thêm thư viện này

class ApiService {
  // THAY THẾ <YOUR_IP_ADDRESS> BẰNG ĐỊA CHỈ IP CỦA BẠN
  static const String _baseUrl = "http://192.168.0.155:8000";

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
}
