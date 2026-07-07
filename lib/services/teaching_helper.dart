import '../models/receipt_template.dart';
import 'receipt_matcher.dart';

/// Given the line the user tapped as "this is the total" (or date, tax, etc),
/// builds a FieldRule by looking at nearby lines for a usable keyword anchor.
/// This is what powers the teaching UI: user taps a value, we infer the rule.
class TeachingHelper {
  /// Looks backward from [tappedIndex] for the nearest line that looks like
  /// a label (short, non-numeric, e.g. "TOTAL", "DATE") to use as the anchor.
  static FieldRule inferRule(List<OcrLine> lines, int tappedIndex,
      {int searchWindow = 2}) {
    final tappedLine = lines[tappedIndex].text;

    // Case 1: the tapped line itself contains both a label-like word
    // and the value (e.g. "TOTAL   $42.17") -> same-line rule.
    final labelMatch = RegExp(r'[A-Za-z]{3,}').firstMatch(tappedLine);
    if (labelMatch != null &&
        RegExp(r'\d').hasMatch(tappedLine)) {
      final keyword = labelMatch.group(0)!;
      return FieldRule(
        keywords: [keyword.toUpperCase()],
        position: AnchorPosition.sameLine,
        pick: AnchorPick.last,
      );
    }

    // Case 2: tapped line is just a bare value -> look at preceding lines
    // for a label, and record the offset.
    for (var offset = 1; offset <= searchWindow; offset++) {
      final candidateIndex = tappedIndex - offset;
      if (candidateIndex < 0) break;
      final candidateText = lines[candidateIndex].text;
      final label = RegExp(r'[A-Za-z]{3,}').firstMatch(candidateText);
      if (label != null && !RegExp(r'\d').hasMatch(candidateText)) {
        return FieldRule(
          keywords: [label.group(0)!.toUpperCase()],
          position: AnchorPosition.nextLine,
          pick: AnchorPick.last,
          lineOffset: offset,
        );
      }
    }

    // Fallback: no clear label found nearby. Anchor on the tapped value
    // itself won't generalize well -- flag this so the UI can ask the
    // user to tap the label line explicitly instead.
    throw StateError(
        'No label found near tapped line. Ask user to tap the label instead.');
  }
}
