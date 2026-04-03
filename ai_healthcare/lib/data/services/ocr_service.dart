import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  static final OcrService _instance = OcrService._internal();
  factory OcrService() => _instance;
  OcrService._internal();

  final _textRecognizer = TextRecognizer();

  /// Extract text from an image file path (mobile only)
  Future<String> extractTextFromImage(String imagePath) async {
    if (kIsWeb) {
      // ML Kit doesn't work on web — caller should use Gemini Vision instead
      return '';
    }

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      final buffer = StringBuffer();
      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          buffer.writeln(line.text);
        }
        buffer.writeln(); // Paragraph break
      }

      return buffer.toString().trim();
    } catch (e) {
      debugPrint('OCR Error: $e');
      return '';
    }
  }

  void dispose() {
    _textRecognizer.close();
  }
}
