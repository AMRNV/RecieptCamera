import 'package:flutter/material.dart';
import '../services/receipt_matcher.dart';
import '../services/sheets_service.dart';

class ReviewScreen extends StatefulWidget {
  final ReceiptParseResult result;
  final SheetsService sheetsService;
  final String spreadsheetId;
  final String sheetName;

  const ReviewScreen({
    super.key,
    required this.result,
    required this.sheetsService,
    required this.spreadsheetId,
    required this.sheetName,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late TextEditingController _merchant;
  late TextEditingController _date;
  late TextEditingController _total;
  late TextEditingController _tax;
  late TextEditingController _category;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _merchant = TextEditingController(text: widget.result.merchant ?? '');
    _date = TextEditingController(text: widget.result.date ?? '');
    _total = TextEditingController(text: widget.result.total ?? '');
    _tax = TextEditingController(text: widget.result.tax ?? '');
    _category = TextEditingController(text: widget.result.category);
  }

  Future<void> _save() async {
    if (_total.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Total is required.')));
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.sheetsService.appendReceipt(
        spreadsheetId: widget.spreadsheetId,
        sheetName: widget.sheetName,
        merchant: _merchant.text.trim(),
        date: _date.text.trim(),
        total: _total.text.trim(),
        tax: _tax.text.trim(),
        category: _category.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Saved to spreadsheet.')));
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Receipt')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (widget.result.needsReview)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 12),
                color: Colors.amber.shade100,
                child: const Text(
                  'Some fields could not be auto-matched — please check them before saving.',
                ),
              ),
            _field('Merchant', _merchant),
            _field('Date', _date),
            _field('Total', _total),
            _field('Tax', _tax),
            _field('Category', _category),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save to Sheet'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      ),
    );
  }
}
