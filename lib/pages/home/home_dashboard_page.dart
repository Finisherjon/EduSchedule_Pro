import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/class_group_model.dart';
import '../../core/models/schedule_model.dart';
import '../../core/models/subject_model.dart';
import '../../core/providers/class_group_provider.dart';
import '../../core/providers/schedule_provider.dart';
import '../subject/subject_detail_page.dart';

// Weekday short codes → weekday number (1=Mon … 7=Sun)
const _kDayNums = {
  'Du': 1, 'Se': 2, 'Ch': 3, 'Pa': 4, 'Ju': 5, 'Sh': 6, 'Ya': 7,
};

const _kDayFull = {
  'Du': 'Dushanba',
  'Se': 'Seshanba',
  'Ch': 'Chorshanba',
  'Pa': 'Payshanba',
  'Ju': 'Juma',
  'Sh': 'Shanba',
  'Ya': 'Yakshanba',
};

class HomeDashboardPage extends StatefulWidget {
  const HomeDashboardPage({super.key});

  @override
  State<HomeDashboardPage> createState() => _HomeDashboardPageState();
}

class _HomeDashboardPageState extends State<HomeDashboardPage> {
  int _selectedPeriod = 0;
  int _selectedClass = 0;

  static const _periods = ['Bugun', 'Haftalik'];

  String _formatDate() {
    final now = DateTime.now();
    const weekdays = [
      'Yakshanba', 'Dushanba', 'Seshanba', 'Chorshanba',
      'Payshanba', 'Juma', 'Shanba',
    ];
    const months = [
      'yanvar', 'fevral', 'mart', 'aprel', 'may', 'iyun',
      'iyul', 'avgust', 'sentyabr', 'oktyabr', 'noyabr', 'dekabr',
    ];
    return '${weekdays[now.weekday % 7]}, ${now.day} ${months[now.month - 1]}';
  }

  ScheduleDay? _todayDay(ScheduleModel schedule) {
    final todayWd = DateTime.now().weekday;
    for (final day in schedule.days) {
      if (_kDayNums[day.day] == todayWd) return day;
    }
    return null;
  }

  void _showClassPicker(List<ClassGroupModel> groups) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => _ClassPickerSheet(
        groups: groups,
        selectedIndex: _selectedClass,
        onSelect: (i) {
          setState(() => _selectedClass = i);
          Navigator.pop(sheetCtx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final classProvider = context.watch<ClassGroupProvider>();
    final scheduleProvider = context.watch<ScheduleProvider>();
    final groups = classProvider.groups;

    if (_selectedClass >= groups.length && groups.isNotEmpty) {
      _selectedClass = 0;
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: _TopAppBar(),
      body: groups.isEmpty
          ? const _NoGroupsState()
          : _buildBody(context, groups, scheduleProvider),
    );
  }

  void _openSubjectDetail(
    BuildContext context,
    ClassGroupModel group,
    ScheduleModel schedule,
    ScheduleLesson lesson,
  ) {
    SubjectModel? subject;
    for (final s in group.subjects) {
      if (s.id == lesson.subjectId) {
        subject = s;
        break;
      }
    }
    if (subject == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SubjectDetailPage(
          subject: subject!,
          schedule: schedule,
          groupName: group.name,
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    List<ClassGroupModel> groups,
    ScheduleProvider scheduleProvider,
  ) {
    final group = groups[_selectedClass];
    final schedule = scheduleProvider.getForGroup(group.id);
    final todayDay = schedule != null ? _todayDay(schedule) : null;
    final todayLessons = todayDay?.lessonCount ?? 0;
    final totalHours =
        group.subjects.fold(0, (s, sub) => s + sub.hoursPerWeek);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WelcomeCard(
            className: group.name,
            date: _formatDate(),
            todayLessons: todayLessons,
            onClassTap: () => _showClassPicker(groups),
          ),
          const SizedBox(height: 16),
          _StatsRow(
            totalLessons: schedule?.totalLessons ?? 0,
            todayLessons: todayLessons,
            totalHours: totalHours,
          ),
          const SizedBox(height: 16),
          _PeriodSelector(
            periods: _periods,
            selected: _selectedPeriod,
            onChanged: (i) => setState(() => _selectedPeriod = i),
          ),
          const SizedBox(height: 16),
          if (schedule == null)
            _NoScheduleCard(
              group: group,
              isGenerating: scheduleProvider.isLoading,
              onGenerate: () =>
                  context.read<ScheduleProvider>().generateFor(group),
            )
          else if (_selectedPeriod == 0)
            _TodayView(
              schedule: schedule,
              todayDay: todayDay,
              onLessonTap: (lesson) =>
                  _openSubjectDetail(context, group, schedule, lesson),
            )
          else
            _WeeklyView(
              schedule: schedule,
              onLessonTap: (lesson) =>
                  _openSubjectDetail(context, group, schedule, lesson),
            ),
        ],
      ),
    );
  }
}

// ── No groups empty state ───────────────────────────────────────────────────────

class _NoGroupsState extends StatelessWidget {
  const _NoGroupsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.school_outlined,
                  size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              "Sinflar qo'shilmagan",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Boshlash uchun sozlash jarayonini tugallang",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.onSurfaceVariant, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ── No schedule card ────────────────────────────────────────────────────────────

class _NoScheduleCard extends StatelessWidget {
  final ClassGroupModel group;
  final bool isGenerating;
  final VoidCallback onGenerate;

