import '../models/receipt_template.dart';

/// A single line of recognized text with position info.
/// Built from ML Kit's RecognizedText in ocr_service.dart, but kept as a
/// plain class here so matching logic has no direct ML Kit dependency.
class OcrLine {
  final String text;
  final double top;
  final double left;

  OcrLine(this.text, {this.top = 0, this.left = 0});
}

class FieldMatchResult {
  final String? value;
  final bool matched;
  final int? anchorLineIndex;

  FieldMatchResult({this.value, this.matched = false, this.anchorLineIndex});
}

class ReceiptParseResult {
  final String? merchant;
  final String? date;
  final String? total;
  final String? tax;
  final String category;
  final bool needsReview;

  ReceiptParseResult({
    this.merchant,
    this.date,
    this.total,
    this.tax,
    required this.category,
    required this.needsReview,
  });
}

class ReceiptMatcher {
  static List<int> _findAnchorLines(List<OcrLine> lines, List<String> keywords) {
    final matches = <int>[];
    for (var i = 0; i < lines.length; i++) {
      final upper = lines[i].text.toUpperCase();
      for (final kw in keywords) {
        if (upper.contains(kw.toUpperCase())) {
          matches.add(i);
          break;
        }
      }
    }
    return matches;
  }

  static String? _extractValue(String line, String? regexOverride) {
    final pattern = regexOverride ?? r'\$?\d+[.,]\d{2}';
    final match = RegExp(pattern).firstMatch(line);
    return match?.group(0);
  }

  static FieldMatchResult applyRule(List<OcrLine> lines, FieldRule rule) {
    final anchors = _findAnchorLines(lines, rule.keywords);
    if (anchors.isEmpty) return FieldMatchResult(matched: false);

    final anchorIndex = rule.pick == AnchorPick.last ? anchors.last : anchors.first;

    if (rule.position == AnchorPosition.sameLine ||
        rule.position == AnchorPosition.sameLineOrNext) {
      final value = _extractValue(lines[anchorIndex].text, rule.regexOverride);
      if (value != null) {
        return FieldMatchResult(value: value, matched: true, anchorLineIndex: anchorIndex);
      }
    }

    if (rule.position == AnchorPosition.nextLine ||
        rule.position == AnchorPosition.sameLineOrNext) {
      final targetIndex = anchorIndex + rule.lineOffset;
      if (targetIndex >= 0 && targetIndex < lines.length) {
        final value = _extractValue(lines[targetIndex].text, rule.regexOverride);
        if (value != null) {
          return FieldMatchResult(value: value, matched: true, anchorLineIndex: targetIndex);
        }
      }
    }

    return FieldMatchResult(matched: false, anchorLineIndex: anchorIndex);
  }

  static StoreTemplate? identifyStore(List<OcrLine> lines, List<StoreTemplate> knownTemplates) {
    final headerLines = lines.take(5).map((l) => l.text.toUpperCase());
    for (final template in knownTemplates) {
      final candidates =
          [template.merchantMatch, ...template.aliases].map((s) => s.toUpperCase());
      for (final header in headerLines) {
        for (final candidate in candidates) {
          if (header.contains(candidate)) return template;
        }
      }
    }
    return null;
  }

  static ReceiptParseResult parse(List<OcrLine> lines, StoreTemplate template) {
    final dateResult = applyRule(lines, template.dateRule);
    final totalResult = applyRule(lines, template.totalRule);
    final taxResult = template.taxRule != null ? applyRule(lines, template.taxRule!) : null;

    return ReceiptParseResult(
      merchant: template.merchantMatch,
      date: dateResult.value,
      total: totalResult.value,
      tax: taxResult?.value,
      category: template.defaultCategory,
      needsReview: !dateResult.matched || !totalResult.matched,
    );
  }
}
