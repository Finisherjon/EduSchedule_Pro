import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/schedule_model.dart';

class ScheduleRepository {
  static const _boxName = 'schedules';

  static Future<void> init() async {
    await Hive.openBox<String>(_boxName);
  }

  Box<String> get _box => Hive.box<String>(_boxName);

  // Keyed by groupId (one schedule per group)
  Future<void> save(ScheduleModel schedule) async {
    await _box.put(schedule.groupId, jsonEncode(schedule.toMap()));
  }

  ScheduleModel? getForGroup(String groupId) {
    final json = _box.get(groupId);
    if (json == null) return null;
    return ScheduleModel.fromMap(
        Map<String, dynamic>.from(jsonDecode(json) as Map));
  }

  List<ScheduleModel> getAll() {
    return _box.values
        .map((v) => ScheduleModel.fromMap(
            Map<String, dynamic>.from(jsonDecode(v) as Map)))
        .toList();
  }

  bool hasForGroup(String groupId) => _box.containsKey(groupId);

  Future<void> deleteForGroup(String groupId) async {
    await _box.delete(groupId);
  }

  Future<void> deleteAll() async {
    await _box.clear();
  }
}
