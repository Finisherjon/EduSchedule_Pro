import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/class_group_model.dart';

class ClassGroupRepository {
  static const _boxName = 'class_groups';

  // ─── Init ─────────────────────────────────────────────────────────────────

  static Future<void> init() async {
    await Hive.openBox<String>(_boxName);
  }

  Box<String> get _box => Hive.box<String>(_boxName);

  // ─── Write ────────────────────────────────────────────────────────────────

  /// Yangi sinf saqlaydi yoki mavjudini yangilaydi (upsert).
  Future<void> save(ClassGroupModel group) async {
    await _box.put(group.id, jsonEncode(group.toMap()));
  }

  /// Bir vaqtda bir nechta sinfni saqlaydi.
  Future<void> saveAll(List<ClassGroupModel> groups) async {
    final entries = {
      for (final g in groups) g.id: jsonEncode(g.toMap()),
    };
    await _box.putAll(entries);
  }

  // ─── Read ─────────────────────────────────────────────────────────────────

  /// Barcha sinflarni qaytaradi (saqlangan tartibda).
  List<ClassGroupModel> getAll() {
    return _box.values
        .map((json) => ClassGroupModel.fromMap(
            Map<String, dynamic>.from(jsonDecode(json) as Map)))
        .toList();
  }

  /// ID bo'yicha bitta sinf — topilmasa null.
  ClassGroupModel? getById(String id) {
    final json = _box.get(id);
    if (json == null) return null;
    return ClassGroupModel.fromMap(
        Map<String, dynamic>.from(jsonDecode(json) as Map));
  }

  /// Sinflar mavjudligini tekshiradi.
  bool get isEmpty => _box.isEmpty;

  int get count => _box.length;

  // ─── Delete ───────────────────────────────────────────────────────────────

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Future<void> deleteAll() async {
    await _box.clear();
  }

  // ─── Watch ───────────────────────────────────────────────────────────────
  // Box o'zgarganda UI avtomatik yangilanishi uchun stream.

  Stream<List<ClassGroupModel>> watch() {
    return _box.watch().map((_) => getAll());
  }
}
