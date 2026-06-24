import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/class_group_model.dart';
import '../../core/models/custom_holiday_model.dart';
import '../../core/models/schedule_model.dart';
import '../../core/providers/class_group_provider.dart';
import '../../core/providers/custom_holiday_provider.dart';
import '../../core/models/subject_model.dart';
import '../../core/providers/schedule_provider.dart';
import '../../core/services/school_calendar.dart';
import '../statistics/statistics_page.dart';
import '../subject/subject_detail_page.dart';

// weekday abbr → DateTime.weekday (1=Mon..7=Sun)
const _kDayNum = {
  'Du': 1, 'Se': 2, 'Ch': 3, 'Pa': 4, 'Ju': 5, 'Sh': 6, 'Ya': 7,
};

const _kDayFull = {
  'Du': 'Dushanba', 'Se': 'Seshanba', 'Ch': 'Chorshanba',
  'Pa': 'Payshanba', 'Ju': 'Juma', 'Sh': 'Shanba', 'Ya': 'Yakshanba',
};

const _kMonths = [
  'Yanvar', 'Fevral', 'Mart', 'Aprel', 'May', 'Iyun',
  'Iyul', 'Avgust', 'Sentyabr', 'Oktyabr', 'Noyabr', 'Dekabr',
];

// Compute this week's date for a day abbreviation
DateTime _weekDateFor(String abbr) {
  final now = DateTime.now();
  final mon = now.subtract(Duration(days: now.weekday - 1));
  final target = _kDayNum[abbr] ?? 1;
  return mon.add(Duration(days: target - 1));
}

class TimetablePage extends StatefulWidget {
  const TimetablePage({super.key});

  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
  int _selectedClass = 0;
  int _selectedPeriod = 0;
  int _selectedDayIdx = 0; // index into group.workDays

  static const _periods = ['Bu hafta', 'Bu oy', 'Bu yil'];

