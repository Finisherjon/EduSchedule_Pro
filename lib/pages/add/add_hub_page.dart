import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/class_group_model.dart';
import '../../core/providers/class_group_provider.dart';
import '../../core/providers/schedule_provider.dart';
import '../setup/class_setup_page.dart';
import '../classes/edit_classes_page.dart';

const _kPalette = [
  Color(0xFF1565C0), Color(0xFF388E3C), Color(0xFFF57C00),
  Color(0xFF7B1FA2), Color(0xFF0097A7), Color(0xFFD32F2F),
];
Color _accentFor(int i) => _kPalette[i % _kPalette.length];

class AddHubPage extends StatelessWidget {
  const AddHubPage({super.key});

  void _goToNewClass(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            const ClassSetupPage(),
      ),
    );
  }

  void _showGroupPicker(BuildContext context, List<ClassGroupModel> groups) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _GroupPickerSheet(
        groups: groups,
        onSelect: (group, index) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => EditClassesPage(
                group: group,
                accentColor: _accentFor(index),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _generateForGroup(
    BuildContext context,
    ClassGroupModel group,
  ) async {
    final sp = context.read<ScheduleProvider>();
    await sp.generateFor(group);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${group.name} uchun jadval yaratildi',
            style: GoogleFonts.inter(fontSize: 13),
          ),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final groups = context.watch<ClassGroupProvider>().groups;
    final sp = context.watch<ScheduleProvider>();
    final groupsWithoutSchedule =
        groups.where((g) => !sp.hasForGroup(g.id)).toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Main actions
                _SectionLabel("Yangi element qo'shish"),
                const SizedBox(height: 10),
                _MainActionCard(
                  icon: Icons.group_add_rounded,
                  bgIcon: Icons.group_rounded,
                  title: 'Yangi sinf / guruh',
                  subtitle: "Guruh xususiyatlari va fanlarni belgilash",
                  badge: null,
                  onTap: () => _goToNewClass(context),
                ),
                const SizedBox(height: 10),
                _MainActionCard(
                  icon: Icons.library_add_rounded,
                  bgIcon: Icons.menu_book_rounded,
                  title: 'Fan qo\'shish / tahrirlash',
                  subtitle: groups.isEmpty
                      ? 'Avval sinf qo\'shing'
                      : '${groups.length} ta sinfdan birini tanlang',
                  badge: groups.isEmpty ? null : '${groups.length}',
                  disabled: groups.isEmpty,
                  onTap: groups.isEmpty
                      ? null
                      : () => _showGroupPicker(context, groups),
                ),

                // Schedule status
                if (groups.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _SectionLabel('Jadval holati'),
                  const SizedBox(height: 10),
                  if (groupsWithoutSchedule.isEmpty)
                    _AllSchedulesReady(groupCount: groups.length)
                  else
                    _SchedulePendingList(
                      groups: groups,
                      pending: groupsWithoutSchedule,
                      sp: sp,
                      onGenerate: (g) => _generateForGroup(context, g),
                    ),
                ],

                // Quick access — only if groups have schedules
                if (groups.length > groupsWithoutSchedule.length) ...[
                  const SizedBox(height: 24),
                  _SectionLabel('Tezkor kirish'),
                  const SizedBox(height: 10),
                  _QuickAccessGrid(
                    groups: groups,
                    sp: sp,
                    onGroupTap: (g, i) => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            EditClassesPage(group: g, accentColor: _accentFor(i)),
                      ),
                    ),
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.school_rounded,
                      color: Colors.white, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'EduSchedule Pro',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                "Qo'shish",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Sinf, fan qo'shish yoki jadval yaratish",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section label ───────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurfaceVariant,
        letterSpacing: 0.3,
      ),
    );
  }
}

// ── Main action card ────────────────────────────────────────────────────────────

class _MainActionCard extends StatelessWidget {
  final IconData icon;
  final IconData bgIcon;
  final String title;
  final String subtitle;
  final String? badge;
  final bool disabled;
  final VoidCallback? onTap;

