import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:googleapis_auth/auth_io.dart';
import '../config.dart';
import 'receipt_matcher.dart';

/// Writes parsed receipt data to the Google Sheet configured in config.dart.
///
/// NOTE on security: this authenticates directly from the service account
/// JSON bundled as an asset, which means the key ships inside the app.
/// That's fine for a personal/testing build you install on your own
/// device. If you ever distribute this app to other people, move this
/// logic to a small backend instead and call that backend from the app,
/// so the private key never leaves your server.
class SheetsService {
  sheets.SheetsApi? _api;

  Future<void> _ensureAuthed() async {
    if (_api != null) return;

    final jsonStr = await rootBundle.loadString(AppConfig.serviceAccountAssetPath);
    final credentials = ServiceAccountCredentials.fromJson(jsonDecode(jsonStr));

    final client = await clientViaServiceAccount(
      credentials,
      [sheets.SheetsApi.spreadsheetsScope],
    );

    _api = sheets.SheetsApi(client);
  }

  /// Ensures the header row exists. Safe to call every time the app starts;
  /// it only writes headers if row 1 looks empty.
  Future<void> ensureHeaderRow({
    required String spreadsheetId,
    required String sheetName,
  }) async {
    await _ensureAuthed();
    final range = '$sheetName!A1:${_colLetter(AppConfig.columnHeaders.length)}1';

    final existing = await _api!.spreadsheets.values.get(spreadsheetId, range);
    final isEmpty = existing.values == null || existing.values!.isEmpty;

    if (isEmpty) {
      await _api!.spreadsheets.values.update(
        sheets.ValueRange(values: [AppConfig.columnHeaders]),
        spreadsheetId,
        range,
        valueInputOption: 'USER_ENTERED',
      );
    }
  }

  String _colLetter(int count) {
    // Simple A, B, C... generator, good enough for small fixed column counts.
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    return letters[count - 1];
  }

  /// Appends one row built from a parsed + user-confirmed receipt.
  Future<void> appendReceipt({
    required String spreadsheetId,
    required String sheetName,
    required String merchant,
    required String? date,
    required String? total,
    required String? tax,
    required String category,
  }) async {
    await _ensureAuthed();

    final now = DateTime.now().toIso8601String();
    final row = [
      now,
      merchant,
      date ?? '',
      total ?? '',
      tax ?? '',
      category,
    ];

    final range = '$sheetName!A:${_colLetter(AppConfig.columnHeaders.length)}';

    await _api!.spreadsheets.values.append(
      sheets.ValueRange(values: [row]),
      spreadsheetId,
      range,
      valueInputOption: 'USER_ENTERED',
      insertDataOption: 'INSERT_ROWS',
    );
  }

  /// Reads the service account's client_email out of the bundled asset, so
  /// the Settings screen can show the user exactly what to share their
  /// sheet with — without them having to open the JSON file themselves.
  Future<String?> readServiceAccountEmail() async {
    final jsonStr = await rootBundle.loadString(AppConfig.serviceAccountAssetPath);
    final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
    return decoded['client_email'] as String?;
  }
}
