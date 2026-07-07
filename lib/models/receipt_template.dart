/// Data model for a per-store receipt parsing template.
/// Rules are anchor-based (keyword + relative offset), not tied to
/// absolute line numbers, so they survive variable receipt length.

enum AnchorPosition {
  sameLine,   // value sits on the same line as the keyword
  nextLine,   // value sits N lines after the keyword line
  sameLineOrNext, // try same line first, fall back to next line
}

enum AnchorPick {
  first,  // use the first matching keyword occurrence
  last,   // use the last matching keyword occurrence (good for totals)
}

class FieldRule {
  final List<String> keywords; // priority list, e.g. ["TOTAL", "AMOUNT DUE"]
  final AnchorPosition position;
  final AnchorPick pick;
  final int lineOffset; // used when position == nextLine (default 1)
  final String? regexOverride; // optional custom regex for value extraction

  const FieldRule({
    required this.keywords,
    this.position = AnchorPosition.sameLineOrNext,
    this.pick = AnchorPick.last,
    this.lineOffset = 1,
    this.regexOverride,
  });

  Map<String, dynamic> toJson() => {
        'keywords': keywords,
        'position': position.name,
        'pick': pick.name,
        'lineOffset': lineOffset,
        'regexOverride': regexOverride,
      };

  factory FieldRule.fromJson(Map<String, dynamic> json) => FieldRule(
        keywords: List<String>.from(json['keywords']),
        position: AnchorPosition.values.byName(json['position']),
        pick: AnchorPick.values.byName(json['pick']),
        lineOffset: json['lineOffset'] ?? 1,
        regexOverride: json['regexOverride'],
      );
}

class StoreTemplate {
  final String merchantMatch; // substring or alias to identify the store
  final List<String> aliases; // alternate spellings OCR might produce
  final FieldRule dateRule;
  final FieldRule totalRule;
  final FieldRule? taxRule;
  final String defaultCategory;

  const StoreTemplate({
    required this.merchantMatch,
    this.aliases = const [],
    required this.dateRule,
    required this.totalRule,
    this.taxRule,
    this.defaultCategory = 'Uncategorized',
  });

  Map<String, dynamic> toJson() => {
        'merchantMatch': merchantMatch,
        'aliases': aliases,
        'dateRule': dateRule.toJson(),
        'totalRule': totalRule.toJson(),
        'taxRule': taxRule?.toJson(),
        'defaultCategory': defaultCategory,
      };

  factory StoreTemplate.fromJson(Map<String, dynamic> json) => StoreTemplate(
        merchantMatch: json['merchantMatch'],
        aliases: List<String>.from(json['aliases'] ?? []),
        dateRule: FieldRule.fromJson(json['dateRule']),
        totalRule: FieldRule.fromJson(json['totalRule']),
        taxRule:
            json['taxRule'] != null ? FieldRule.fromJson(json['taxRule']) : null,
        defaultCategory: json['defaultCategory'] ?? 'Uncategorized',
      );
}
