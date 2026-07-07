/// ============================================================
/// CONFIGURE YOUR DESTINATION HERE. This is the only file
/// you should need to edit to point the app at your own sheet.
/// ============================================================
class AppConfig {
  /// The ID from your Google Sheet's URL:
  /// https://docs.google.com/spreadsheets/d/THIS_PART/edit
  static const String spreadsheetId = 'YOUR_SPREADSHEET_ID_HERE';

  /// The tab name inside the spreadsheet to append rows to.
  static const String sheetName = 'Sheet1';

  /// Path to the service account JSON key, bundled as an asset.
  /// See README.md for how to create this.
  static const String serviceAccountAssetPath = 'assets/service_account.json';

  /// Column order written to the sheet on each append.
  /// Edit this list (and SheetsService._rowFromEntry) if you want
  /// different / more columns.
  static const List<String> columnHeaders = [
    'Date Added',
    'Merchant',
    'Receipt Date',
    'Total',
    'Tax',
    'Category',
  ];
}
