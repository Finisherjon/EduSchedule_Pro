import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/class_group_model.dart';
import '../../core/models/schedule_model.dart';
import '../../core/models/subject_model.dart';
import '../../core/providers/class_group_provider.dart';
import '../../core/providers/schedule_provider.dart';
import '../../core/services/school_calendar.dart';

// Group accent palette (no color field on ClassGroupModel)
const _kPalette = [
  Color(0xFF1565C0),
  Color(0xFF388E3C),
  Color(0xFFF57C00),
  Color(0xFF7B1FA2),
  Color(0xFF0097A7),
  Color(0xFFD32F2F),
];

Color _accentFor(int i) => _kPalette[i % _kPalette.length];

// Canonical day order used when computing unions across groups
const _kDayOrder = ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh'];

// ── Helper types ───────────────────────────────────────────────────────────────

typedef _SubStat = ({String name, int hours, Color color});

// ── Helper functions ───────────────────────────────────────────────────────────

/// Lesson count per workday for a single group's schedule.
List<int> _dailyLessons(ScheduleModel? schedule, List<String> workDays) {
  return workDays.map((d) {
    if (schedule == null) return 0;
    for (final day in schedule.days) {
      if (day.day == d) return day.lessonCount;
    }
    return 0;
  }).toList();
}

/// Union of all workDays across groups, in canonical order.
List<String> _unionWorkDays(List<ClassGroupModel> groups) {
  final seen = {for (final g in groups) ...g.workDays};
  return _kDayOrder.where(seen.contains).toList();
}

List<int> _allDailyLessons(
  List<ClassGroupModel> groups,
  ScheduleProvider sp,
  List<String> days,
) {
  return days.map((d) {
    return groups.fold<int>(0, (sum, g) {
      final sched = sp.getForGroup(g.id);
      if (sched == null) return sum;
      for (final day in sched.days) {
        if (day.day == d) return sum + day.lessonCount;
      }
      return sum;
    });
  }).toList();
}

List<_SubStat> _groupSubjects(ClassGroupModel group) {
  final sorted = [...group.subjects]
    ..sort((a, b) => b.hoursPerWeek.compareTo(a.hoursPerWeek));
  return sorted
      .map(
        (s) =>
            (name: s.name, hours: s.hoursPerWeek, color: Color(s.colorValue)),
      )
      .toList();
}

List<_SubStat> _mergedSubjects(List<ClassGroupModel> groups) {
  final map = <String, _SubStat>{};
  for (final g in groups) {
    for (final s in g.subjects) {
      if (map.containsKey(s.name)) {
        final ex = map[s.name]!;
        map[s.name] = (
          name: ex.name,
          hours: ex.hours + s.hoursPerWeek,
          color: ex.color,
        );
      } else {
        map[s.name] = (
          name: s.name,
          hours: s.hoursPerWeek,
          color: Color(s.colorValue),
        );
      }
    }
  }
  return map.values.toList()..sort((a, b) => b.hours.compareTo(a.hours));
}

