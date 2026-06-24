import 'package:flutter/foundation.dart';
import '../models/custom_holiday_model.dart';
import '../repositories/custom_holiday_repository.dart';

class CustomHolidayProvider extends ChangeNotifier {
  final _repo = CustomHolidayRepository();
  late List<CustomHoliday> _holidays;

  CustomHolidayProvider() {
    _holidays = _repo.getAll();
  }

  List<CustomHoliday> get holidays => List.unmodifiable(_holidays);

  String? getHolidayName(DateTime date) {
    for (final h in _holidays) {
      if (h.covers(date)) return h.name;
    }
    return null;
  }

  bool isHoliday(DateTime date) => getHolidayName(date) != null;

  Future<void> add(CustomHoliday holiday) async {
    _holidays = [..._holidays, holiday];
    await _repo.saveAll(_holidays);
    notifyListeners();
  }

  Future<void> update(int index, CustomHoliday holiday) async {
    final list = List<CustomHoliday>.from(_holidays);
    list[index] = holiday;
    _holidays = list;
    await _repo.saveAll(_holidays);
    notifyListeners();
  }

  Future<void> remove(int index) async {
    _holidays = List.from(_holidays)..removeAt(index);
    await _repo.saveAll(_holidays);
    notifyListeners();
  }
}
