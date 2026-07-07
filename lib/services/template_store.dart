import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/receipt_template.dart';

/// Stores StoreTemplates as JSON strings in a Hive box, keyed by
/// merchant name. Avoids Hive code-gen/TypeAdapters entirely --
/// just plain JSON in, JSON out.
class TemplateStore {
  static const String _boxName = 'store_templates';
  Box<String>? _box;

  Future<void> init() async {
    _box = await Hive.openBox<String>(_boxName);
  }

  Box<String> get _requireBox {
    if (_box == null) {
      throw StateError('TemplateStore.init() must be called before use.');
    }
    return _box!;
  }

  Future<void> save(StoreTemplate template) async {
    final key = template.merchantMatch.toUpperCase();
    await _requireBox.put(key, jsonEncode(template.toJson()));
  }

  Future<void> delete(String merchantMatch) async {
    await _requireBox.delete(merchantMatch.toUpperCase());
  }

  List<StoreTemplate> getAll() {
    return _requireBox.values
        .map((jsonStr) => StoreTemplate.fromJson(jsonDecode(jsonStr)))
        .toList();
  }
}
