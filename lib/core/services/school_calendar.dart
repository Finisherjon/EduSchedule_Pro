class HolidayInfo {
  final String name;
  final bool isBreak;

  const HolidayInfo(this.name, {this.isBreak = false});
}

/// O'zbekiston maktablari uchun ta'til va bayram kalendari.
class SchoolCalendar {
  // ── Yildan-yilga o'zgarmaydigan rasmiy bayramlar (oy, kun) ─────────────────
  static const _fixed = <(int, int), String>{
    (1, 1):  'Yangi yil',
    (3, 8):  "Xalqaro xotin-qizlar kuni",
    (3, 21): "Navro'z bayrami",
    (5, 9):  'Xotira va qadrlash kuni',
    (9, 1):  'Mustaqillik kuni',
    (10, 1): "O'qituvchi va murabbiylar kuni",
    (12, 8): 'Konstitutsiya kuni',
  };

  // ── Yil bo'yicha qo'shimcha dam olish kunlari (ko'chirilgan bayramlar) ─────
  static const _extra = <int, List<(int, int, String)>>{
    2026: [
      (3, 9,  "Ko'chirilgan dam olish (8-mart o'rniga)"),
      (3, 23, "Ko'chirilgan dam olish (Navro'z o'rniga)"),
      (5, 11, "Ko'chirilgan dam olish (9-may o'rniga)"),
      (8, 31, "Qo'shimcha dam olish kuni"),
    ],
  };

  // ── Qo'zg'aluvchan bayramlar: Ramazon va Qurbon hayiti ────────────────────
  static const _variable = <int, List<(int, int, String)>>{
    2025: [
      (3, 30, 'Ramazon hayiti'),
      (3, 31, 'Ramazon hayiti'),
      (6, 6,  'Qurbon hayiti'),
      (6, 7,  'Qurbon hayiti'),
    ],
    2026: [
      (3, 19, 'Ramazon hayiti'),
      (3, 20, 'Ramazon hayiti'),
      (5, 27, 'Qurbon hayiti'),
      (5, 28, 'Qurbon hayiti'),
    ],
  };

  // ── Choraklar orasidagi ta'tillar (yil → [(boshOy, boshKun, oxirOy, oxirKun, nom)]) ──
  static const _breaks = <int, List<(int, int, int, int, String)>>{
    2025: [
      (11, 1, 11, 6,   "Kuzgi ta'til"),
      (12, 27, 12, 31, "Qishki ta'til"),
    ],
    2026: [
      (1, 1, 1, 11,   "Qishki ta'til"),
      (3, 28, 4, 5,   "Bahorgi ta'til"),
      (7, 1, 8, 31,   "Yozgi ta'til"),
    ],
  };

  // ─────────────────────────────────────────────────────────────────────────

  /// Berilgan sana bayram yoki ta'til bo'lsa [HolidayInfo] qaytaradi.
  /// Aks holda `null`.
  static HolidayInfo? getInfo(DateTime date) {
    // 1. Rasmiy bayram
    final fixedName = _fixed[(date.month, date.day)];
    if (fixedName != null) return HolidayInfo(fixedName);

    // 2. Ko'chirilgan / qo'shimcha dam olish
    for (final e in _extra[date.year] ?? const []) {
      if (date.month == e.$1 && date.day == e.$2) return HolidayInfo(e.$3);
    }

    // 3. Hayitlar
    for (final h in _variable[date.year] ?? const []) {
      if (date.month == h.$1 && date.day == h.$2) return HolidayInfo(h.$3);
    }

    // 4. Chorak ta'tillari
    for (final b in _breaks[date.year] ?? const []) {
      final start = DateTime(date.year, b.$1, b.$2);
      final end = DateTime(date.year, b.$3, b.$4);
      if (!date.isBefore(start) && !date.isAfter(end)) {
        return HolidayInfo(b.$5, isBreak: true);
      }
    }

    return null;
  }

  static bool isHolidayOrBreak(DateTime date) => getInfo(date) != null;

  /// Berilgan oy ichida nechta dam olish kuni borligini qaytaradi.
  static int offDaysInMonth(int year, int month) {
    int count = 0;
    final days = DateTime(year, month + 1, 0).day;
    for (int d = 1; d <= days; d++) {
      if (isHolidayOrBreak(DateTime(year, month, d))) count++;
    }
    return count;
  }

  /// Yil uchun barcha rasmiy bayramlarni qaytaradi (birlashtirilgan, sana bo'yicha saralangan).
  /// Bir xil nomli ketma-ket kunlar bitta yozuvga birlashtiriladi.
  static List<({DateTime start, DateTime? end, String name})>
      publicHolidaysForYear(int year) {
    final raw = <(DateTime, String)>[];

    for (final e in _fixed.entries) {
      raw.add((DateTime(year, e.key.$1, e.key.$2), e.value));
    }
    for (final e in _extra[year] ?? const <(int, int, String)>[]) {
      raw.add((DateTime(year, e.$1, e.$2), e.$3));
    }
    for (final h in _variable[year] ?? const <(int, int, String)>[]) {
      raw.add((DateTime(year, h.$1, h.$2), h.$3));
    }

    raw.sort((a, b) => a.$1.compareTo(b.$1));

    final merged = <({DateTime start, DateTime? end, String name})>[];
    for (final item in raw) {
      if (merged.isNotEmpty &&
          merged.last.name == item.$2 &&
          item.$1
                  .difference(merged.last.end ?? merged.last.start)
                  .inDays <=
              1) {
        final last = merged.removeLast();
        merged.add((start: last.start, end: item.$1, name: last.name));
      } else {
        merged.add((start: item.$1, end: null, name: item.$2));
      }
    }
    return merged;
  }

  /// Yil uchun maktab ta'til davrlarini qaytaradi.
  static List<({DateTime start, DateTime end, String name})>
      schoolBreaksForYear(int year) {
    return (_breaks[year] ?? const <(int, int, int, int, String)>[])
        .map((b) => (
              start: DateTime(year, b.$1, b.$2),
              end: DateTime(year, b.$3, b.$4),
              name: b.$5,
            ))
        .toList();
  }

  /// Bugundan boshlab kelayotgan bayram va ta'tillarni qaytaradi (max [maxCount]).
  static List<({DateTime start, DateTime? end, String name, bool isBreak})>
      upcomingEvents({int maxCount = 6}) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final events =
        <({DateTime start, DateTime? end, String name, bool isBreak})>[];

    for (final year in [today.year, today.year + 1]) {
      for (final h in publicHolidaysForYear(year)) {
        final start = DateTime(h.start.year, h.start.month, h.start.day);
        if (!start.isBefore(todayOnly)) {
          events.add((
            start: h.start,
            end: h.end,
            name: h.name,
            isBreak: false,
          ));
        }
      }
      for (final b in schoolBreaksForYear(year)) {
        final start = DateTime(b.start.year, b.start.month, b.start.day);
        if (!start.isBefore(todayOnly)) {
          events.add((
            start: b.start,
            end: b.end,
            name: b.name,
            isBreak: true,
          ));
        }
      }
    }

    events.sort((a, b) => a.start.compareTo(b.start));

    // Remove duplicate names that are adjacent (same event, different year copies)
    final seen = <String>{};
    final deduped =
        <({DateTime start, DateTime? end, String name, bool isBreak})>[];
    for (final e in events) {
      final key = '${e.name}-${e.start.year}';
      if (seen.add(key)) deduped.add(e);
    }

    return deduped.take(maxCount).toList();
  }
}