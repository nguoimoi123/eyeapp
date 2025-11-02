// lib/screens/quiz_challenge_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
import 'dart:math';

// Import ApiService của bạn
import '../services/api_service.dart';

// Model để đại diện cho một câu hỏi
class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctAnswerIndex;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
  });
}

class QuizChallengeScreen extends StatefulWidget {
  const QuizChallengeScreen({super.key}); // <<< SỬA ĐỔI: Thêm key

  @override
  State<QuizChallengeScreen> createState() => _QuizChallengeScreenState();
}

class _QuizChallengeScreenState extends State<QuizChallengeScreen> {
  final ApiService _apiService = ApiService();
  final int _maxVideoDurationSeconds = 20;

  // State cho việc tải video
  File? _selectedVideo;
  bool _isUploading = false;
  String? _uploadError;

  // State cho Quiz
  List<QuizQuestion> _questions = [];
  int _currentQuestionIndex = 0;
  int? _selectedAnswerIndex;
  int _score = 0;
  bool _isQuizCompleted = false;

  // Danh sách tất cả các vật thể có thể có
  final List<String> _allPossibleObjects = [
    'aeroplane',
    'bicycle',
    'bird',
    'boat',
    'bottle',
    'bus',
    'car',
    'cat',
    'chair',
    'cow',
    'diningtable',
    'dog',
    'horse',
    'motorbike',
    'person',
    'pottedplant',
    'sheep',
    'sofa',
    'train',
    'tvmonitor',
  ];

  @override
  Widget build(BuildContext context) {
    if (_selectedVideo == null) {
      return _buildVideoPickerScreen();
    }
    if (_isUploading) {
      return _buildUploadingScreen();
    }
    if (_uploadError != null) {
      return _buildErrorScreen();
    }
    if (_questions.isEmpty) {
      return _buildWaitingForQuizScreen();
    }
    if (_isQuizCompleted) {
      return _buildResultScreen();
    }
    return _buildQuizScreen();
  }

