import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/class_group_provider.dart';
import '../../core/providers/schedule_provider.dart';
import '../onboarding/onboarding_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Notifications

  // ── Actions ──────────────────────────────────────────────────────────────────

  Future<void> _regenerateAll() async {
    // Capture before any await
    final scheduleProvider = context.read<ScheduleProvider>();
    final groups = context.read<ClassGroupProvider>().groups;
    if (groups.isEmpty) return;

    final confirm = await _showConfirm(
      title: 'Jadvallarni qayta yaratish',
      message:
          'Barcha ${groups.length} ta sinf uchun dars jadvali qayta yaratiladi. Mavjud jadvallar o\'chiriladi.',
      confirmLabel: 'Qayta yaratish',
      confirmColor: AppColors.primary,
    );
    if (!confirm || !mounted) return;

    for (final g in groups) {
      await scheduleProvider.generateFor(g);
    }
    if (mounted) {
      _showSnack('${groups.length} ta jadval muvaffaqiyatli yaratildi');
    }
  }

  Future<void> _deleteAllSchedules() async {
    // Capture before any await
    final scheduleProvider = context.read<ScheduleProvider>();
    final snack = ScaffoldMessenger.of(context);

    final confirm = await _showConfirm(
      title: 'Barcha jadvallarni o\'chirish',
      message:
          'Barcha sinflarning dars jadvallari o\'chiriladi. Bu amalni qaytarib bo\'lmaydi.',
      confirmLabel: 'O\'chirish',
      confirmColor: AppColors.error,
    );
    if (!confirm || !mounted) return;

    await scheduleProvider.deleteAll();
    if (mounted) {
      snack.showSnackBar(
        SnackBar(
          content: Text(
            "Barcha jadvallar o'chirildi",
            style: GoogleFonts.inter(fontSize: 13),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _resetAllData() async {
    // Capture before any await
    final groupProvider = context.read<ClassGroupProvider>();
    final scheduleProvider = context.read<ScheduleProvider>();
    final nav = Navigator.of(context);

    final confirm = await _showConfirm(
      title: 'Barcha ma\'lumotlarni o\'chirish',
      message:
          'Barcha sinflar, fanlar va jadvallar to\'liq o\'chiriladi. Ilova boshidan sozlanadi.',
      confirmLabel: 'Hammasini o\'chirish',
      confirmColor: AppColors.error,
    );
    if (!confirm || !mounted) return;

    await scheduleProvider.deleteAll();
    await groupProvider.deleteAll();

    if (!mounted) return;
    nav.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const OnboardingPage()),
      (route) => false,
    );
  }

  Future<bool> _showConfirm({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.onSurfaceVariant,
            height: 1.5,
          ),
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
            child: Text(
              confirmLabel,
              style: GoogleFonts.inter(
                color: confirmColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter(fontSize: 13)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupProvider = context.watch<ClassGroupProvider>();
    final scheduleProvider = context.watch<ScheduleProvider>();

    final groupCount = groupProvider.groups.length;
    final totalSubjects = groupProvider.groups.fold(
      0,
      (s, g) => s + g.subjects.length,
    );
    final scheduledCount = groupProvider.groups
        .where((g) => scheduleProvider.hasForGroup(g.id))
        .length;
    final totalHours = groupProvider.groups.fold(
      0,
      (s, g) => s + g.subjects.fold(0, (ss, sub) => ss + sub.hoursPerWeek),
    );

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: _SettingsHeader()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Profile
                const _ProfileCard(),
                const SizedBox(height: 20),

                // Data overview
                _DataOverview(
                  groupCount: groupCount,
                  subjectCount: totalSubjects,
                  scheduledCount: scheduledCount,
                  totalHours: totalHours,
                ),
                const SizedBox(height: 20),

                // Schedule management
                _SectionLabel("Jadval boshqaruvi"),
                const SizedBox(height: 10),
                _SettingsCard(
                  children: [
                    _ActionTile(
                      icon: Icons.auto_awesome_rounded,
                      iconColor: AppColors.primary,
                      title: 'Barcha jadvallarni qayta yaratish',
                      subtitle: '$scheduledCount ta jadval bor',
                      onTap: scheduleProvider.isLoading ? null : _regenerateAll,
                      loading: scheduleProvider.isLoading,
                    ),
                    _Divider(),
                    _ActionTile(
                      icon: Icons.delete_sweep_rounded,
                      iconColor: const Color(0xFFF57C00),
                      title: 'Barcha jadvallarni o\'chirish',
                      subtitle: 'Sinflar saqlanib qoladi',
                      onTap: scheduledCount == 0 ? null : _deleteAllSchedules,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // About
                _SectionLabel('Dastur haqida'),
                const SizedBox(height: 10),
                _SettingsCard(
                  children: [
                    const _InfoTile(
                      icon: Icons.info_outline_rounded,
                      iconColor: AppColors.primaryContainer,
                      title: 'Versiya',
                      value: 'v1.0.0 (beta)',
                    ),
                    _Divider(),
                    const _InfoTile(
                      icon: Icons.code_rounded,
                      iconColor: Color(0xFF388E3C),
                      title: 'Dasturchi',
                      value: 'Yoriqulov Miraziz',
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Reset button
                _DangerButton(
                  icon: Icons.delete_forever_rounded,
                  label: "Barcha ma'lumotlarni o'chirish",
                  onTap: _resetAllData,
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data overview ──────────────────────────────────────────────────────────────

class _DataOverview extends StatelessWidget {
  final int groupCount;
  final int subjectCount;
  final int scheduledCount;
  final int totalHours;

  const _DataOverview({
    required this.groupCount,
    required this.subjectCount,
    required this.scheduledCount,
    required this.totalHours,
  });

  @override
  Widget build(BuildContext context) {
    if (groupCount == 0) return const SizedBox();

    final items = [
      (
        label: 'Sinflar',
        value: '$groupCount',
        icon: Icons.school_rounded,
        color: AppColors.primary,
      ),
      (
        label: 'Fanlar',
        value: '$subjectCount',
        icon: Icons.menu_book_rounded,
        color: const Color(0xFF388E3C),
      ),
      (
        label: 'Jadvallar',
        value: '$scheduledCount',
        icon: Icons.calendar_month_rounded,
        color: const Color(0xFF0097A7),
      ),
      (
        label: 'Soat/hafta',
        value: '${totalHours}h',
        icon: Icons.schedule_rounded,
        color: const Color(0xFFF57C00),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.06),
            AppColors.primary.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Joriy ma'lumotlar",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: items
                .map(
                  (it) => Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: it.color.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(it.icon, size: 17, color: it.color),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          it.value,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: it.color,
                          ),
                        ),
                        Text(
                          it.label,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────────

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader();

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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.settings_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Sozlamalar',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Profile card ───────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  const _ProfileCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                'MY',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
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
                  'Yoriqulov Miraziz',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Jadval administratori raqami: \n+998 99 700 28 19',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'TATU',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryContainer,
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

// ── Shared building blocks ─────────────────────────────────────────────────────

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

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 64,
      color: AppColors.outlineVariant.withValues(alpha: 0.6),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool loading;

  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (disabled ? AppColors.outline : iconColor).withValues(
                  alpha: 0.1,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: loading
                  ? Padding(
                      padding: const EdgeInsets.all(9),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: iconColor,
                      ),
                    )
                  : Icon(
                      icon,
                      size: 18,
                      color: disabled ? AppColors.outline : iconColor,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: disabled
                          ? AppColors.onSurfaceVariant
                          : AppColors.onSurface,
                    ),
                  ),
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
              Icons.chevron_right_rounded,
              size: 18,
              color: disabled
                  ? AppColors.outlineVariant
                  : AppColors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.onSurface,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _DangerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DangerButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.error, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