  const _NoScheduleCard({
    required this.group,
    required this.isGenerating,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                size: 32, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Jadval hali yaratilmagan',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "${group.name} sinfi uchun avtomatik dars jadvali yarating.\n"
            "${group.subjects.length} ta fan, ${group.workDays.length} kun asosida.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.onSurfaceVariant,
                height: 1.5),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: isGenerating
                    ? null
                    : const LinearGradient(
                        colors: [Color(0xFF1565C0), Color(0xFF1E88E5)]),
                color: isGenerating ? AppColors.surfaceContainerHigh : null,
                borderRadius: BorderRadius.circular(999),
                boxShadow: isGenerating
                    ? null
                    : [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: isGenerating ? null : onGenerate,
                  child: Center(
                    child: isGenerating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.primary),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.auto_awesome_rounded,
                                  color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Jadval yaratish',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Today view ──────────────────────────────────────────────────────────────────

class _TodayView extends StatelessWidget {
  final ScheduleModel schedule;
  final ScheduleDay? todayDay;
  final ValueChanged<ScheduleLesson> onLessonTap;

  const _TodayView({
    required this.schedule,
    required this.todayDay,
    required this.onLessonTap,
  });

  @override
  Widget build(BuildContext context) {
    if (todayDay == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Column(
          children: [
            const Icon(Icons.weekend_outlined,
                size: 40, color: AppColors.outlineVariant),
            const SizedBox(height: 12),
            Text(
              'Bugun dam olish kuni',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Dars jadvalida bugun ish kuni emas',
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    if (todayDay!.lessons.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Center(
          child: Text(
            'Bugun darslar yo\'q',
            style: GoogleFonts.inter(
                fontSize: 14, color: AppColors.onSurfaceVariant),
          ),
        ),
      );
    }

    return _TimelineWidget(day: todayDay!, onLessonTap: onLessonTap);
  }
}

// ── Timeline widget ─────────────────────────────────────────────────────────────

class _TimelineWidget extends StatelessWidget {
  final ScheduleDay day;
  final ValueChanged<ScheduleLesson> onLessonTap;

  static const double _timeColW = 58;
  static const double _dotGap = 8;
  static const double _dotSize = 14;

  const _TimelineWidget({required this.day, required this.onLessonTap});

  @override
  Widget build(BuildContext context) {
    // Build interleaved list: lesson, break, lesson, break, …, lesson
    final items = <_TItem>[];
    for (int i = 0; i < day.lessons.length; i++) {
      items.add(_TLesson(day.lessons[i]));
      if (i < day.breaks.length) {
        items.add(_TBreak(day.breaks[i]));
      }
    }

    const lineX = _timeColW + _dotGap + _dotSize / 2;

    return Stack(
      children: [
        Positioned(
          left: lineX - 0.75,
          top: 20,
          bottom: 20,
          child: Container(
            width: 1.5,
            color: AppColors.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        Column(
          children: items.asMap().entries.map((e) {
            final i = e.key;
            final item = e.value;
            return Padding(
              padding: EdgeInsets.only(bottom: i < items.length - 1 ? 8 : 0),
              child: switch (item) {
                _TLesson t => _LessonRow(
                    lesson: t.lesson,
                    onTap: () => onLessonTap(t.lesson),
                    timeColW: _timeColW,
                    dotGap: _dotGap,
                    dotSize: _dotSize,
                  ),
                _TBreak t => _BreakRow(
                    br: t.br,
                    timeColW: _timeColW,
                    dotGap: _dotGap,
                  ),
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

sealed class _TItem {}
class _TLesson extends _TItem { final ScheduleLesson lesson; _TLesson(this.lesson); }
class _TBreak extends _TItem { final ScheduleBreak br; _TBreak(this.br); }

class _LessonRow extends StatelessWidget {
  final ScheduleLesson lesson;
  final VoidCallback onTap;
  final double timeColW;
  final double dotGap;
  final double dotSize;

  const _LessonRow({
    required this.lesson,
    required this.onTap,
    required this.timeColW,
    required this.dotGap,
    required this.dotSize,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(lesson.colorValue);
    return GestureDetector(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: timeColW,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  lesson.startTime,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                Text(
                  lesson.endTime,
                  style: GoogleFonts.inter(
                      fontSize: 10, color: AppColors.outline),
                ),
              ],
            ),
          ),
          SizedBox(width: dotGap),
          Container(
            margin: const EdgeInsets.only(top: 3),
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.surface, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: _LessonCard(lesson: lesson)),
        ],
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  final ScheduleLesson lesson;

  const _LessonCard({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final color = Color(lesson.colorValue);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.07),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: color),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              lesson.subjectName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${lesson.lessonNumber}-dars',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.schedule_rounded,
                              size: 12, color: AppColors.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            '${lesson.startTime} – ${lesson.endTime}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BreakRow extends StatelessWidget {
  final ScheduleBreak br;
  final double timeColW;
  final double dotGap;

  const _BreakRow({
    required this.br,
    required this.timeColW,
    required this.dotGap,
  });

  @override
  Widget build(BuildContext context) {
    final label = br.isLarge
        ? '${br.duration} daqiqa katta tanaffus'
        : '${br.duration} daqiqa tanaffus';

    return Row(
      children: [
        SizedBox(
          width: timeColW,
          child: Text(
            br.time,
            textAlign: TextAlign.right,
            style:
                GoogleFonts.inter(fontSize: 11, color: AppColors.outline),
          ),
        ),
        SizedBox(width: dotGap),
        Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: br.isLarge
                ? AppColors.secondary.withValues(alpha: 0.2)
                : AppColors.surfaceContainerHigh,
            shape: BoxShape.circle,
            border: Border.all(
              color: br.isLarge
                  ? AppColors.secondary.withValues(alpha: 0.5)
                  : AppColors.outlineVariant,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: br.isLarge
                  ? AppColors.secondary.withValues(alpha: 0.06)
                  : AppColors.surface.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: br.isLarge
                    ? AppColors.secondary.withValues(alpha: 0.3)
                    : AppColors.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  br.isLarge
                      ? Icons.restaurant_outlined
                      : Icons.local_cafe_outlined,
                  size: 13,
                  color:
                      br.isLarge ? AppColors.secondary : AppColors.outline,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color:
                        br.isLarge ? AppColors.secondary : AppColors.outline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Weekly view ─────────────────────────────────────────────────────────────────

class _WeeklyView extends StatelessWidget {
  final ScheduleModel schedule;
  final ValueChanged<ScheduleLesson> onLessonTap;

  const _WeeklyView({required this.schedule, required this.onLessonTap});

  @override
  Widget build(BuildContext context) {
    final todayWd = DateTime.now().weekday;

    return Column(
      children: schedule.days.asMap().entries.map((e) {
        final i = e.key;
        final day = e.value;
        final isToday = _kDayNums[day.day] == todayWd;
        final full = _kDayFull[day.day] ?? day.day;

        return Container(
          margin: EdgeInsets.only(bottom: i < schedule.days.length - 1 ? 10 : 0),
          decoration: BoxDecoration(
            color: isToday
                ? AppColors.primary.withValues(alpha: 0.04)
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isToday
                  ? AppColors.primary.withValues(alpha: 0.35)
                  : AppColors.outlineVariant,
              width: isToday ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Day header
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                child: Row(
                  children: [
                    if (isToday)
                      Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    Text(
                      full,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isToday
                            ? AppColors.primary
                            : AppColors.onSurface,
                      ),
                    ),
                    if (isToday) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Bugun',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isToday
                            ? AppColors.primary
                            : AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${day.lessonCount} ta dars',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isToday
                              ? Colors.white
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (day.lessons.isNotEmpty) ...[
                const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.outlineVariant),
                ...day.lessons.asMap().entries.map((le) {
                  final j = le.key;
                  final lesson = le.value;
                  final isLast = j == day.lessons.length - 1;
                  final color = Color(lesson.colorValue);

                  return GestureDetector(
                    onTap: () => onLessonTap(lesson),
                    child: Container(
                      padding:
                          const EdgeInsets.fromLTRB(14, 10, 14, 10),
                      decoration: isLast
                          ? null
                          : BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: AppColors.outlineVariant
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 44,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lesson.startTime,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  '${lesson.lessonNumber}-d',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: AppColors.outline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 3,
                            height: 36,
                            margin: const EdgeInsets.symmetric(
                                horizontal: 10),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              lesson.subjectName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ),
                          Text(
                            lesson.endTime,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                  child: Text(
                    'Darslar yo\'q',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.outline),
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Top AppBar ──────────────────────────────────────────────────────────────────

class _TopAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: Row(
        children: [
          const Icon(Icons.school_rounded, color: Colors.white, size: 26),
          const SizedBox(width: 8),
          Text(
            'EduSchedule Pro',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
      actions: const [],
    );
  }
}

// ── Welcome card ────────────────────────────────────────────────────────────────

class _WelcomeCard extends StatelessWidget {
  final String className;
  final String date;
  final int todayLessons;
  final VoidCallback onClassTap;

  const _WelcomeCard({
    required this.className,
    required this.date,
    required this.todayLessons,
    required this.onClassTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: onClassTap,
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$className sinf!',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.expand_more_rounded,
                            color: Colors.white, size: 16),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Bugun $todayLessons ta dars',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats row ───────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final int totalLessons;
  final int todayLessons;
  final int totalHours;

  const _StatsRow({
    required this.totalLessons,
    required this.todayLessons,
    required this.totalHours,
  });

  @override
  Widget build(BuildContext context) {
    final stats = [
      (
        label: 'Haftalik dars',
        value: '$totalLessons',
        color: AppColors.primary,
      ),
      (
        label: 'Bugun',
        value: '$todayLessons',
        color: AppColors.secondary,
      ),
      (
        label: 'Jami soat',
        value: '${totalHours}h',
        color: const Color(0xFFF57C00),
      ),
    ];

    return Row(
      children: List.generate(stats.length, (i) {
        final s = stats[i];
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(left: i == 0 ? 0 : 10),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.4)),
            ),
            child: Column(
              children: [
                Text(
                  s.label,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppColors.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s.value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: s.color,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ── Period selector ─────────────────────────────────────────────────────────────

class _PeriodSelector extends StatelessWidget {
  final List<String> periods;
  final int selected;
  final ValueChanged<int> onChanged;

  const _PeriodSelector({
    required this.periods,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: List.generate(periods.length, (i) {
          final isSelected = i == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color:
                                AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  periods[i],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: isSelected
                        ? Colors.white
                        : AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Class picker sheet ──────────────────────────────────────────────────────────

class _ClassPickerSheet extends StatelessWidget {
  final List<ClassGroupModel> groups;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _ClassPickerSheet({
    required this.groups,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Sinfni tanlang',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Ko'rmoqchi bo'lgan sinf jadvalini tanlang",
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  controller: scrollController,
                  shrinkWrap: true,
                  itemCount: groups.length,
                  itemBuilder: (_, i) {
              final isSelected = i == selectedIndex;
              final group = groups[i];
              final totalHours = group.subjects
                  .fold(0, (s, sub) => s + sub.hoursPerWeek);

              // Check schedule from provider
              final schedule =
                  context.read<ScheduleProvider>().getForGroup(group.id);

              return GestureDetector(
                onTap: () => onSelect(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.outlineVariant,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.surfaceContainerHigh,
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
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.onSurface,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurface,
                              ),
                            ),
                            Text(
                              schedule != null
                                  ? '${schedule.totalLessons} dars/hafta · ${totalHours}h'
                                  : '${group.subjects.length} ta fan · ${totalHours}h/hafta',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_rounded,
                              size: 14, color: Colors.white),
                        ),
                    ],
                  ),
                ),
              );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
