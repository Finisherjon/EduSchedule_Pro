import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/class_group_model.dart';
import '../../core/models/subject_model.dart';
import '../../core/providers/class_group_provider.dart';
import '../../core/providers/schedule_provider.dart';
import 'edit_classes_page.dart';
import '../subject/subject_detail_page.dart';

const _kPalette = [
  Color(0xFF1565C0),
  Color(0xFF388E3C),
  Color(0xFFF57C00),
  Color(0xFF7B1FA2),
  Color(0xFF0097A7),
  Color(0xFFD32F2F),
];

Color _accentFor(int index) => _kPalette[index % _kPalette.length];

String _difficultyLabel(SubjectDifficulty d) => switch (d) {
      SubjectDifficulty.veryHard => 'Juda qiyin',
      SubjectDifficulty.hard => 'Qiyin',
      SubjectDifficulty.medium => "O'rta",
      SubjectDifficulty.easy => 'Yengil',
      SubjectDifficulty.veryEasy => 'Juda yengil',
    };

Color _difficultyColor(SubjectDifficulty d) => switch (d) {
      SubjectDifficulty.veryHard => const Color(0xFF6A1B1B),
      SubjectDifficulty.hard => const Color(0xFFD32F2F),
      SubjectDifficulty.medium => const Color(0xFFF57C00),
      SubjectDifficulty.easy => const Color(0xFF388E3C),
      SubjectDifficulty.veryEasy => const Color(0xFF66BB6A),
    };

class ClassesPage extends StatefulWidget {
  const ClassesPage({super.key});

  @override
  State<ClassesPage> createState() => _ClassesPageState();
}

class _ClassesPageState extends State<ClassesPage> {
  final Map<String, bool> _expanded = {};