  // --- Màn hình chọn video ---
  Widget _buildVideoPickerScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FC),
        elevation: 0,
        title: Text(
          'Thử thách video',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Symbols.video_file, size: 80, color: Colors.grey[600]),
              const SizedBox(height: 20),
              Text(
                'Chọn một video (dưới $_maxVideoDurationSeconds giây) để bắt đầu thử thách!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: _pickAndValidateVideo, // <<< SỬA ĐỔI: Đã sửa hàm này
                icon: const Icon(Icons.upload_file),
                label: const Text('Chọn Video'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A90E2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Màn hình đang tải lên ---
  Widget _buildUploadingScreen() {
    return const Scaffold(
      // <<< SỬA ĐỔI: Thêm key
      backgroundColor: const Color(0xFFF7F8FC),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              "Đang tải video lên và tạo câu hỏi...\nĐây có thể mất vài phút.",
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // --- Màn hình lỗi ---
  Widget _buildErrorScreen() {
    return Scaffold(
      // <<< SỬA ĐỔI: Thêm key
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FC),
        elevation: 0,
        title: Text(
          'Lỗi',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Symbols.error, size: 80, color: Colors.red[600]),
              const SizedBox(height: 20),
              Text(
                _uploadError!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: _resetToPicker, // <<< SỬA ĐỔI: Dùng hàm reset
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Màn hình chờ quiz ---
  Widget _buildWaitingForQuizScreen() {
    return _buildUploadingScreen(); // Có thể dùng chung UI
  }

  // --- Màn hình chính của Quiz ---
  Widget _buildQuizScreen() {
    final currentQuestion = _questions[_currentQuestionIndex];
    return Scaffold(
      // <<< SỬA ĐỔI: Thêm key
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black54),
          onPressed: _resetToPicker, // <<< SỬA ĐỔI: Dùng hàm reset
        ),
        title: Text(
          'Thử thách video',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Câu hỏi ${_currentQuestionIndex + 1}/4',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: LinearProgressIndicator(
                    value: (_currentQuestionIndex + 1) / 4,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF4A90E2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hiển thị tên file video
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05), // <<< SỬA ĐỔI
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Symbols.video_file, color: Colors.blue[700]),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _selectedVideo!.path.split('/').last,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              currentQuestion.question,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: ListView.builder(
                itemCount: currentQuestion.options.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildAnswerButton(
                      currentQuestion.options[index],
                      index,
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: _selectedAnswerIndex != null ? _confirmAnswer : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A90E2),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Xác nhận',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Màn hình kết quả ---
  Widget _buildResultScreen() {
    return Scaffold(
      // <<< SỬA ĐỔI: Thêm key
      backgroundColor: const Color(0xFFF7F8FC),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _score >= 2
                    ? Symbols.emoji_events
                    : Symbols.sentiment_dissatisfied,
                size: 100,
                color: _score >= 2 ? Colors.amber : Colors.grey,
              ),
              const SizedBox(height: 20),
              Text(
                'Hoàn thành!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Bạn đã trả lời đúng $_score/4 câu',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _resetQuiz, // <<< SỬA ĐỔI: Dùng hàm reset
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A90E2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Chơi lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Các widget con ---
  Widget _buildAnswerButton(String answer, int index) {
    final isSelected = _selectedAnswerIndex == index;
    return ElevatedButton(
      // <<< SỬA ĐỔI: Thêm key
      onPressed: () {
        setState(() {
          _selectedAnswerIndex = index;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected
            ? const Color(0xFF4A90E2).withValues(alpha: 0.2) // <<< SỬA ĐỔI
            : Colors.white,
        foregroundColor: Colors.black87,
        side: BorderSide(
          color: isSelected ? const Color(0xFF4A90E2) : Colors.grey.shade300,
          width: 2,
        ),
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        '${String.fromCharCode(65 + index)}. $answer',
        style: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  // --- Các hàm xử lý logic ---
  Future<void> _pickAndValidateVideo() async {
    // <<< SỬA ĐỔI: Đã sửa hàm này
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );

    if (result != null && result.files.single.path != null) {
      final videoFile = File(result.files.single.path!);
      final controller = VideoPlayerController.file(videoFile);
      await controller.initialize();

      if (controller.value.duration.inSeconds > _maxVideoDurationSeconds) {
        // <<< SỬA ĐỔI: Hiển thị lỗi bằng SnackBar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Video quá dài! Vui lòng chọn video ngắn hơn $_maxVideoDurationSeconds giây.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        controller.dispose();
        return;
      }

      controller.dispose();

      setState(() {
        _selectedVideo = videoFile;
        _uploadError = null;
      });
      _uploadVideoAndGenerateQuiz();
    }
  }

  Future<void> _uploadVideoAndGenerateQuiz() async {
    setState(() {
      _isUploading = true;
    });

    try {
      Map<String, dynamic> responseData = await _apiService.analyzeVideo(
        _selectedVideo!,
      );

      List<dynamic> questionsData = responseData['questions'];
      List<QuizQuestion> parsedQuestions = [];

      for (var qData in questionsData) {
        String correctAnswer = qData['options'][qData['correct_answer_index']];
        List<String> allOptions = _generateOptions(correctAnswer);

        parsedQuestions.add(
          QuizQuestion(
            question: qData['question'],
            options: allOptions,
            correctAnswerIndex: allOptions.indexOf(correctAnswer),
          ),
        );
      }

      setState(() {
        _questions = parsedQuestions;
        _currentQuestionIndex = 0;
        _isUploading = false;
      });
    } catch (e) {
      print(e);
      setState(() {
        _isUploading = false;
        _uploadError = "Có lỗi xảy ra khi xử lý video: $e";
      });
    }
  }

  List<String> _generateOptions(String correctAnswer) {
    List<String> options = [correctAnswer];
    Random random = Random();

    if (correctAnswer.replaceAll(RegExp(r'[^0-9]'), '').isNotEmpty) {
      int correctNum = int.tryParse(correctAnswer) ?? 0;
      Set<int> usedNumbers = {correctNum};

      while (options.length < 4) {
        int offset = random.nextInt(5) + 1;
        int wrongAnswer = random.nextBool()
            ? correctNum + offset
            : correctNum - offset;
        if (wrongAnswer > 0 && !usedNumbers.contains(wrongAnswer)) {
          options.add(wrongAnswer.toString());
          usedNumbers.add(wrongAnswer);
        }
      }
    } else {
      Set<String> usedNames = {correctAnswer};
      List<String> shuffledObjects = List.from(_allPossibleObjects)
        ..shuffle(random);

      for (String obj in shuffledObjects) {
        if (!usedNames.contains(obj)) {
          options.add(obj);
          usedNames.add(obj);
        }
        if (options.length == 4) break;
      }
    }

    options.shuffle();
    return options;
  }

  void _confirmAnswer() {
    if (_selectedAnswerIndex == null) return;

    bool isCorrect =
        _selectedAnswerIndex ==
        _questions[_currentQuestionIndex].correctAnswerIndex;
    if (isCorrect) {
      _score++;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(isCorrect ? 'Chính xác!' : 'Chưa đúng!'),
        content: Text(
          isCorrect
              ? 'Bạn thật tinh mắt!'
              : 'Đáp án đúng là ${_questions[_currentQuestionIndex].options[_questions[_currentQuestionIndex].correctAnswerIndex]}.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _nextQuestion();
            },
            child: const Text('Tiếp tục'),
          ),
        ],
      ),
    );
  }

  void _nextQuestion() {
    setState(() {
      _selectedAnswerIndex = null;
      if (_currentQuestionIndex < 3) {
        _currentQuestionIndex++;
      } else {
        _isQuizCompleted = true;
      }
    });
  }

  // <<< SỬA ĐỔI: Thêm các hàm reset để code gọn gàng
  void _resetToPicker() {
    setState(() {
      _selectedVideo = null;
      _uploadError = null;
      _questions = [];
      _currentQuestionIndex = 0;
      _score = 0;
      _selectedAnswerIndex = null;
      _isQuizCompleted = false;
    });
  }

  void _resetQuiz() {
    setState(() {
      _currentQuestionIndex = 0;
      _score = 0;
      _selectedAnswerIndex = null;
      _isQuizCompleted = false;
    });
  }
}
