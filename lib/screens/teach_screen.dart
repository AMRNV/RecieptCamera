import 'package:flutter/material.dart';
import '../models/receipt_template.dart';
import '../services/receipt_matcher.dart';
import '../services/teaching_helper.dart';
import '../services/template_store.dart';

enum _TeachField { date, total, tax }

class TeachScreen extends StatefulWidget {
  final List<OcrLine> lines;
  final TemplateStore templateStore;

  const TeachScreen({super.key, required this.lines, required this.templateStore});

  @override
  State<TeachScreen> createState() => _TeachScreenState();
}

class _TeachScreenState extends State<TeachScreen> {
  late TextEditingController _merchantController;
  _TeachField _activeField = _TeachField.date;

  FieldRule? _dateRule;
  FieldRule? _totalRule;
  FieldRule? _taxRule;

  @override
  void initState() {
    super.initState();
    // Guess the merchant name from the first non-empty line; user can edit.
    final guess = widget.lines.isNotEmpty ? widget.lines.first.text : '';
    _merchantController = TextEditingController(text: guess);
  }

  void _onLineTapped(int index) {
    try {
      final rule = TeachingHelper.inferRule(widget.lines, index);
      setState(() {
        switch (_activeField) {
          case _TeachField.date:
            _dateRule = rule;
            _activeField = _TeachField.total;
            break;
          case _TeachField.total:
            _totalRule = rule;
            _activeField = _TeachField.tax;
            break;
          case _TeachField.tax:
            _taxRule = rule;
            break;
        }
      });
    } on StateError catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  bool get _canSave => _dateRule != null && _totalRule != null && _merchantController.text.trim().isNotEmpty;

  Future<void> _saveTemplate() async {
    final template = StoreTemplate(
      merchantMatch: _merchantController.text.trim(),
      dateRule: _dateRule!,
      totalRule: _totalRule!,
      taxRule: _taxRule,
    );
    await widget.templateStore.save(template);
    if (mounted) Navigator.pop(context, template);
  }

  String get _instructionText {
    switch (_activeField) {
      case _TeachField.date:
        return 'Tap the line with the DATE (or its label)';
      case _TeachField.total:
        return 'Tap the line with the TOTAL amount (or its label)';
      case _TeachField.tax:
        return 'Tap the line with TAX (optional — you can skip this)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teach This Store')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _merchantController,
              decoration: const InputDecoration(
                labelText: 'Store name',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _instructionText,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (_activeField == _TeachField.tax)
                  TextButton(
                    onPressed: () => setState(() {}), // no-op, tax stays null if skipped
                    child: const Text('Skip'),
                  ),
              ],
            ),
          ),
          _statusChips(),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: widget.lines.length,
              itemBuilder: (context, index) {
                final line = widget.lines[index];
                return ListTile(
                  dense: true,
                  title: Text(line.text),
                  onTap: () => _onLineTapped(index),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canSave ? _saveTemplate : null,
                child: const Text('Save Template & Continue'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChips() {
    Widget chip(String label, bool done) => Chip(
          label: Text(label),
          backgroundColor: done ? Colors.green.shade100 : Colors.grey.shade200,
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Wrap(
        spacing: 8,
        children: [
          chip('Date', _dateRule != null),
          chip('Total', _totalRule != null),
          chip('Tax (optional)', _taxRule != null),
        ],
      ),
    );
  }
}