  Future<void> _confirmDelete(ClassGroupModel group) async {
    final classProvider = context.read<ClassGroupProvider>();
    final scheduleProvider = context.read<ScheduleProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Sinfni o'chirish",
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        content: Text(
          "'${group.name}' sinfini va uning jadvalini o'chirmoqchimisiz?\n\nBu amalni qaytarib bo'lmaydi.",
          style: GoogleFonts.inter(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Bekor qilish',
              style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(
              "O'chirish",
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await classProvider.delete(group.id);
    await scheduleProvider.deleteForGroup(group.id);
    _expanded.remove(group.id);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClassGroupProvider>();
    final groups = provider.groups;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                _GradientHeader(classCount: groups.length),
                if (groups.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(),
                  )
                else ...[
                  SliverToBoxAdapter(child: _SummaryRow(groups: groups)),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) {
                          final group = groups[i];
                          final color = _accentFor(i);
                          return _ClassCard(
                            group: group,
                            accentColor: color,
                            expanded: _expanded[group.id] ?? false,
                            onToggle: () => setState(
                              () => _expanded[group.id] =
                                  !(_expanded[group.id] ?? false),
                            ),
                            onEdit: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => EditClassesPage(
                                  group: group,
                                  accentColor: color,
                                ),
                              ),
                            ),
                            onDelete: () => _confirmDelete(group),
                          );
                        },
                        childCount: groups.length,
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

// ── Empty state ─────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
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
              child: const Icon(
                Icons.groups_outlined,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Sinflar mavjud emas',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Sozlash jarayonida sinflar va fanlar qo'shiladi",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Gradient header ─────────────────────────────────────────────────────────────

class _GradientHeader extends StatelessWidget {
  final int classCount;

  const _GradientHeader({required this.classCount});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.groups_rounded,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'EduSchedule Pro',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$classCount ta sinf',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Sinflar',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Barcha sinflar va ularning fanlarini boshqaring',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Summary row ─────────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final List<ClassGroupModel> groups;

  const _SummaryRow({required this.groups});

  @override
  Widget build(BuildContext context) {
    final totalSubjects = groups.fold(0, (s, g) => s + g.subjects.length);
    final totalHours = groups.fold(
      0,
      (s, g) => s + g.subjects.fold(0, (ss, sub) => ss + sub.hoursPerWeek),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          _StatCard(
            icon: Icons.groups_rounded,
            label: 'Jami sinflar',
            value: '${groups.length}',
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          _StatCard(
            icon: Icons.menu_book_rounded,
            label: 'Jami fanlar',
            value: '$totalSubjects',
            color: const Color(0xFF388E3C),
          ),
          const SizedBox(width: 10),
          _StatCard(
            icon: Icons.schedule_rounded,
            label: 'Haftalik soat',
            value: '$totalHours',
            color: const Color(0xFFF57C00),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color,
                height: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Class card ──────────────────────────────────────────────────────────────────

class _ClassCard extends StatelessWidget {
  final ClassGroupModel group;
  final Color accentColor;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ClassCard({
    required this.group,
    required this.accentColor,
    required this.expanded,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: expanded
              ? accentColor.withValues(alpha: 0.4)
              : AppColors.outlineVariant,
          width: expanded ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: expanded
                ? accentColor.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: expanded ? 12 : 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _CardHeader(
            group: group,
            accentColor: accentColor,
            expanded: expanded,
            onToggle: onToggle,
            onEdit: onEdit,
            onDelete: onDelete,
          ),
          if (expanded) ...[
            Divider(height: 1, color: accentColor.withValues(alpha: 0.15)),
            _SubjectsList(
              subjects: group.subjects,
              groupId: group.id,
              groupName: group.name,
            ),
          ],
        ],
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  final ClassGroupModel group;
  final Color accentColor;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CardHeader({
    required this.group,
    required this.accentColor,
    required this.expanded,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final initials = group.name.length > 5
        ? group.name.substring(0, 5)
        : group.name;

    return GestureDetector(
      onTap: onToggle,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                  textAlign: TextAlign.center,
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
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: 5),
                        decoration: BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(
                        group.language,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${group.subjects.length} fan',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onEdit,
              child: Container(
                width: 34,
                height: 34,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  size: 17,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
            GestureDetector(
              onTap: onDelete,
              child: Container(
                width: 34,
                height: 34,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.2)),
                ),
                child: Icon(
                  Icons.delete_outline_rounded,
                  size: 17,
                  color: AppColors.error.withValues(alpha: 0.8),
                ),
              ),
            ),
            AnimatedRotation(
              turns: expanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: expanded ? accentColor : AppColors.onSurfaceVariant,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubjectsList extends StatelessWidget {
  final List<SubjectModel> subjects;
  final String groupId;
  final String groupName;

  const _SubjectsList({
    required this.subjects,
    required this.groupId,
    required this.groupName,
  });

  @override
  Widget build(BuildContext context) {
    final schedule =
        context.read<ScheduleProvider>().getForGroup(groupId);

    if (subjects.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        child: Text(
          "Fanlar qo'shilmagan",
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.outline,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      child: Column(
        children: subjects.asMap().entries.map((e) {
          final i = e.key;
          final sub = e.value;
          return Padding(
            padding:
                EdgeInsets.only(bottom: i < subjects.length - 1 ? 8 : 0),
            child: _SubjectRow(
              subject: sub,
              onTap: schedule == null
                  ? null
                  : () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SubjectDetailPage(
                            subject: sub,
                            schedule: schedule,
                            groupName: groupName,
                          ),
                        ),
                      ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SubjectRow extends StatelessWidget {
  final SubjectModel subject;
  final VoidCallback? onTap;

  const _SubjectRow({required this.subject, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = Color(subject.colorValue);
    final p = subject.difficulty;
    final pColor = _difficultyColor(p);

    return GestureDetector(
      onTap: onTap,
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject.name,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded,
                        size: 11, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: 3),
                    Text(
                      '${subject.hoursPerWeek} soat/hafta',
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
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: pColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _difficultyLabel(p),
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: pColor,
              ),
            ),
          ),
        ],
      ),
    ),
  );
  }
}
