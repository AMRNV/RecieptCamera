import 'package:flutter/material.dart';
import '../services/settings_store.dart';
import '../services/sheets_service.dart';

/// Lets the user point the app at their own Google Sheet: paste either a
/// full sheet URL or just the ID, plus the tab name to append rows to.
class SettingsScreen extends StatefulWidget {
  final SettingsStore settingsStore;
  final SheetsService sheetsService;

  const SettingsScreen({
    super.key,
    required this.settingsStore,
    required this.sheetsService,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _spreadsheetController;
  late final TextEditingController _sheetNameController;

  String? _serviceAccountEmail;
  bool _testing = false;
  String? _testResult;
  bool _testFailed = false;

  @override
  void initState() {
    super.initState();
    _spreadsheetController =
        TextEditingController(text: widget.settingsStore.spreadsheetId ?? '');
    _sheetNameController =
        TextEditingController(text: widget.settingsStore.sheetName);
    _loadServiceAccountEmail();
  }

  Future<void> _loadServiceAccountEmail() async {
    try {
      final email = await widget.sheetsService.readServiceAccountEmail();
      if (mounted) setState(() => _serviceAccountEmail = email);
    } catch (_) {
      // Non-fatal: just means we can't show the hint.
    }
  }

  /// Accepts either a bare ID or a full sheet URL and pulls out the ID.
  String _extractSpreadsheetId(String input) {
    final trimmed = input.trim();
    final match = RegExp(r'/spreadsheets/d/([a-zA-Z0-9-_]+)').firstMatch(trimmed);
    return match != null ? match.group(1)! : trimmed;
  }

  Future<void> _save() async {
    final id = _extractSpreadsheetId(_spreadsheetController.text);
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a spreadsheet URL or ID first.')),
      );
      return;
    }
    await widget.settingsStore.save(
      spreadsheetId: id,
      sheetName: _sheetNameController.text,
    );
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Destination saved.')));
      Navigator.pop(context, true);
    }
  }

  Future<void> _testConnection() async {
    final id = _extractSpreadsheetId(_spreadsheetController.text);
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a spreadsheet URL or ID first.')),
      );
      return;
    }
    final sheetName = _sheetNameController.text.trim().isEmpty
        ? 'Sheet1'
        : _sheetNameController.text.trim();

    setState(() {
      _testing = true;
      _testResult = null;
    });
    try {
      await widget.sheetsService
          .ensureHeaderRow(spreadsheetId: id, sheetName: sheetName);
      setState(() {
        _testFailed = false;
        _testResult = 'Connected — header row is set up.';
      });
    } catch (e) {
      setState(() {
        _testFailed = true;
        _testResult = 'Could not connect: $e';
      });
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  @override
  void dispose() {
    _spreadsheetController.dispose();
    _sheetNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Destination Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Paste your Google Sheet URL (or just the ID) and the tab name '
            'you want receipts appended to.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _spreadsheetController,
            decoration: const InputDecoration(
              labelText: 'Spreadsheet URL or ID',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _sheetNameController,
            decoration: const InputDecoration(
              labelText: 'Tab name',
              hintText: 'Sheet1',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          if (_serviceAccountEmail != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Share your sheet with this service account (Editor access), '
                      'or writes will fail:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    SelectableText(_serviceAccountEmail!),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _testing ? null : _testConnection,
            child: _testing
                ? const SizedBox(
                    height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Test Connection'),
          ),
          if (_testResult != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _testResult!,
                style: TextStyle(color: _testFailed ? Colors.red : Colors.green.shade700),
              ),
            ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _save,
            child: const Text('Save Destination'),
          ),
        ],
      ),
    );
  }
}
