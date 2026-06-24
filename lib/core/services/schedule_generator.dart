import '../models/class_group_model.dart';
import '../models/schedule_model.dart';
import '../models/subject_model.dart';

class ScheduleGenerator {
  /// Generates a weekly schedule for [group].
  ///
  /// Algorithm:
  /// 1. Sort subjects by difficulty (veryHard first), then hoursPerWeek descending.
  /// 2. Build an interleaved pool (round-robin across subjects) so lessons
  ///    of different subjects alternate rather than clustering.
  /// 3. Gap-maximizing placement with balanced-load constraint:
  ///    - Each day is capped at ceil(totalLessons / numDays) lessons.
  ///    - The last working day is additionally capped at 4 lessons.
  ///    - Tie-breaking strongly prefers less-loaded days (penalty × 3).
  /// 3b. Within each day, sort lessons by difficulty (hardest in the morning).
  /// 4. Calculate start/end times for each lesson, inserting breaks.
  static ScheduleModel generate(ClassGroupModel group) {
    final emptyDays = group.workDays
        .map((d) => ScheduleDay(day: d, lessons: const [], breaks: const []))
        .toList();

    if (group.subjects.isEmpty || group.workDays.isEmpty) {
      return ScheduleModel(
        groupId: group.id,
        generatedAt: DateTime.now(),
        days: emptyDays,
      );
    }

    final numDays = group.workDays.length;
    final maxPerDay = group.maxLessonsPerDay;

    // ── Step 1: sort subjects ─────────────────────────────────────────────────
    final sorted = [...group.subjects]
      ..sort((a, b) {
        final dc = b.difficulty.index.compareTo(a.difficulty.index);
        if (dc != 0) return dc;
        return b.hoursPerWeek.compareTo(a.hoursPerWeek);
      });

    // ── Step 2: interleaved pool ──────────────────────────────────────────────
    // Round-robin across subjects so different subjects alternate, which
    // prevents any single day from accumulating all lessons of one subject.
    final pool = <SubjectModel>[];
    final maxHours =
        sorted.fold(0, (int m, s) => s.hoursPerWeek > m ? s.hoursPerWeek : m);
    for (int round = 0; round < maxHours; round++) {
      for (final sub in sorted) {
        if (round < sub.hoursPerWeek) pool.add(sub);
      }
    }

    // ── Step 3: gap-maximizing greedy fill with balanced caps ─────────────────
    final int totalLessons = pool.length;

    // Balanced daily cap: no day exceeds ceil(total / days).
    // Clamped to user's configured max so we never exceed their setting.
    final int balancedCap = numDays > 0
        ? (totalLessons / numDays).ceil().clamp(1, maxPerDay)
        : maxPerDay;
    // Last working day gets at most 4 lessons (lighter end-of-week).
    final int lastDayCap = balancedCap.clamp(1, 4);

    // Saturday ("Sh") gets a lighter load: ≈ half the balanced cap, max 3.
    final int saturdayIdx = group.workDays.indexOf('Sh');
    final int saturdayCap = saturdayIdx >= 0
        ? ((balancedCap / 2).ceil()).clamp(1, 3)
        : balancedCap;

    // Returns the lesson cap for day index [d].
    int capFor(int d) {
      if (saturdayIdx >= 0 && d == saturdayIdx) return saturdayCap;
      if (d == numDays - 1) return lastDayCap;
      return balancedCap;
    }

    final grid = List.generate(numDays, (_) => <SubjectModel>[]);

    for (final sub in pool) {
      // Days where this subject is already placed
      final placedDays = <int>[
        for (int d = 0; d < numDays; d++)
          if (grid[d].any((s) => s.id == sub.id)) d,
      ];

      int bestDay = -1;
      double bestScore = double.negativeInfinity;

      for (int d = 0; d < numDays; d++) {
        final dayMax = capFor(d);
        if (grid[d].length >= dayMax) continue;
        // Never place the same subject twice on the same day
        if (grid[d].any((s) => s.id == sub.id)) continue;

        // Minimum gap to the nearest existing lesson of this subject.
        double minGap = numDays.toDouble();
        for (final pd in placedDays) {
          final gap = (d - pd).abs().toDouble();
          if (gap < minGap) minGap = gap;
        }

        // Gap-maximization + strong load-balance penalty (×3 vs ×1 before).
        // This ensures less-loaded days win when gaps are close in value.
        final score = minGap * 10 - grid[d].length * 3;
        if (score > bestScore) {
          bestScore = score;
          bestDay = d;
        }
      }

      // Fallback pass 1: balanced cap exhausted — relax to maxPerDay but
      // still avoid placing the same subject twice on the same day.
      if (bestDay < 0) {
        int minLoad = maxPerDay + 1;
        for (int d = 0; d < numDays; d++) {
          if (grid[d].any((s) => s.id == sub.id)) continue;
          final hardCap = (saturdayIdx >= 0 && d == saturdayIdx)
              ? saturdayCap
              : (d == numDays - 1)
                  ? (maxPerDay < 4 ? maxPerDay : 4)
                  : maxPerDay;
          if (grid[d].length < hardCap && grid[d].length < minLoad) {
            minLoad = grid[d].length;
            bestDay = d;
          }
        }
      }
      // Fallback pass 2: every day already has this subject (hours > days).
      // Allow duplication on the least-loaded day as a last resort.
      if (bestDay < 0) {
        int minLoad = maxPerDay + 1;
        for (int d = 0; d < numDays; d++) {
          final hardCap = (saturdayIdx >= 0 && d == saturdayIdx)
              ? saturdayCap
              : (d == numDays - 1)
                  ? (maxPerDay < 4 ? maxPerDay : 4)
                  : maxPerDay;
          if (grid[d].length < hardCap && grid[d].length < minLoad) {
            minLoad = grid[d].length;
            bestDay = d;
          }
        }
      }

      if (bestDay >= 0) grid[bestDay].add(sub);
    }

    // ── Step 3b: within each day sort hardest lessons first (morning) ─────────
    for (final day in grid) {
      day.sort((a, b) => b.difficulty.index.compareTo(a.difficulty.index));
    }

    // ── Step 4: build ScheduleDay objects with times ──────────────────────────
    final scheduleDays = <ScheduleDay>[];

    for (int d = 0; d < numDays; d++) {
      final subjects = grid[d];
      final lessons = <ScheduleLesson>[];
      final breaks = <ScheduleBreak>[];

      int currentMin = 8 * 60; // 08:00 start

      for (int i = 0; i < subjects.length; i++) {
        final sub = subjects[i];
        final startTime = _fmt(currentMin);
        currentMin += group.lessonDuration;
        final endTime = _fmt(currentMin);

        lessons.add(ScheduleLesson(
          subjectId: sub.id,
          subjectName: sub.name,
          colorValue: sub.colorValue,
          lessonNumber: i + 1,
          startTime: startTime,
          endTime: endTime,
        ));

        if (i < subjects.length - 1) {
          final largeBr = group.largeBreaks
              .where((b) => b.afterLesson == i + 1)
              .firstOrNull;

          if (largeBr != null) {
            breaks.add(ScheduleBreak(
              time: endTime,
              duration: largeBr.duration,
              isLarge: true,
            ));
            currentMin += largeBr.duration;
          } else {
            breaks.add(ScheduleBreak(
              time: endTime,
              duration: group.smallBreakDuration,
              isLarge: false,
            ));
            currentMin += group.smallBreakDuration;
          }
        }
      }

      scheduleDays.add(ScheduleDay(
        day: group.workDays[d],
        lessons: lessons,
        breaks: breaks,
      ));
    }

    return ScheduleModel(
      groupId: group.id,
      generatedAt: DateTime.now(),
      days: scheduleDays,
    );
  }

  static String _fmt(int totalMinutes) {
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}
