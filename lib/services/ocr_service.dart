import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'receipt_matcher.dart';

/// Runs on-device OCR (free, no API calls) and flattens the result into
/// a single top-to-bottom ordered list of OcrLine, which is what
/// ReceiptMatcher expects.
class OcrService {
  final TextRecognizer _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  /// [imagePath] is the local file path returned by the camera.
  Future<List<OcrLine>> recognizeLines(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final RecognizedText result = await _recognizer.processImage(inputImage);

    final lines = <OcrLine>[];
    for (final block in result.blocks) {
      for (final line in block.lines) {
        lines.add(OcrLine(
          line.text,
          top: line.boundingBox.top.toDouble(),
          left: line.boundingBox.left.toDouble(),
        ));
      }
    }

    // ML Kit generally returns lines in reading order already, but block
    // order can be unreliable on cluttered receipts, so we re-sort by
    // vertical position (top to bottom) as a safety net. This is what
    // keeps line-offset rules ("next line after TOTAL") reliable.
    lines.sort((a, b) => a.top.compareTo(b.top));

    return lines;
  }

  Future<void> dispose() async {
    await _recognizer.close();
  }
}
