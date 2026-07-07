import 'package:hive_flutter/hive_flutter.dart';

/// Stores the user-configurable destination (which spreadsheet/tab to
/// append receipts to) in Hive, so it can be set and changed from within
/// the app instead of requiring a source edit + rebuild.
class SettingsStore {
  static const String _boxName = 'app_settings';
  static const String _spreadsheetIdKey = 'spreadsheetId';
  static const String _sheetNameKey = 'sheetName';

  Box? _box;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  Box get _requireBox {
    if (_box == null) {
      throw StateError('SettingsStore.init() must be called before use.');
    }
    return _box!;
  }

  String? get spreadsheetId => _requireBox.get(_spreadsheetIdKey) as String?;

  String get sheetName =>
      (_requireBox.get(_sheetNameKey) as String?) ?? 'Sheet1';

  bool get isConfigured =>
      spreadsheetId != null && spreadsheetId!.trim().isNotEmpty;

  Future<void> save({
    required String spreadsheetId,
    required String sheetName,
  }) async {
    await _requireBox.put(_spreadsheetIdKey, spreadsheetId.trim());
    await _requireBox.put(
      _sheetNameKey,
      sheetName.trim().isEmpty ? 'Sheet1' : sheetName.trim(),
    );
  }
}
