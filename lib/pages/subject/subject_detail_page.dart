import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/subject_model.dart';
import '../../core/models/schedule_model.dart';

const _kDayFull = {
  'Du': 'Dushanba',
  'Se': 'Seshanba',
  'Ch': 'Chorshanba',
  'Pa': 'Payshanba',
  'Ju': 'Juma',
  'Sh': 'Shanba',
  'Ya': 'Yakshanba',
};

String _difficultyLabel(SubjectDifficulty d) => switch (d) {
      SubjectDifficulty.veryHard => 'Juda qiyin',
      SubjectDifficulty.hard => 'Qiyin',
      SubjectDifficulty.medium => "O'rta",
      SubjectDifficulty.easy => 'Yengil',
      SubjectDifficulty.veryEasy => 'Juda yengil',
    };

String _difficultyStars(SubjectDifficulty d) => switch (d) {
      SubjectDifficulty.veryHard => '★★★★★',
      SubjectDifficulty.hard => '★★★★',
      SubjectDifficulty.medium => '★★★',
      SubjectDifficulty.easy => '★★',
      SubjectDifficulty.veryEasy => '★',
    };

Color _difficultyColor(SubjectDifficulty d) => switch (d) {
      SubjectDifficulty.veryHard => const Color(0xFFD32F2F),
      SubjectDifficulty.hard => const Color(0xFFF57C00),
      SubjectDifficulty.medium => const Color(0xFF1565C0),
      SubjectDifficulty.easy => const Color(0xFF388E3C),
      SubjectDifficulty.veryEasy => const Color(0xFF66BB6A),
    };

class SubjectDetailPage extends StatelessWidget {
  final SubjectModel subject;
  final ScheduleModel schedule;
  final String groupName;

  const SubjectDetailPage({
    super.key,
    required this.subject,
    required this.schedule,
    required this.groupName,
  });

  @override
  Widget build(BuildContext context) {
    final subjectColor = Color(subject.colorValue);
    final diff = subject.difficulty;

    // Ushbu fan jadvalda qaysi kun va vaqtda bor
    final occurrences = <(ScheduleDay, ScheduleLesson)>[];
    for (final day in schedule.days) {
      for (final lesson in day.lessons) {
        if (lesson.subjectId == subject.id) {
          occurrences.add((day, lesson));
        }
      }
    }

    final yearlyHours = subject.hoursPerWeek * 36;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          _buildHeader(context, subjectColor, diff),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatsRow(
                    weeklyHours: subject.hoursPerWeek,
                    weeklyLessons: occurrences.length,
                    yearlyHours: yearlyHours,
                  ),
                  const SizedBox(height: 20),
                  _ScheduleSection(occurrences: occurrences),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, Color subjectColor, SubjectDifficulty diff) {
    final darker =
        Color.lerp(subjectColor, Colors.black, 0.3) ?? subjectColor;
    final diffColor = _difficultyColor(diff);

    return SliverToBoxAdapter(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [darker, subjectColor],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white),
                    ),
                    Expanded(
                      child: Text(
                        groupName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _difficultyStars(diff),
                                style: TextStyle(
                                  fontSize: 10,
                                  color:
                                      diffColor == const Color(0xFFD32F2F)
                                          ? Colors.redAccent[100]
                                          : Colors.white,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _difficultyLabel(diff),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${subject.hoursPerWeek} soat/hafta',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Stats row ───────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final int weeklyHours;
  final int weeklyLessons;
  final int yearlyHours;

  const _StatsRow({
    required this.weeklyHours,
    required this.weeklyLessons,
    required this.yearlyHours,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        label: 'Haftalik soat',
        value: '${weeklyHours}h',
        icon: Icons.schedule_rounded,
        color: AppColors.primary,
      ),
      (
        label: 'Haftalik dars',
        value: '$weeklyLessons ta',
        icon: Icons.calendar_today_rounded,
        color: const Color(0xFF388E3C),
      ),
      (
        label: 'Yillik soat',
        value: '${yearlyHours}h',
        icon: Icons.auto_stories_rounded,
        color: const Color(0xFFF57C00),
      ),
    ];

    return Row(
      children: items.asMap().entries.map((e) {
        final i = e.key;
        final s = e.value;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(left: i == 0 ? 0 : 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: s.color.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(s.icon, size: 18, color: s.color),
                const SizedBox(height: 8),
                Text(
                  s.value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: s.color,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  s.label,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Schedule section ────────────────────────────────────────────────────────────

class _ScheduleSection extends StatelessWidget {
  final List<(ScheduleDay, ScheduleLesson)> occurrences;

  const _ScheduleSection({required this.occurrences});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Haftalik jadval',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        if (occurrences.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Center(
              child: Text(
                'Jadvalda topilmadi',
                style: GoogleFonts.inter(
                    fontSize: 14, color: AppColors.onSurfaceVariant),
              ),
            ),
          )
        else
          ...occurrences.asMap().entries.map((e) {
            final i = e.key;
            final (day, lesson) = e.value;
            final dayFull = _kDayFull[day.day] ?? day.day;
            final isLast = i == occurrences.length - 1;

            return Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 8),
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outlineVariant),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${lesson.lessonNumber}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
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
                          dayFull,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.schedule_rounded,
                                size: 12,
                                color: AppColors.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(
                              '${lesson.startTime} – ${lesson.endTime}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${lesson.lessonNumber}-dars',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}