  @override
  void initState() {
    super.initState();
    _selectedDayIdx = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncDayToToday());
  }

  void _showAddHolidaySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddHolidaySheet(
        onSave: (holiday) =>
            context.read<CustomHolidayProvider>().add(holiday),
      ),
    );
  }

  void _showHolidaysList(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HolidaysListSheet(
        provider: context.read<CustomHolidayProvider>(),
      ),
    );
  }

  void _syncDayToToday() {
    final groups = context.read<ClassGroupProvider>().groups;
    if (groups.isEmpty) return;
    final workDays = groups[_selectedClass.clamp(0, groups.length - 1)].workDays;
    final todayWd = DateTime.now().weekday;
    // Find which workDay matches today
    for (int i = 0; i < workDays.length; i++) {
      if (_kDayNum[workDays[i]] == todayWd) {
        setState(() => _selectedDayIdx = i);
        return;
      }
    }
    setState(() => _selectedDayIdx = 0);
  }

  @override
  Widget build(BuildContext context) {
    final groups = context.watch<ClassGroupProvider>().groups;
    final scheduleProvider = context.watch<ScheduleProvider>();
    final holidays = context.watch<CustomHolidayProvider>().holidays;

    if (_selectedClass >= groups.length && groups.isNotEmpty) {
      _selectedClass = 0;
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      floatingActionButton: groups.isNotEmpty
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (holidays.isNotEmpty)
                  FloatingActionButton.small(
                    heroTag: 'holidays_list',
                    onPressed: () => _showHolidaysList(context),
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFE65100),
                    elevation: 2,
                    tooltip: 'Ta\'tillar ro\'yxati',
                    child: const Icon(Icons.list_rounded),
                  ),
                if (holidays.isNotEmpty) const SizedBox(height: 10),
                FloatingActionButton.extended(
                  heroTag: 'add_holiday',
                  onPressed: () => _showAddHolidaySheet(context),
                  backgroundColor: const Color(0xFFE65100),
                  foregroundColor: Colors.white,
                  elevation: 3,
                  icon: const Icon(Icons.beach_access_rounded, size: 20),
                  label: Text(
                    'Ta\'til qo\'shish',
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            )
          : null,
      body: groups.isEmpty
          ? _buildEmpty()
          : _buildWithGroups(context, groups, scheduleProvider),
    );
  }

  Widget _buildEmpty() {
    return Column(
      children: [
        _Header(
          groupNames: const [],
          selectedClass: 0,
          onClassChanged: (_) {},
          onStatsTap: () {},
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 52, color: AppColors.outlineVariant),
                const SizedBox(height: 12),
                Text(
                  'Sinflar qo\'shilmagan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Boshlash uchun sozlash jarayonini tugallang',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWithGroups(
    BuildContext context,
    List<ClassGroupModel> groups,
    ScheduleProvider scheduleProvider,
  ) {
    final group = groups[_selectedClass];
    final schedule = scheduleProvider.getForGroup(group.id);

    return Column(
      children: [
        _Header(
          groupNames: groups.map((g) => g.name).toList(),
          selectedClass: _selectedClass,
          onClassChanged: (i) {
            setState(() {
              _selectedClass = i;
              _selectedDayIdx = 0;
            });
            _syncDayToToday();
          },
          onStatsTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const StatisticsPage()),
          ),
        ),
        _PeriodBar(
          selected: _selectedPeriod,
          periods: _periods,
          onTap: (i) => setState(() => _selectedPeriod = i),
        ),
        Expanded(child: _buildContent(context, group, schedule, scheduleProvider)),
      ],
    );
  }

  Widget _buildContent(
    BuildContext context,
    ClassGroupModel group,
    ScheduleModel? schedule,
    ScheduleProvider scheduleProvider,
  ) {
    if (schedule == null) {
      return _NoScheduleView(
        group: group,
        isGenerating: scheduleProvider.isLoading,
        onGenerate: () => scheduleProvider.generateFor(group),
      );
    }

    switch (_selectedPeriod) {
      case 0:
        return _WeeklyView(
          group: group,
          schedule: schedule,
          selectedDayIdx: _selectedDayIdx,
          onDayTap: (i) => setState(() => _selectedDayIdx = i),
        );
      case 1:
        return _MonthlyView(group: group, schedule: schedule);
      case 2:
        return _YearlyView(group: group, schedule: schedule);
      default:
        return const SizedBox();
    }
  }
}

// ── No schedule view ────────────────────────────────────────────────────────────

class _NoScheduleView extends StatelessWidget {
  final ClassGroupModel group;
  final bool isGenerating;
  final VoidCallback onGenerate;

  const _NoScheduleView({
    required this.group,
    required this.isGenerating,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  size: 34, color: AppColors.primary),
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
              "${group.name} sinfi uchun dars jadvali\nhali yaratilmagan",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant,
                  height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 220,
              height: 48,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: isGenerating
                      ? null
                      : const LinearGradient(
                          colors: [Color(0xFF1565C0), Color(0xFF1E88E5)]),
                  color:
                      isGenerating ? AppColors.surfaceContainerHigh : null,
                  borderRadius: BorderRadius.circular(999),
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
                              mainAxisSize: MainAxisSize.min,
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
      ),
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final List<String> groupNames;
  final int selectedClass;
  final ValueChanged<int> onClassChanged;
  final VoidCallback onStatsTap;

  const _Header({
    required this.groupNames,
    required this.selectedClass,
    required this.onClassChanged,
    required this.onStatsTap,
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
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Dars Jadvali',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: onStatsTap,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.leaderboard_rounded,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 5),
                          Text(
                            'Statistika',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (groupNames.isNotEmpty)
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: groupNames.length,
                  separatorBuilder: (_, si) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final sel = i == selectedClass;
                    return GestureDetector(
                      onTap: () => onClassChanged(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: sel
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          groupNames[i],
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: sel ? AppColors.primaryContainer : Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Sinflar yo\'q',
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.7)),
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ── Period bar ─────────────────────────────────────────────────────────────────

class _PeriodBar extends StatelessWidget {
  final int selected;
  final List<String> periods;
  final ValueChanged<int> onTap;

  const _PeriodBar(
      {required this.selected, required this.periods, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceContainerLowest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          children: List.generate(periods.length, (i) {
            final sel = i == selected;
            return Expanded(
              child: GestureDetector(
                onTap: () => onTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: sel ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: sel
                        ? [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 4,
                                offset: const Offset(0, 1))
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      periods[i],
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight:
                            sel ? FontWeight.w600 : FontWeight.w400,
                        color: sel
                            ? AppColors.primaryContainer
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ── Weekly view ────────────────────────────────────────────────────────────────

class _WeeklyView extends StatefulWidget {
  final ClassGroupModel group;
  final ScheduleModel schedule;
  final int selectedDayIdx;
  final ValueChanged<int> onDayTap;

  const _WeeklyView({
    required this.group,
    required this.schedule,
    required this.selectedDayIdx,
    required this.onDayTap,
  });

  @override
  State<_WeeklyView> createState() => _WeeklyViewState();
}

class _WeeklyViewState extends State<_WeeklyView> {
  bool _isEditMode = false;

  @override
  void didUpdateWidget(_WeeklyView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDayIdx != widget.selectedDayIdx) {
      _isEditMode = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final customHolidays = context.watch<CustomHolidayProvider>();
    final workDays = widget.group.workDays;
    final safeIdx = widget.selectedDayIdx.clamp(0, workDays.length - 1);
    final selectedAbbr = workDays[safeIdx];
    final today = DateTime.now();
    final thisWeekDate = _weekDateFor(selectedAbbr);

    ScheduleDay? selectedDay;
    for (final d in widget.schedule.days) {
      if (d.day == selectedAbbr) {
        selectedDay = d;
        break;
      }
    }
    final lessons = selectedDay?.lessons ?? [];
    final customHolidayName = customHolidays.getHolidayName(thisWeekDate);

    return Column(
      children: [
        // Day selector
        Container(
          color: AppColors.surfaceContainerLowest,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(workDays.length, (i) {
              final abbr = workDays[i];
              final date = _weekDateFor(abbr);
              final isSelected = i == safeIdx;
              final isToday = date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;
              final hasCustomHoliday =
                  customHolidays.isHoliday(date);

              return GestureDetector(
                onTap: () => widget.onDayTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: workDays.length > 5 ? 44 : 52,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryContainer
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: isToday && !isSelected
                        ? Border.all(
                            color: AppColors.primaryContainer, width: 1.5)
                        : null,
                  ),
                  child: Column(
                    children: [
                      Text(
                        abbr,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.85)
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${date.day}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : isToday
                                  ? AppColors.primaryContainer
                                  : AppColors.onSurface,
                        ),
                      ),
                      if (isToday && !isSelected)
                        Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.only(top: 3),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                        )
                      else if (!isSelected && hasCustomHoliday)
                        Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.only(top: 3),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE65100),
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
        // Summary row with edit toggle
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
          child: Row(
            children: [
              Text(
                _isEditMode
                    ? 'Tartibni o\'zgartirish'
                    : '${_kDayFull[selectedAbbr] ?? selectedAbbr} — ${lessons.length} ta dars',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              const Spacer(),
              if (!_isEditMode &&
                  lessons.isNotEmpty &&
                  customHolidayName == null)
                Text(
                  '${lessons.first.startTime} – ${lessons.last.endTime}',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
              if (_isEditMode)
                TextButton(
                  onPressed: () => setState(() => _isEditMode = false),
                  child: Text(
                    'Tayyor',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                )
              else if (lessons.isNotEmpty || customHolidayName != null)
                IconButton(
                  onPressed: () => setState(() => _isEditMode = true),
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  color: AppColors.onSurfaceVariant,
                  tooltip: 'Tahrirlash',
                ),
            ],
          ),
        ),
        // Content
        Expanded(
          child: _buildDayContent(
              context, selectedDay, lessons, customHolidayName,
              thisWeekDate: thisWeekDate),
        ),
      ],
    );
  }

  Widget _buildDayContent(
    BuildContext context,
    ScheduleDay? selectedDay,
    List<ScheduleLesson> lessons,
    String? customHolidayName, {
    required DateTime thisWeekDate,
  }) {
    if (customHolidayName != null) {
      return _buildCustomHolidayView(context, customHolidayName, thisWeekDate);
    }

    if (lessons.isEmpty) return _EmptyDay();

    if (_isEditMode) {
      return _buildEditMode(context, selectedDay!, lessons);
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: lessons.length,
      separatorBuilder: (_, si) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final lesson = lessons[i];
        final br = i < (selectedDay?.breaks.length ?? 0)
            ? selectedDay!.breaks[i]
            : null;
        return Column(
          children: [
            _LessonCard(
              lesson: lesson,
              onTap: () {
                SubjectModel? subject;
                for (final s in widget.group.subjects) {
                  if (s.id == lesson.subjectId) {
                    subject = s;
                    break;
                  }
                }
                if (subject == null) return;
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => SubjectDetailPage(
                    subject: subject!,
                    schedule: widget.schedule,
                    groupName: widget.group.name,
                  ),
                ));
              },
            ),
            if (br != null) _BreakDivider(br: br),
          ],
        );
      },
    );
  }

  Widget _buildCustomHolidayView(
      BuildContext context, String name, DateTime date) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: const Color(0xFFFF8F00).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.beach_access_rounded,
                  size: 32, color: Color(0xFFE65100)),
            ),
            const SizedBox(height: 16),
            Text(
              name,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              'Bu kun ta\'til sifatida belgilangan',
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            if (_isEditMode)
              OutlinedButton.icon(
                onPressed: () => _removeCustomHoliday(context, date),
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                label: Text('Ta\'tilni o\'chirish',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE53935),
                  side: const BorderSide(color: Color(0xFFE53935)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditMode(BuildContext context, ScheduleDay selectedDay,
      List<ScheduleLesson> lessons) {
    return Column(
      children: [
        // Add holiday button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: InkWell(
            onTap: () => _showAddHolidaySheet(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFF8F00).withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFFFF8F00).withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.beach_access_rounded,
                      size: 17, color: Color(0xFFE65100)),
                  const SizedBox(width: 10),
                  Text(
                    'Qo\'shimcha ta\'til qo\'shish',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFE65100),
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.add_rounded,
                      size: 18, color: Color(0xFFE65100)),
                ],
              ),
            ),
          ),
        ),
        // Reorderable lessons
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            itemCount: lessons.length,
            onReorder: (oldIdx, newIdx) =>
                _onReorder(context, selectedDay, lessons, oldIdx, newIdx),
            itemBuilder: (ctx, i) => _EditLessonCard(
              key: ValueKey('${lessons[i].subjectId}_$i'),
              lesson: lessons[i],
            ),
          ),
        ),
      ],
    );
  }

  void _onReorder(BuildContext context, ScheduleDay day,
      List<ScheduleLesson> lessons, int oldIdx, int newIdx) {
    if (newIdx > oldIdx) newIdx--;
    final reordered = List<ScheduleLesson>.from(lessons);
    final moved = reordered.removeAt(oldIdx);
    reordered.insert(newIdx, moved);

    int cur = 8 * 60;
    final newLessons = <ScheduleLesson>[];
    final newBreaks = <ScheduleBreak>[];
    for (int i = 0; i < reordered.length; i++) {
      final l = reordered[i];
      final start = _fmtTime(cur);
      cur += widget.group.lessonDuration;
      final end = _fmtTime(cur);
      newLessons.add(ScheduleLesson(
        subjectId: l.subjectId,
        subjectName: l.subjectName,
        colorValue: l.colorValue,
        lessonNumber: i + 1,
        startTime: start,
        endTime: end,
      ));
      if (i < reordered.length - 1 && i < day.breaks.length) {
        final br = day.breaks[i];
        newBreaks.add(
            ScheduleBreak(time: end, duration: br.duration, isLarge: br.isLarge));
        cur += br.duration;
      }
    }

    final newDay =
        ScheduleDay(day: day.day, lessons: newLessons, breaks: newBreaks);
    final newDays = widget.schedule.days
        .map((d) => d.day == newDay.day ? newDay : d)
        .toList();
    final newSchedule = ScheduleModel(
      id: widget.schedule.id,
      groupId: widget.schedule.groupId,
      generatedAt: widget.schedule.generatedAt,
      days: newDays,
    );
    context.read<ScheduleProvider>().saveManual(newSchedule);
  }

  void _showAddHolidaySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddHolidaySheet(
        onSave: (holiday) =>
            context.read<CustomHolidayProvider>().add(holiday),
      ),
    );
  }

  void _removeCustomHoliday(BuildContext context, DateTime date) {
    final provider = context.read<CustomHolidayProvider>();
    final idx = provider.holidays.indexWhere((h) => h.covers(date));
    if (idx >= 0) provider.remove(idx);
    setState(() => _isEditMode = false);
  }
}

String _fmtTime(int totalMinutes) {
  final h = totalMinutes ~/ 60;
  final m = totalMinutes % 60;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}

class _LessonCard extends StatelessWidget {
  final ScheduleLesson lesson;
  final VoidCallback? onTap;

  const _LessonCard({required this.lesson, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = Color(lesson.colorValue);
    return GestureDetector(
      onTap: onTap,
      child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Row(
          children: [
            Container(width: 4, color: color),
            // Time column
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
              child: Column(
                children: [
                  Text(
                    lesson.startTime,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 14,
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    color: AppColors.outlineVariant,
                  ),
                  Text(
                    lesson.endTime,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            VerticalDivider(width: 1, color: AppColors.outlineVariant),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.subjectName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${lesson.lessonNumber}-dars',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '#${lesson.lessonNumber}',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
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

class _BreakDivider extends StatelessWidget {
  final ScheduleBreak br;

  const _BreakDivider({required this.br});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Row(
        children: [
          Icon(
            br.isLarge
                ? Icons.restaurant_outlined
                : Icons.local_cafe_outlined,
            size: 13,
            color: br.isLarge ? AppColors.secondary : AppColors.outline,
          ),
          const SizedBox(width: 6),
          Text(
            br.isLarge
                ? '${br.duration} daqiqa katta tanaffus'
                : '${br.duration} daqiqa tanaffus',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: br.isLarge ? AppColors.secondary : AppColors.outline,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Divider(
              color: br.isLarge
                  ? AppColors.secondary.withValues(alpha: 0.3)
                  : AppColors.outlineVariant,
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditLessonCard extends StatelessWidget {
  final ScheduleLesson lesson;

  const _EditLessonCard({required super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    final color = Color(lesson.colorValue);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Row(
          children: [
            Container(width: 4, color: color),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
              child: Column(
                children: [
                  Text(
                    lesson.startTime,
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface),
                  ),
                  Container(
                      width: 1,
                      height: 14,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      color: AppColors.outlineVariant),
                  Text(
                    lesson.endTime,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            VerticalDivider(width: 1, color: AppColors.outlineVariant),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.subjectName,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${lesson.lessonNumber}-dars',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 14),
              child: Icon(Icons.drag_handle_rounded,
                  size: 20, color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add custom holiday sheet ───────────────────────────────────────────────────

// ── Holidays list sheet ───────────────────────────────────────────────────────

class _HolidaysListSheet extends StatefulWidget {
  final CustomHolidayProvider provider;

  const _HolidaysListSheet({required this.provider});

  @override
  State<_HolidaysListSheet> createState() => _HolidaysListSheetState();
}

class _HolidaysListSheetState extends State<_HolidaysListSheet> {
  @override
  Widget build(BuildContext context) {
    final holidays = widget.provider.holidays;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle + header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                        color: AppColors.outlineVariant,
                        borderRadius: BorderRadius.circular(999)),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF8F00).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.beach_access_rounded,
                          size: 18, color: Color(0xFFE65100)),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Qo\'shimcha ta\'tillar',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF8F00).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${holidays.length} ta',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFE65100)),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1),
              ],
            ),
          ),
          // List
          Flexible(
            child: holidays.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.event_available_rounded,
                            size: 44, color: AppColors.outlineVariant),
                        const SizedBox(height: 12),
                        Text(
                          'Ta\'tillar yo\'q',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    shrinkWrap: true,
                    itemCount: holidays.length,
                    separatorBuilder: (_, idx) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final h = holidays[i];
                      final sameDay = h.startDate.year == h.endDate.year &&
                          h.startDate.month == h.endDate.month &&
                          h.startDate.day == h.endDate.day;
                      final dateLabel = sameDay
                          ? '${h.startDate.day} ${_kMonths[h.startDate.month - 1]} ${h.startDate.year}'
                          : '${h.startDate.day} ${_kMonths[h.startDate.month - 1]} – ${h.endDate.day} ${_kMonths[h.endDate.month - 1]} ${h.endDate.year}';
                      final dayCount = h.endDate
                              .difference(h.startDate)
                              .inDays +
                          1;

                      return Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8F0),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: const Color(0xFFFF8F00)
                                  .withValues(alpha: 0.25)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.fromLTRB(14, 6, 8, 6),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF8F00).withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.beach_access_rounded,
                                size: 18, color: Color(0xFFE65100)),
                          ),
                          title: Text(
                            h.name,
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurface),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '$dateLabel${dayCount > 1 ? ' ($dayCount kun)' : ''}',
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.onSurfaceVariant),
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => _openEdit(context, i, h),
                                icon: const Icon(Icons.edit_rounded, size: 18),
                                color: AppColors.onSurfaceVariant,
                                tooltip: 'Tahrirlash',
                              ),
                              IconButton(
                                onPressed: () =>
                                    _confirmDelete(context, i, h.name),
                                icon: const Icon(
                                    Icons.delete_outline_rounded, size: 20),
                                color: const Color(0xFFE53935),
                                tooltip: 'O\'chirish',
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
    );
  }

  void _openEdit(BuildContext context, int index, CustomHoliday holiday) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddHolidaySheet(
        initial: holiday,
        onSave: (updated) {
          widget.provider.update(index, updated);
          setState(() {});
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, int index, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Ta\'tilni o\'chirish',
          style: GoogleFonts.plusJakartaSans(
              fontSize: 17, fontWeight: FontWeight.w700),
        ),
        content: Text(
          '"$name" ta\'tilini o\'chirishni tasdiqlaysizmi?',
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Bekor', style: GoogleFonts.inter(color: AppColors.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () {
              widget.provider.remove(index);
              Navigator.pop(ctx);
              setState(() {});
            },
            child: Text(
              'O\'chirish',
              style: GoogleFonts.inter(
                  color: const Color(0xFFE53935), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Add custom holiday sheet ───────────────────────────────────────────────────

class _AddHolidaySheet extends StatefulWidget {
  final ValueChanged<CustomHoliday> onSave;
  final CustomHoliday? initial;

  const _AddHolidaySheet({required this.onSave, this.initial});

  bool get isEdit => initial != null;

  @override
  State<_AddHolidaySheet> createState() => _AddHolidaySheetState();
}

class _AddHolidaySheetState extends State<_AddHolidaySheet> {
  late final TextEditingController _nameCtrl;
  late DateTime _start;
  late DateTime _end;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _nameCtrl = TextEditingController(text: initial.name);
      _start = initial.startDate;
      _end = initial.endDate;
    } else {
      _nameCtrl = TextEditingController();
      final today = DateTime.now();
      _start = DateTime(today.year, today.month, today.day);
      _end = DateTime(today.year, today.month, today.day);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            24, 20, 24, MediaQuery.viewInsetsOf(context).bottom + 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(999)),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.isEdit ? 'Ta\'tilni tahrirlash' : 'Qo\'shimcha ta\'til qo\'shish',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Ta\'til nomi',
              hintText: 'masalan, Qo\'shimcha dam olish',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _DateChip(
                  label: 'Boshlanish',
                  date: _start,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _start,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) {
                      setState(() {
                        _start = picked;
                        if (_end.isBefore(_start)) _end = _start;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DateChip(
                  label: 'Tugash',
                  date: _end,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _end,
                      firstDate: _start,
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) setState(() => _end = picked);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                final name = _nameCtrl.text.trim();
                if (name.isEmpty) return;
                widget.onSave(
                    CustomHoliday(startDate: _start, endDate: _end, name: name));
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(
                'Saqlash',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const _DateChip(
      {required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 11, color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text(
              '${date.day} ${_kMonths[date.month - 1]}',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _EmptyDay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.event_busy_rounded,
              size: 52, color: AppColors.outlineVariant),
          const SizedBox(height: 12),
          Text(
            'Bu kun dars yo\'q',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Dam olish kuni yoki darslar kiritilmagan',
            style:
                GoogleFonts.inter(fontSize: 13, color: AppColors.outline),
          ),
        ],
      ),
    );
  }
}

// ── Monthly view ───────────────────────────────────────────────────────────────

class _MonthlyView extends StatefulWidget {
  final ClassGroupModel group;
  final ScheduleModel schedule;

  const _MonthlyView({required this.group, required this.schedule});

  @override
  State<_MonthlyView> createState() => _MonthlyViewState();
}

class _MonthlyViewState extends State<_MonthlyView> {
  late DateTime _month;
  DateTime? _selectedDate;

  static const _dayHeaders = ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _selectedDate = now;
  }

  int _lessonsOnWeekday(int wd) {
    for (final day in widget.schedule.days) {
      if (_kDayNum[day.day] == wd) return day.lessonCount;
    }
    return 0;
  }

  ScheduleDay? _scheduleForWeekday(int wd) {
    for (final day in widget.schedule.days) {
      if (_kDayNum[day.day] == wd) return day;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final customHolidays = context.watch<CustomHolidayProvider>();
    final now = DateTime.now();
    final firstDay = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final startPad = firstDay.weekday - 1;
    final rows = ((startPad + daysInMonth) / 7).ceil();

    int schoolDays = 0;
    int totalLessons = 0;
    for (int d = 1; d <= daysInMonth; d++) {
      final date = DateTime(_month.year, _month.month, d);
      if (SchoolCalendar.isHolidayOrBreak(date) ||
          customHolidays.isHoliday(date)) { continue; }
      final count = _lessonsOnWeekday(date.weekday);
      if (count > 0) {
        schoolDays++;
        totalLessons += count;
      }
    }

    final selDate = _selectedDate;
    final selHolidayInfo =
        selDate != null ? SchoolCalendar.getInfo(selDate) : null;
    final selCustomHoliday =
        selDate != null ? customHolidays.getHolidayName(selDate) : null;
    final selSchedule =
        selDate != null ? _scheduleForWeekday(selDate.weekday) : null;
    final selLessons = selSchedule?.lessons ?? [];
    final selBreaks = selSchedule?.breaks ?? [];
    final selHasLessons = selDate != null &&
        selHolidayInfo == null &&
        selCustomHoliday == null &&
        _lessonsOnWeekday(selDate.weekday) > 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Month navigation ──
          Row(
            children: [
              _NavButton(
                icon: Icons.chevron_left_rounded,
                onTap: () => setState(() {
                  _month = DateTime(_month.year, _month.month - 1);
                  _selectedDate = null;
                }),
              ),
              Expanded(
                child: Text(
                  '${_kMonths[_month.month - 1]} ${_month.year}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              _NavButton(
                icon: Icons.chevron_right_rounded,
                onTap: () => setState(() {
                  _month = DateTime(_month.year, _month.month + 1);
                  _selectedDate = null;
                }),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // ── Calendar card ──
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.outlineVariant),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(10, 14, 10, 14),
            child: Column(
              children: [
                // Day header row
                Row(
                  children: _dayHeaders.map((d) {
                    final isWeekend = d == 'Sh' || d == 'Ya';
                    return Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isWeekend
                                ? const Color(0xFFE53935)
                                    .withValues(alpha: 0.65)
                                : AppColors.onSurfaceVariant,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                const Divider(height: 1, color: Color(0xFFF0F0F0)),
                const SizedBox(height: 8),
                // Week rows
                ...List.generate(rows, (row) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: List.generate(7, (col) {
                        final cellIdx = row * 7 + col;
                        final day = cellIdx - startPad + 1;

                        if (day < 1 || day > daysInMonth) {
                          return const Expanded(child: SizedBox(height: 52));
                        }

                        final date =
                            DateTime(_month.year, _month.month, day);
                        final isToday = date.year == now.year &&
                            date.month == now.month &&
                            date.day == now.day;
                        final isSelected = selDate != null &&
                            date.year == selDate.year &&
                            date.month == selDate.month &&
                            date.day == selDate.day;
                        final wd = date.weekday;
                        final holidayInfo = SchoolCalendar.getInfo(date);
                        final customHolidayName =
                            customHolidays.getHolidayName(date);
                        final isHoliday =
                            holidayInfo != null && !holidayInfo.isBreak;
                        final isSchoolBreak =
                            holidayInfo != null && holidayInfo.isBreak;
                        final isCustomHoliday = customHolidayName != null;
                        final anyHoliday =
                            holidayInfo != null || isCustomHoliday;
                        final lessonCount = anyHoliday
                            ? 0
                            : _lessonsOnWeekday(wd);
                        final isWeekend = wd >= 6;
                        final dots = !anyHoliday
                            ? (_scheduleForWeekday(wd)
                                    ?.lessons
                                    .take(3)
                                    .map((l) => Color(l.colorValue))
                                    .toList() ??
                                [])
                            : <Color>[];
                        final overflow =
                            lessonCount > 3 ? lessonCount - 3 : 0;

                        return Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _selectedDate = date),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: 52,
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 2),
                              decoration: BoxDecoration(
                                gradient: isToday
                                    ? const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFF1565C0),
                                          Color(0xFF1E88E5),
                                        ],
                                      )
                                    : null,
                                color: isSelected && !isToday
                                    ? AppColors.primaryContainer
                                        .withValues(alpha: 0.1)
                                    : !isToday && isHoliday
                                        ? const Color(0xFFE53935)
                                            .withValues(alpha: 0.07)
                                        : !isToday &&
                                                (isSchoolBreak ||
                                                    isCustomHoliday)
                                            ? const Color(0xFFFF8F00)
                                                .withValues(alpha: 0.07)
                                            : null,
                                borderRadius: BorderRadius.circular(12),
                                border: isSelected && !isToday
                                    ? Border.all(
                                        color: AppColors.primaryContainer,
                                        width: 1.5,
                                      )
                                    : null,
                              ),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '$day',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: isToday || isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                      color: isToday
                                          ? Colors.white
                                          : isSelected
                                              ? AppColors.primaryContainer
                                              : isHoliday
                                                  ? const Color(0xFFB71C1C)
                                                      .withValues(alpha: 0.8)
                                                  : isSchoolBreak ||
                                                          isCustomHoliday
                                                      ? const Color(0xFFE65100)
                                                          .withValues(
                                                              alpha: 0.8)
                                                      : isWeekend
                                                          ? const Color(
                                                                  0xFFE53935)
                                                              .withValues(
                                                                  alpha: 0.65)
                                                          : AppColors.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  if (isToday)
                                    lessonCount > 0
                                        ? Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 5,
                                                    vertical: 1),
                                            decoration: BoxDecoration(
                                              color: Colors.white
                                                  .withValues(alpha: 0.25),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '$lessonCount',
                                              style: GoogleFonts.inter(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                          )
                                        : Icon(
                                            isHoliday
                                                ? Icons.celebration_rounded
                                                : Icons.beach_access_rounded,
                                            size: 10,
                                            color: Colors.white
                                                .withValues(alpha: 0.8),
                                          )
                                  else if (isHoliday)
                                    Icon(
                                      Icons.celebration_rounded,
                                      size: 10,
                                      color: const Color(0xFFE53935)
                                          .withValues(alpha: 0.6),
                                    )
                                  else if (isSchoolBreak || isCustomHoliday)
                                    Icon(
                                      Icons.beach_access_rounded,
                                      size: 10,
                                      color: const Color(0xFFFF8F00)
                                          .withValues(alpha: 0.6),
                                    )
                                  else if (dots.isNotEmpty)
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        ...dots.map(
                                          (c) => Container(
                                            width: 5,
                                            height: 5,
                                            margin: const EdgeInsets
                                                .symmetric(horizontal: 1),
                                            decoration: BoxDecoration(
                                              color: c,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                        if (overflow > 0)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left: 1),
                                            child: Text(
                                              '+$overflow',
                                              style: GoogleFonts.inter(
                                                fontSize: 7,
                                                color: AppColors
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                          ),
                                      ],
                                    )
                                  else
                                    const SizedBox(height: 5),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                }),
              ],
            ),
          ),
          // ── Selected day panel ──
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: selDate != null
                ? selHolidayInfo != null
                    ? _HolidayInfoCard(date: selDate, info: selHolidayInfo)
                    : selCustomHoliday != null
                        ? _CustomHolidayInfoCard(
                            date: selDate, name: selCustomHoliday)
                    : selHasLessons
                        ? _SelectedDayPanel(
                            date: selDate,
                            lessons: selLessons,
                            breaks: selBreaks,
                          )
                        : Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 20, horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: AppColors.outlineVariant),
                              ),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.event_busy_rounded,
                                    size: 28,
                                    color: AppColors.outlineVariant,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Bu kunda dars yo\'q',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 20),
          // ── Stats section ──
          Text(
            '${_kMonths[_month.month - 1]} oyi statistikasi',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          _MonthStats(schoolDays: schoolDays, totalLessons: totalLessons),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Icon(icon, size: 20, color: AppColors.onSurface),
      ),
    );
  }
}

class _SelectedDayPanel extends StatelessWidget {
  final DateTime date;
  final List<ScheduleLesson> lessons;
  final List<ScheduleBreak> breaks;

  const _SelectedDayPanel({
    required this.date,
    required this.lessons,
    required this.breaks,
  });

  @override
  Widget build(BuildContext context) {
    final dayAbbr =
        ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'][date.weekday - 1];
    final dayFull = _kDayFull[dayAbbr] ?? dayAbbr;
    final monthName = _kMonths[date.month - 1];

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
                ),
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dayFull,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${date.day} $monthName, ${date.year}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${lessons.length} ta dars',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                children: List.generate(lessons.length, (i) {
                  final lesson = lessons[i];
                  final br = i < breaks.length ? breaks[i] : null;
                  final color = Color(lesson.colorValue);

                  return Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 3,
                            height: 38,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lesson.subjectName,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                                Text(
                                  '${lesson.startTime} – ${lesson.endTime}',
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
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${lesson.lessonNumber}-dars',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (br != null)
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(15, 4, 0, 4),
                          child: Row(
                            children: [
                              Icon(
                                br.isLarge
                                    ? Icons.restaurant_outlined
                                    : Icons.local_cafe_outlined,
                                size: 11,
                                color: br.isLarge
                                    ? AppColors.secondary
                                    : AppColors.outline,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '${br.duration} daqiqa${br.isLarge ? ' katta' : ''} tanaffus',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontStyle: FontStyle.italic,
                                  color: br.isLarge
                                      ? AppColors.secondary
                                      : AppColors.outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HolidayInfoCard extends StatelessWidget {
  final DateTime date;
  final HolidayInfo info;

  const _HolidayInfoCard({required this.date, required this.info});

  @override
  Widget build(BuildContext context) {
    final isBreak = info.isBreak;
    final accent =
        isBreak ? const Color(0xFFE65100) : const Color(0xFFB71C1C);
    final bg = isBreak
        ? const Color(0xFFFFF3E0)
        : const Color(0xFFFFEBEE);
    final border =
        isBreak ? const Color(0xFFFF8F00) : const Color(0xFFE53935);
    final icon = isBreak
        ? Icons.beach_access_rounded
        : Icons.celebration_rounded;
    final dayAbbr =
        ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'][date.weekday - 1];
    final dayFull = _kDayFull[dayAbbr] ?? dayAbbr;
    final monthName = _kMonths[date.month - 1];

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: border.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: border.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accent, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$dayFull, ${date.day} $monthName ${date.year}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: accent.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isBreak ? "Ta'til kuni — dars bo'lmaydi" : "Dam olish kuni — dars bo'lmaydi",
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomHolidayInfoCard extends StatelessWidget {
  final DateTime date;
  final String name;

  const _CustomHolidayInfoCard({required this.date, required this.name});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFE65100);
    const bg = Color(0xFFFFF3E0);
    const border = Color(0xFFFF8F00);
    final dayAbbr =
        ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'][date.weekday - 1];
    final dayFull = _kDayFull[dayAbbr] ?? dayAbbr;
    final monthName = _kMonths[date.month - 1];

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: border.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: border.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.beach_access_rounded,
                  color: accent, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: accent),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$dayFull, ${date.day} $monthName ${date.year}',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: accent.withValues(alpha: 0.7)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Qo\'shimcha ta\'til — dars bo\'lmaydi',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthStats extends StatelessWidget {
  final int schoolDays;
  final int totalLessons;

  const _MonthStats(
      {required this.schoolDays, required this.totalLessons});

  @override
  Widget build(BuildContext context) {
    final avg = schoolDays > 0 ? totalLessons / schoolDays : 0.0;

    final cards = [
      (
        icon: Icons.calendar_month_rounded,
        label: 'Maktab kunlari',
        value: '$schoolDays',
        color: AppColors.primaryContainer,
      ),
      (
        icon: Icons.menu_book_rounded,
        label: 'Jami darslar',
        value: '$totalLessons',
        color: const Color(0xFF388E3C),
      ),
      (
        icon: Icons.trending_up_rounded,
        label: "Kuniga o'rtacha",
        value: avg.toStringAsFixed(1),
        color: const Color(0xFFF57C00),
      ),
    ];

    return Row(
      children: List.generate(cards.length, (i) {
        final c = cards[i];
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < cards.length - 1 ? 8 : 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.color.withValues(alpha: 0.25)),
              boxShadow: [
                BoxShadow(
                  color: c.color.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: c.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(c.icon, size: 16, color: c.color),
                ),
                const SizedBox(height: 8),
                Text(
                  c.value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: c.color,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  c.label,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppColors.onSurfaceVariant,
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

// ── Yearly view ────────────────────────────────────────────────────────────────

class _YearlyView extends StatefulWidget {
  final ClassGroupModel group;
  final ScheduleModel schedule;

  const _YearlyView({required this.group, required this.schedule});

  @override
  State<_YearlyView> createState() => _YearlyViewState();
}

class _YearlyViewState extends State<_YearlyView> {
  // Start year of the academic year (e.g. 2025 = "2025–2026 o'quv yili")
  late int _startYear;

  // Sep–Dec use _startYear; Jan–May use _startYear + 1
  static const _academicMonthNums = [9, 10, 11, 12, 1, 2, 3, 4, 5];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startYear = now.month >= 9 ? now.year : now.year - 1;
  }

  int _yearFor(int month) => month >= 9 ? _startYear : _startYear + 1;

  int _lessonsInMonth(int year, int month) {
    int total = 0;
    final days = DateTime(year, month + 1, 0).day;
    for (int d = 1; d <= days; d++) {
      final date = DateTime(year, month, d);
      if (SchoolCalendar.isHolidayOrBreak(date)) continue;
      for (final day in widget.schedule.days) {
        if (_kDayNum[day.day] == date.weekday) {
          total += day.lessonCount;
          break;
        }
      }
    }
    return total;
  }

  int _schoolDaysInMonth(int year, int month) {
    int count = 0;
    final days = DateTime(year, month + 1, 0).day;
    for (int d = 1; d <= days; d++) {
      final date = DateTime(year, month, d);
      if (SchoolCalendar.isHolidayOrBreak(date)) continue;
      for (final day in widget.schedule.days) {
        if (_kDayNum[day.day] == date.weekday && day.lessonCount > 0) {
          count++;
          break;
        }
      }
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    // Build per-month data for the 9 academic months (Sep–May)
    final monthData = _academicMonthNums.map((m) {
      final y = _yearFor(m);
      return (
        year: y,
        month: m,
        name: _kMonths[m - 1],
        lessons: _lessonsInMonth(y, m),
        schoolDays: _schoolDaysInMonth(y, m),
        offDays: SchoolCalendar.offDaysInMonth(y, m),
      );
    }).toList();

    final lessonCounts = monthData.map((m) => m.lessons).toList();
    final maxLessons =
        lessonCounts.isEmpty ? 1 : lessonCounts.reduce((a, b) => a > b ? a : b);
    final totalYear = lessonCounts.fold(0, (s, c) => s + c);
    final totalSchoolDays = monthData.fold(0, (s, m) => s + m.schoolDays);
    final busiestIdx = maxLessons > 0 ? lessonCounts.indexOf(maxLessons) : -1;

    // Holidays filtered to academic year range (Sep of _startYear – May of _startYear+1)
    final yearHolidays = [
      ...SchoolCalendar.publicHolidaysForYear(_startYear)
          .where((h) => h.start.month >= 9),
      ...SchoolCalendar.publicHolidaysForYear(_startYear + 1)
          .where((h) => h.start.month <= 5),
    ]..sort((a, b) => a.start.compareTo(b.start));

    // School breaks filtered and merged (Qishki ta'til spans Dec–Jan)
    final rawBreaks = [
      ...SchoolCalendar.schoolBreaksForYear(_startYear)
          .where((b) => b.start.month >= 9),
      ...SchoolCalendar.schoolBreaksForYear(_startYear + 1)
          .where((b) => b.start.month <= 5),
    ]..sort((a, b) => a.start.compareTo(b.start));
    final yearBreaks = <({DateTime start, DateTime end, String name})>[];
    for (final br in rawBreaks) {
      if (yearBreaks.isNotEmpty && yearBreaks.last.name == br.name) {
        final last = yearBreaks.removeLast();
        yearBreaks.add((
          start: last.start,
          end: br.end.isAfter(last.end) ? br.end : last.end,
          name: last.name,
        ));
      } else {
        yearBreaks.add(br);
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Academic year navigation ──
          Row(
            children: [
              _NavButton(
                icon: Icons.chevron_left_rounded,
                onTap: () => setState(() => _startYear--),
              ),
              Expanded(
                child: Text(
                  "$_startYear–${_startYear + 1} o'quv yili",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              _NavButton(
                icon: Icons.chevron_right_rounded,
                onTap: () => setState(() => _startYear++),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // ── Year summary banner ──
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1565C0).withValues(alpha: 0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                _YearStat(
                  icon: Icons.menu_book_rounded,
                  label: 'Jami darslar',
                  value: '$totalYear',
                ),
                _YearStatDivider(),
                _YearStat(
                  icon: Icons.calendar_today_rounded,
                  label: 'Maktab kunlari',
                  value: '$totalSchoolDays',
                ),
                _YearStatDivider(),
                _YearStat(
                  icon: Icons.star_rounded,
                  label: "Eng ko'p",
                  value: busiestIdx >= 0 ? monthData[busiestIdx].name : '—',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // ── Month grid (9 school months: Sep–May) ──
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.92,
            ),
            itemCount: monthData.length,
            itemBuilder: (_, i) {
              final m = monthData[i];
              final isCurrentMonth =
                  m.year == now.year && m.month == now.month;
              final isPast = m.year < now.year ||
                  (m.year == now.year && m.month < now.month);
              final fraction = maxLessons > 0 ? m.lessons / maxLessons : 0.0;

              return _MonthCard(
                monthName: m.name,
                lessonCount: m.lessons,
                schoolDays: m.schoolDays,
                offDays: m.offDays,
                fraction: fraction,
                isCurrentMonth: isCurrentMonth,
                isPast: isPast,
              );
            },
          ),
          const SizedBox(height: 20),
          _YearlyHolidaySection(
            year: _startYear,
            holidays: yearHolidays,
            breaks: yearBreaks,
          ),
        ],
      ),
    );
  }
}

class _YearStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _YearStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.85), size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.75),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _YearStatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: Colors.white.withValues(alpha: 0.2),
    );
  }
}

class _MonthCard extends StatelessWidget {
  final String monthName;
  final int lessonCount;
  final int schoolDays;
  final int offDays;
  final double fraction;
  final bool isCurrentMonth;
  final bool isPast;

  const _MonthCard({
    required this.monthName,
    required this.lessonCount,
    required this.schoolDays,
    required this.offDays,
    required this.fraction,
    required this.isCurrentMonth,
    required this.isPast,
  });

  @override
  Widget build(BuildContext context) {
    final Color accent = isPast
        ? AppColors.onSurfaceVariant
        : const Color(0xFF1E88E5);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
      decoration: BoxDecoration(
        gradient: isCurrentMonth
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
              )
            : null,
        color: isCurrentMonth ? null : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentMonth
              ? Colors.transparent
              : isPast
                  ? AppColors.outlineVariant
                  : AppColors.primaryContainer.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: (isCurrentMonth
                    ? const Color(0xFF1565C0)
                    : Colors.black)
                .withValues(
                    alpha: isCurrentMonth ? 0.18 : 0.04),
            blurRadius: isCurrentMonth ? 12 : 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month name + status badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  monthName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isCurrentMonth
                        ? Colors.white
                        : AppColors.onSurface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isCurrentMonth
                      ? Colors.white.withValues(alpha: 0.2)
                      : isPast
                          ? AppColors.surfaceContainerHigh
                          : AppColors.primaryContainer
                              .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isCurrentMonth
                      ? 'Hozir'
                      : isPast
                          ? "O'tdi"
                          : 'Kelasi',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: isCurrentMonth
                        ? Colors.white
                        : isPast
                            ? AppColors.onSurfaceVariant
                            : AppColors.primaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          // Lesson count (big)
          Text(
            '$lessonCount',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: isCurrentMonth ? Colors.white : accent,
              height: 1,
            ),
          ),
          Text(
            'ta dars · $schoolDays kun',
            style: GoogleFonts.inter(
              fontSize: 10,
              color: isCurrentMonth
                  ? Colors.white.withValues(alpha: 0.75)
                  : AppColors.onSurfaceVariant,
            ),
          ),
          if (offDays > 0)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Row(
                children: [
                  Icon(
                    Icons.celebration_rounded,
                    size: 10,
                    color: isCurrentMonth
                        ? Colors.white.withValues(alpha: 0.65)
                        : const Color(0xFFE53935).withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '$offDays dam olish',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: isCurrentMonth
                          ? Colors.white.withValues(alpha: 0.65)
                          : const Color(0xFFE53935).withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(
                  height: 5,
                  color: isCurrentMonth
                      ? Colors.white.withValues(alpha: 0.25)
                      : AppColors.surfaceContainerHigh,
                ),
                FractionallySizedBox(
                  widthFactor: fraction,
                  child: Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: isCurrentMonth
                          ? Colors.white
                          : isPast
                              ? AppColors.onSurfaceVariant
                                  .withValues(alpha: 0.45)
                              : const Color(0xFF1E88E5),
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
  }
}

// ── Yearly holiday section ─────────────────────────────────────────────────────

class _YearlyHolidaySection extends StatelessWidget {
  final int year;
  final List<({DateTime start, DateTime? end, String name})> holidays;
  final List<({DateTime start, DateTime end, String name})> breaks;

  const _YearlyHolidaySection({
    required this.year,
    required this.holidays,
    required this.breaks,
  });

  String _fmt(DateTime d) => '${d.day} ${_kMonths[d.month - 1]}';

  String _range(DateTime start, DateTime? end) {
    if (end == null) return _fmt(start);
    if (start.month == end.month) {
      return '${start.day}–${end.day} ${_kMonths[start.month - 1]}';
    }
    return '${_fmt(start)} – ${_fmt(end)}';
  }

  @override
  Widget build(BuildContext context) {
    if (holidays.isEmpty && breaks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Bayramlar va ta'tillar",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            children: [
              if (holidays.isNotEmpty) ...[
                _HolidayGroupHeader(
                  icon: Icons.celebration_rounded,
                  label: 'Rasmiy bayramlar',
                  color: const Color(0xFFE53935),
                ),
                ...holidays.asMap().entries.map((e) => _HolidayRow(
                      icon: Icons.celebration_rounded,
                      iconColor: const Color(0xFFE53935),
                      name: e.value.name,
                      dateStr: _range(e.value.start, e.value.end),
                      isLast: breaks.isEmpty &&
                          e.key == holidays.length - 1,
                    )),
              ],
              if (breaks.isNotEmpty) ...[
                _HolidayGroupHeader(
                  icon: Icons.beach_access_rounded,
                  label: "Maktab ta'tillari",
                  color: const Color(0xFFFF8F00),
                ),
                ...breaks.asMap().entries.map((e) => _HolidayRow(
                      icon: Icons.beach_access_rounded,
                      iconColor: const Color(0xFFFF8F00),
                      name: e.value.name,
                      dateStr: _range(e.value.start, e.value.end),
                      isLast: e.key == breaks.length - 1,
                    )),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _HolidayGroupHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _HolidayGroupHeader({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        border: Border(
          bottom: BorderSide(color: color.withValues(alpha: 0.15)),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _HolidayRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String name;
  final String dateStr;
  final bool isLast;

  const _HolidayRow({
    required this.icon,
    required this.iconColor,
    required this.name,
    required this.dateStr,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(
                  color: Color(0xFFF0F0F0),
                  width: 0.5,
                ),
              ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 13, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.onSurface,
              ),
            ),
          ),
          Text(
            dateStr,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
