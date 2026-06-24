import 'package:flutter/foundation.dart';
import '../models/class_group_model.dart';
import '../models/schedule_model.dart';
import '../repositories/schedule_repository.dart';
import '../services/schedule_generator.dart';

class ScheduleProvider extends ChangeNotifier {
  final _repo = ScheduleRepository();

  // groupId → ScheduleModel
  final Map<String, ScheduleModel> _schedules = {};
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  ScheduleModel? getForGroup(String groupId) => _schedules[groupId];
  bool hasForGroup(String groupId) => _schedules.containsKey(groupId);

  Future<void> loadAll() async {
    _isLoading = true;
    notifyListeners();

    final all = _repo.getAll();
    _schedules.clear();
    for (final s in all) {
      _schedules[s.groupId] = s;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Saves a manually edited schedule without regenerating.
  Future<void> saveManual(ScheduleModel schedule) async {
    await _repo.save(schedule);
    _schedules[schedule.groupId] = schedule;
    notifyListeners();
  }

  /// Generates and saves a schedule for [group], replacing any existing one.
  Future<ScheduleModel> generateFor(ClassGroupModel group) async {
    final schedule = ScheduleGenerator.generate(group);
    await _repo.save(schedule);
    _schedules[group.id] = schedule;
    notifyListeners();
    return schedule;
  }

  Future<void> deleteForGroup(String groupId) async {
    await _repo.deleteForGroup(groupId);
    _schedules.remove(groupId);
    notifyListeners();
  }

  Future<void> deleteAll() async {
    await _repo.deleteAll();
    _schedules.clear();
    notifyListeners();
  }
}
