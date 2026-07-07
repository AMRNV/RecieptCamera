/// ============================================================
/// App-wide constants. The destination spreadsheet ID and tab name
/// are configured from within the app (see SettingsScreen /
/// SettingsStore) rather than hardcoded here.
/// ============================================================
class AppConfig {
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