  const _MainActionCard({
    required this.icon,
    required this.bgIcon,
    required this.title,
    required this.subtitle,
    this.badge,
    this.disabled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor =
        disabled ? AppColors.outlineVariant : AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: disabled
                ? AppColors.outlineVariant
                : AppColors.primary.withValues(alpha: 0.2),
          ),
          boxShadow: disabled
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(bgIcon,
                      color: AppColors.outlineVariant, size: 32),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 18),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: disabled
                              ? AppColors.onSurfaceVariant
                              : AppColors.onSurface,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            badge!,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_rounded,
              color: primaryColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ── All schedules ready ─────────────────────────────────────────────────────────

class _AllSchedulesReady extends StatelessWidget {
  final int groupCount;

  const _AllSchedulesReady({required this.groupCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF388E3C).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0xFF388E3C).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF388E3C).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded,
                color: Color(0xFF388E3C), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Barcha jadvallar tayyor',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF388E3C),
                  ),
                ),
                Text(
                  '$groupCount ta sinf uchun dars jadvali mavjud',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
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

// ── Schedule pending list ───────────────────────────────────────────────────────

class _SchedulePendingList extends StatelessWidget {
  final List<ClassGroupModel> groups;
  final List<ClassGroupModel> pending;
  final ScheduleProvider sp;
  final Future<void> Function(ClassGroupModel) onGenerate;

  const _SchedulePendingList({
    required this.groups,
    required this.pending,
    required this.sp,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Summary banner
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF57C00).withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: const Color(0xFFF57C00).withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 18, color: Color(0xFFF57C00)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${pending.length} ta sinf uchun jadval yaratilmagan',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFFF57C00),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Cards per pending group
        ...pending.map((g) {
          final idx = groups.indexOf(g);
          final accent = _accentFor(idx < 0 ? 0 : idx);
          final isGenerating = sp.isLoading;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.outlineVariant),
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
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      g.name.length > 4 ? g.name.substring(0, 4) : g.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
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
                        g.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                      ),
                      Text(
                        '${g.subjects.length} fan · ${g.workDays.length} ish kuni',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: isGenerating ? null : () => onGenerate(g),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isGenerating
                          ? AppColors.surfaceContainerHigh
                          : AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: isGenerating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.auto_awesome_rounded,
                                  color: Colors.white, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                'Yaratish',
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
          );
        }),
      ],
    );
  }
}

// ── Quick access grid ───────────────────────────────────────────────────────────

class _QuickAccessGrid extends StatelessWidget {
  final List<ClassGroupModel> groups;
  final ScheduleProvider sp;
  final void Function(ClassGroupModel, int) onGroupTap;

  const _QuickAccessGrid({
    required this.groups,
    required this.sp,
    required this.onGroupTap,
  });

  @override
  Widget build(BuildContext context) {
    // Only show groups that already have a schedule
    final ready = groups
        .asMap()
        .entries
        .where((e) => sp.hasForGroup(e.value.id))
        .toList();

    if (ready.isEmpty) return const SizedBox();

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.5,
      children: ready.map((e) {
        final i = e.key;
        final group = e.value;
        final accent = _accentFor(i);
        final schedule = sp.getForGroup(group.id);
        final totalHours =
            group.subjects.fold(0, (s, sub) => s + sub.hoursPerWeek);

        return GestureDetector(
          onTap: () => onGroupTap(group, i),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: accent.withValues(alpha: 0.25)),
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
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          group.name.length > 4
                              ? group.name.substring(0, 4)
                              : group.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF388E3C),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  group.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  schedule != null
                      ? '${schedule.totalLessons} dars · ${totalHours}h'
                      : '${group.subjects.length} fan',
                  style: GoogleFonts.inter(
                    fontSize: 11,
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

// ── Group picker sheet ──────────────────────────────────────────────────────────

class _GroupPickerSheet extends StatelessWidget {
  final List<ClassGroupModel> groups;
  final void Function(ClassGroupModel, int) onSelect;

  const _GroupPickerSheet({
    required this.groups,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Column(
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
                    'Fan qo\'shish uchun sinfni tanlang',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            Flexible(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                shrinkWrap: true,
                itemCount: groups.length,
                itemBuilder: (_, i) {
                  final group = groups[i];
                  final accent = _accentFor(i);
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      onSelect(group, i);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 13),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.outlineVariant),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                group.name.length > 4
                                    ? group.name.substring(0, 4)
                                    : group.name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
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
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                                Text(
                                  '${group.subjects.length} ta fan',
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppColors.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded,
                              size: 18, color: AppColors.onSurfaceVariant),
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
    );
  }
}