// ── Page ───────────────────────────────────────────────────────────────────────

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  int _selectedClass = -1; // -1 = all groups

  @override
  Widget build(BuildContext context) {
    final groups = context.watch<ClassGroupProvider>().groups;
    final sp = context.watch<ScheduleProvider>();

    if (groups.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        body: Column(
          children: [
            _StatsHeader(
              selectedClass: _selectedClass,
              groups: const [],
              onClassTap: (_) {},
            ),
            Expanded(child: _EmptyState()),
          ],
        ),
      );
    }

    // Clamp in case groups shrink
    if (_selectedClass >= groups.length) {
      _selectedClass = -1;
    }

    final ClassGroupModel? group = _selectedClass == -1
        ? null
        : groups[_selectedClass];
    final ScheduleModel? schedule = group != null
        ? sp.getForGroup(group.id)
        : null;

    // Compute stats
    final List<String> dayAbbrs = group != null
        ? group.workDays
        : _unionWorkDays(groups);
    final days = group != null
        ? _dailyLessons(schedule, group.workDays)
        : _allDailyLessons(groups, sp, dayAbbrs);
    final subjects = group != null
        ? _groupSubjects(group)
        : _mergedSubjects(groups);
    final totalLessons = days.fold(0, (a, b) => a + b);
    final totalHours = subjects.fold(0, (a, s) => a + s.hours);
    final workDayCount = dayAbbrs.length.clamp(1, 7);
    final avgPerDay = totalLessons / workDayCount;
    final topSubject = subjects.isEmpty ? '—' : subjects.first.name;

    // Difficulty counts
    final allSubjectModels = group != null
        ? group.subjects
        : groups.expand((g) => g.subjects).toList();
    final highCount = allSubjectModels
        .where((s) => s.difficulty == SubjectDifficulty.veryHard)
        .length;
    final medHighCount = allSubjectModels
        .where((s) => s.difficulty == SubjectDifficulty.hard)
        .length;
    final medCount = allSubjectModels
        .where((s) => s.difficulty == SubjectDifficulty.medium)
        .length;
    final medLowCount = allSubjectModels
        .where((s) => s.difficulty == SubjectDifficulty.easy)
        .length;
    final lowCount = allSubjectModels
        .where((s) => s.difficulty == SubjectDifficulty.veryEasy)
        .length;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _StatsHeader(
              selectedClass: _selectedClass,
              groups: groups,
              onClassTap: (i) => setState(() => _selectedClass = i),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _SummaryGrid(
                  totalLessons: totalLessons,
                  totalHours: totalHours,
                  subjectCount: subjects.length,
                  avgPerDay: avgPerDay,
                  topSubject: topSubject,
                  hasSchedule: group == null
                      ? groups.any((g) => sp.hasForGroup(g.id))
                      : sp.hasForGroup(group.id),
                ),
                const SizedBox(height: 20),
                _DailyLoadChart(dayAbbrs: dayAbbrs, dailyLessons: days),
                const SizedBox(height: 20),
                if (subjects.isNotEmpty) ...[
                  _SubjectChart(subjects: subjects),
                  const SizedBox(height: 20),
                ],
                _PriorityBreakdown(
                  veryHard: highCount,
                  hard: medHighCount,
                  medium: medCount,
                  easy: medLowCount,
                  veryEasy: lowCount,
                ),
                const SizedBox(height: 20),
                const _UpcomingHolidaysCard(),
                if (_selectedClass == -1 && groups.length > 1) ...[
                  const SizedBox(height: 20),
                  _ClassOverview(groups: groups, sp: sp),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.leaderboard_outlined,
            size: 52,
            color: AppColors.outlineVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'Ma\'lumot yo\'q',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Statistika uchun sinflar qo\'shilishi kerak',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────────

class _StatsHeader extends StatelessWidget {
  final int selectedClass;
  final List<ClassGroupModel> groups;
  final ValueChanged<int> onClassTap;

  const _StatsHeader({
    required this.selectedClass,
    required this.groups,
    required this.onClassTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Row(
                children: [
                  if (Navigator.of(context).canPop())
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 36,
                        height: 36,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 36,
                      height: 36,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.leaderboard_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Statistika',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          'Dars yuklamalari va fanlar tahlili',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _ClassChip(
                    label: 'Barchasi',
                    selected: selectedClass == -1,
                    color: Colors.white,
                    onTap: () => onClassTap(-1),
                  ),
                  ...List.generate(
                    groups.length,
                    (i) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _ClassChip(
                        label: groups[i].name,
                        selected: selectedClass == i,
                        color: _accentFor(i),
                        onTap: () => onClassTap(i),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}

class _ClassChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _ClassChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.primaryContainer : Colors.white,
          ),
        ),
      ),
    );
  }
}

// ── Summary grid ───────────────────────────────────────────────────────────────

class _SummaryGrid extends StatelessWidget {
  final int totalLessons;
  final int totalHours;
  final int subjectCount;
  final double avgPerDay;
  final String topSubject;
  final bool hasSchedule;

  const _SummaryGrid({
    required this.totalLessons,
    required this.totalHours,
    required this.subjectCount,
    required this.avgPerDay,
    required this.topSubject,
    required this.hasSchedule,
  });

  @override
  Widget build(BuildContext context) {
    final lessonsVal = hasSchedule ? '$totalLessons ta' : '—';
    final avgVal = hasSchedule ? avgPerDay.toStringAsFixed(1) : '—';

    final cards = [
      (
        icon: Icons.menu_book_rounded,
        label: 'Haftalik darslar',
        value: lessonsVal,
        color: AppColors.primaryContainer,
      ),
      (
        icon: Icons.schedule_rounded,
        label: 'Haftalik soat',
        value: '$totalHours soat',
        color: const Color(0xFF388E3C),
      ),
      (
        icon: Icons.trending_up_rounded,
        label: "Kuniga o'rtacha",
        value: avgVal,
        color: const Color(0xFFF57C00),
      ),
      (
        icon: Icons.star_rounded,
        label: "Eng ko'p fan",
        value: topSubject,
        color: const Color(0xFF7B1FA2),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Umumiy ko'rsatkichlar",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.55,
          children: cards
              .map(
                (c) => _SummaryCard(
                  icon: c.icon,
                  label: c.label,
                  value: c.value,
                  color: c.color,
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: color,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Daily load chart ───────────────────────────────────────────────────────────

class _DailyLoadChart extends StatelessWidget {
  final List<String> dayAbbrs;
  final List<int> dailyLessons;

  const _DailyLoadChart({required this.dayAbbrs, required this.dailyLessons});

  @override
  Widget build(BuildContext context) {
    final maxLessons = dailyLessons.isEmpty
        ? 1
        : dailyLessons.reduce((a, b) => a > b ? a : b);
    final todayIdx = (DateTime.now().weekday - 1).clamp(0, 4);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Kunlik yuklama',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                'darslar soni',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(dayAbbrs.length, (i) {
                final isToday = i == todayIdx;
                final count = i < dailyLessons.length ? dailyLessons[i] : 0;
                final fraction = maxLessons > 0 ? count / maxLessons : 0.0;
                final barColor = isToday
                    ? AppColors.primaryContainer
                    : AppColors.primary.withValues(alpha: 0.35);

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '$count',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isToday
                                ? AppColors.primaryContainer
                                : AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            height: 80 * fraction,
                            decoration: BoxDecoration(
                              color: barColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          dayAbbrs[i],
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: isToday
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: isToday
                                ? AppColors.primaryContainer
                                : AppColors.onSurfaceVariant,
                          ),
                        ),
                        if (isToday)
                          Container(
                            width: 5,
                            height: 5,
                            margin: const EdgeInsets.only(top: 3),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Subject chart ──────────────────────────────────────────────────────────────

class _SubjectChart extends StatelessWidget {
  final List<_SubStat> subjects;

  const _SubjectChart({required this.subjects});

  @override
  Widget build(BuildContext context) {
    if (subjects.isEmpty) return const SizedBox();
    final maxHours = subjects.first.hours;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Fanlar bo'yicha soatlar",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                'soat / hafta',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...subjects.asMap().entries.map((e) {
            final i = e.key;
            final sub = e.value;
            final fraction = maxHours > 0 ? sub.hours / maxHours : 0.0;

            return Padding(
              padding: EdgeInsets.only(
                bottom: i < subjects.length - 1 ? 14 : 0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: sub.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          sub.name,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                      Text(
                        '${sub.hours}h',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: sub.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Stack(
                      children: [
                        Container(
                          height: 7,
                          color: sub.color.withValues(alpha: 0.12),
                        ),
                        FractionallySizedBox(
                          widthFactor: fraction,
                          child: Container(
                            height: 7,
                            decoration: BoxDecoration(
                              color: sub.color,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Priority breakdown ─────────────────────────────────────────────────────────

class _PriorityBreakdown extends StatelessWidget {
  final int veryHard;
  final int hard;
  final int medium;
  final int easy;
  final int veryEasy;

  const _PriorityBreakdown({
    required this.veryHard,
    required this.hard,
    required this.medium,
    required this.easy,
    required this.veryEasy,
  });

  @override
  Widget build(BuildContext context) {
    final total = veryHard + hard + medium + easy + veryEasy;
    if (total == 0) return const SizedBox();

    final items = [
      (label: '★★★★★', count: veryHard, color: const Color(0xFF6A1B1B)),
      (label: '★★★★', count: hard, color: const Color(0xFFD32F2F)),
      (label: '★★★', count: medium, color: const Color(0xFFF57C00)),
      (label: '★★', count: easy, color: const Color(0xFF388E3C)),
      (label: '★', count: veryEasy, color: const Color(0xFF66BB6A)),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Qiyinlik bo\'yicha taqsimot',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          // Stacked bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Row(
              children: items.map((it) {
                final flex = it.count > 0 ? it.count : 0;
                if (flex == 0) return const SizedBox.shrink();
                return Expanded(
                  flex: flex,
                  child: Container(height: 12, color: it.color),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: items.map((it) {
              final pct = (it.count / total * 100).round();
              return Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: it.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${it.count} ta',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: it.color,
                      ),
                    ),
                    Text(
                      it.label,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '$pct%',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.outline,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Class overview (shown in "Barchasi" mode) ──────────────────────────────────

class _ClassOverview extends StatelessWidget {
  final List<ClassGroupModel> groups;
  final ScheduleProvider sp;

  const _ClassOverview({required this.groups, required this.sp});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sinflar xulosasi',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        ...groups.asMap().entries.map((e) {
          final i = e.key;
          final group = e.value;
          final accent = _accentFor(i);
          final schedule = sp.getForGroup(group.id);
          final totalHours = group.subjects.fold(
            0,
            (s, sub) => s + sub.hoursPerWeek,
          );
          final weeklyLessons = schedule?.totalLessons ?? 0;

          return Container(
            margin: EdgeInsets.only(bottom: i < groups.length - 1 ? 10 : 0),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent.withValues(alpha: 0.25)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      group.name.length > 4
                          ? group.name.substring(0, 4)
                          : group.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${group.subjects.length} fan · ${totalHours}h/hafta · ${group.workDays.length} ish kuni',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (schedule != null) ...[
                      Text(
                        '$weeklyLessons',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                      Text(
                        'dars/hafta',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.outlineVariant.withValues(
                            alpha: 0.3,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Jadval yo\'q',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ── Upcoming holidays card ─────────────────────────────────────────────────────

class _UpcomingHolidaysCard extends StatelessWidget {
  const _UpcomingHolidaysCard();

  static const _kMonths = [
    'yan',
    'fev',
    'mar',
    'apr',
    'may',
    'iyn',
    'iyl',
    'avg',
    'sen',
    'okt',
    'noy',
    'dek',
  ];

  String _fmtDate(DateTime d) => '${d.day} ${_kMonths[d.month - 1]}';

  String _dateLabel(DateTime start, DateTime? end) {
    if (end == null) return _fmtDate(start);
    if (start.month == end.month) {
      return '${start.day}–${end.day} ${_kMonths[start.month - 1]}';
    }
    return '${_fmtDate(start)} – ${_fmtDate(end)}';
  }

  String _daysUntil(DateTime start) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final diff = DateTime(
      start.year,
      start.month,
      start.day,
    ).difference(todayOnly).inDays;
    if (diff == 0) return 'Bugun!';
    if (diff == 1) return 'Ertaga';
    return '$diff kun';
  }

  Color _daysColor(DateTime start) {
    final today = DateTime.now();
    final diff = DateTime(
      start.year,
      start.month,
      start.day,
    ).difference(DateTime(today.year, today.month, today.day)).inDays;
    if (diff <= 3) return const Color(0xFFE53935);
    if (diff <= 14) return const Color(0xFFFF8F00);
    return AppColors.onSurfaceVariant;
  }

  @override
  Widget build(BuildContext context) {
    final events = SchoolCalendar.upcomingEvents(maxCount: 6);
    if (events.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 13, 16, 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.event_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Yaqin bayramlar va ta\'tillar',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Event list
          ...events.asMap().entries.map((entry) {
            final i = entry.key;
            final e = entry.value;
            final accent = e.isBreak
                ? const Color(0xFFFF8F00)
                : const Color(0xFFE53935);
            final daysColor = _daysColor(e.start);
            final isLast = i == events.length - 1;

            return Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : const Border(
                        bottom: BorderSide(color: Color(0xFFF2F2F2), width: 1),
                      ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      e.isBreak
                          ? Icons.beach_access_rounded
                          : Icons.celebration_rounded,
                      size: 15,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                        Text(
                          _dateLabel(e.start, e.end),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: daysColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _daysUntil(e.start),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: daysColor,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
