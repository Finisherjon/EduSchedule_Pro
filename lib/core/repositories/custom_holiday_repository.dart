import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/custom_holiday_model.dart';

class CustomHolidayRepository {
  static const _boxName = 'custom_holidays';
  static const _key = 'all';

  static Future<void> init() async {
    await Hive.openBox<String>(_boxName);
  }

  Box<String> get _box => Hive.box<String>(_boxName);

  List<CustomHoliday> getAll() {
    final json = _box.get(_key);
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return list
        .map((e) => CustomHoliday.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> saveAll(List<CustomHoliday> holidays) async {
    await _box.put(_key, jsonEncode(holidays.map((h) => h.toMap()).toList()));
  }
}
