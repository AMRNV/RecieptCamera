import 'package:flutter/material.dart';
import '../services/ocr_service.dart';
import '../services/receipt_matcher.dart';
import '../services/settings_store.dart';
import '../services/sheets_service.dart';
import '../services/template_store.dart';
import 'capture_screen.dart';
import 'review_screen.dart';
import 'settings_screen.dart';
import 'teach_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _ocrService = OcrService();
  final _templateStore = TemplateStore();
  final _sheetsService = SheetsService();
  final _settingsStore = SettingsStore();

  bool _ready = false;
  bool _busy = false;
  String? _statusText;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _templateStore.init();
    await _settingsStore.init();
    setState(() => _ready = true);
  }

  Future<void> _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          settingsStore: _settingsStore,
          sheetsService: _sheetsService,
        ),
      ),
    );
    setState(() {});
  }

  Future<void> _scanReceipt() async {
    if (!_settingsStore.isConfigured) {
      await _openSettings();
      if (!_settingsStore.isConfigured) return;
    }

    setState(() {
      _busy = true;
      _statusText = 'Opening camera…';
    });

    final photoPath = await Navigator.push<String?>(
      context,
      MaterialPageRoute(builder: (_) => const CaptureScreen()),
    );

    if (photoPath == null) {
      setState(() {
        _busy = false;
        _statusText = null;
      });
      return;
    }

    setState(() => _statusText = 'Reading text…');
    final lines = await _ocrService.recognizeLines(photoPath);

    if (lines.isEmpty) {
      setState(() {
        _busy = false;
        _statusText = 'No text found in that photo — try again with better lighting/focus.';
      });
      return;
    }

    final knownTemplates = _templateStore.getAll();
    final matchedTemplate = ReceiptMatcher.identifyStore(lines, knownTemplates);

    if (matchedTemplate != null) {
      setState(() => _statusText = 'Matched store: ${matchedTemplate.merchantMatch}');
      final parsed = ReceiptMatcher.parse(lines, matchedTemplate);
      await _goToReview(parsed);
    } else {
      setState(() => _statusText = 'New store — let\u2019s teach it once.');
      final savedTemplate = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TeachScreen(lines: lines, templateStore: _templateStore),
        ),
      );
      if (savedTemplate != null) {
        final parsed = ReceiptMatcher.parse(lines, savedTemplate);
        await _goToReview(parsed);
      }
    }

    setState(() {
      _busy = false;
      _statusText = null;
    });
  }

  Future<void> _goToReview(ReceiptParseResult parsed) async {
    final spreadsheetId = _settingsStore.spreadsheetId!;
    final sheetName = _settingsStore.sheetName;
    try {
      await _sheetsService.ensureHeaderRow(
        spreadsheetId: spreadsheetId,
        sheetName: sheetName,
      );
    } catch (_) {
      // Non-fatal: header row is a convenience, not a requirement.
    }
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewScreen(
          result: parsed,
          sheetsService: _sheetsService,
          spreadsheetId: spreadsheetId,
          sheetName: sheetName,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final templateCount = _ready ? _templateStore.getAll().length : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt Scanner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Destination settings',
            onPressed: _busy ? null : _openSettings,
          ),
        ],
      ),
      body: Center(
        child: !_ready
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('$templateCount store template(s) learned',
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  Text(
                    _settingsStore.isConfigured
                        ? 'Sending to sheet: ${_settingsStore.sheetName}'
                        : 'No destination configured yet — tap Scan or the gear icon to set one up.',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (_statusText != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      child: Text(_statusText!, textAlign: TextAlign.center),
                    ),
                  ElevatedButton.icon(
                    onPressed: _busy ? null : _scanReceipt,
                    icon: const Icon(Icons.camera_alt),
                    label: Text(_busy ? 'Working…' : 'Scan Receipt'),
                  ),
                ],
              ),
      ),
    );
  }
}
