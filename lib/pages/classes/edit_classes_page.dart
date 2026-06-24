import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/class_group_model.dart';
import '../../core/models/subject_model.dart';
import '../../core/providers/class_group_provider.dart';
import '../../core/providers/schedule_provider.dart';

const _kSubjectColors = [
  Color(0xFFBA1A1A),
  Color(0xFF006AA9),
  Color(0xFF47A1FF),
  Color(0xFF1565C0),
  Color(0xFF388E3C),
  Color(0xFFF57C00),
  Color(0xFF7B1FA2),
  Color(0xFF00838F),
];

String _diffLabel(SubjectDifficulty d) => switch (d) {
      SubjectDifficulty.veryHard => 'Juda qiyin',
      SubjectDifficulty.hard => 'Qiyin',
      SubjectDifficulty.medium => "O'rta",
      SubjectDifficulty.easy => 'Yengil',
      SubjectDifficulty.veryEasy => 'Juda yengil',
    };

Color _diffColor(SubjectDifficulty d) => switch (d) {
      SubjectDifficulty.veryHard => const Color(0xFFD32F2F),
      SubjectDifficulty.hard => const Color(0xFFE64A19),
      SubjectDifficulty.medium => const Color(0xFFF57C00),
      SubjectDifficulty.easy => const Color(0xFF388E3C),
      SubjectDifficulty.veryEasy => const Color(0xFF66BB6A),
    };

// ── Page ───────────────────────────────────────────────────────────────────────

class EditClassesPage extends StatefulWidget {
  final ClassGroupModel group;
  final Color accentColor;

  const EditClassesPage({
    super.key,
    required this.group,
    required this.accentColor,
  });

  @override
  State<EditClassesPage> createState() => _EditClassesPageState();
}

class _EditClassesPageState extends State<EditClassesPage> {
  late final TextEditingController _nameCtrl;
  late int _selectedLang;
  late Set<String> _selectedDays;
  late double _maxLessons;
  late int _lessonDuration;
  late List<LargeBreakConfig> _largeBreaks;
  late int _smallBreakDuration;
  late List<SubjectModel> _subjects;
  bool _saving = false;

  static const _langs = ["O'zbek", 'Rus', 'English'];
  static const _allDays = ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh'];

  @override
  void initState() {
    super.initState();
    final g = widget.group;
    _nameCtrl = TextEditingController(text: g.name);
    _selectedLang = _langs.indexOf(g.language).clamp(0, _langs.length - 1);
    _selectedDays = Set<String>.from(g.workDays);
    _maxLessons = g.maxLessonsPerDay.toDouble().clamp(3, 10);
    _lessonDuration = g.lessonDuration;
    _largeBreaks = List<LargeBreakConfig>.from(g.largeBreaks);
    _smallBreakDuration = g.smallBreakDuration;
    _subjects = List<SubjectModel>.from(g.subjects);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  List<LargeBreakConfig> _buildLargeBreaks() => _largeBreaks;

  Future<void> _saveAndPop() async {
    if (_saving) return;
    setState(() => _saving = true);
    final updated = widget.group.copyWith(
      name: _nameCtrl.text.trim().isEmpty ? widget.group.name : _nameCtrl.text.trim(),
      language: _langs[_selectedLang],
      workDays: _selectedDays.toList(),
      maxLessonsPerDay: _maxLessons.round(),
      lessonDuration: _lessonDuration,
      largeBreaks: _buildLargeBreaks(),
      smallBreakDuration: _smallBreakDuration,
      subjects: _subjects,
    );
    final classProvider = context.read<ClassGroupProvider>();
    final scheduleProvider = context.read<ScheduleProvider>();
    await classProvider.save(updated);
    await scheduleProvider.generateFor(updated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${updated.name} jadvali qayta tuzildi',
            style: GoogleFonts.inter(fontSize: 13),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    }
  }

  void _showSubjectSheet({int? index}) {
    final existing = index != null ? _subjects[index] : null;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SubjectSheet(
        initial: existing,
        onSave: (name, hours, difficulty) {
          setState(() {
            if (index == null) {
              final colorIdx = _subjects.length;
              _subjects.add(SubjectModel(
                name: name,
                hoursPerWeek: hours,
                manualDifficulty: difficulty,
                colorValue:
                    _kSubjectColors[colorIdx % _kSubjectColors.length].toARGB32(),
              ));
            } else {
              _subjects[index] = _subjects[index].copyWith(
                name: name,
                hoursPerWeek: hours,
                manualDifficulty: difficulty,
                clearManualDifficulty: difficulty == null,
              );
            }
          });
        },
      ),
    );
  }

  void _deleteSubject(int index) => setState(() => _subjects.removeAt(index));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          _Header(
            group: widget.group,
            onBack: () => Navigator.pop(context),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionCard(
                    accentColor: AppColors.primaryContainer,
                    icon: Icons.school_rounded,
                    title: "Sinf ma'lumotlari",
                    child: _BasicInfoSection(
                      nameCtrl: _nameCtrl,
                      selectedLang: _selectedLang,
                      langs: _langs,
                      onLangChanged: (v) => setState(() => _selectedLang = v),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    accentColor: const Color(0xFF0097A7),
                    icon: Icons.calendar_month_rounded,
                    title: 'Dars jadvali',
                    child: _ScheduleSection(
                      allDays: _allDays,
                      selectedDays: _selectedDays,
                      maxLessons: _maxLessons,
                      lessonDuration: _lessonDuration,
                      onDayToggle: (d) => setState(() {
                        if (_selectedDays.contains(d)) {
                          if (_selectedDays.length > 1) _selectedDays.remove(d);
                        } else {
                          _selectedDays.add(d);
                        }
                      }),
                      onMaxLessonsChanged: (v) => setState(() => _maxLessons = v),
                      onDurationChanged: (v) => setState(() => _lessonDuration = v),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    accentColor: const Color(0xFFF57C00),
                    icon: Icons.coffee_rounded,
                    title: 'Tanaffuslar',
                    child: _BreaksSection(
                      largeBreaks: _largeBreaks,
                      smallBreakDuration: _smallBreakDuration,
                      onAddLargeBreak: () => setState(() {
                        if (_largeBreaks.length < 2) {
                          _largeBreaks.add(LargeBreakConfig());
                        }
                      }),
                      onRemoveLargeBreak: (i) =>
                          setState(() => _largeBreaks.removeAt(i)),
                      onLargeAfterLessonChanged: (i, v) =>
                          setState(() => _largeBreaks[i].afterLesson = v),
                      onLargeDurationChanged: (i, v) =>
                          setState(() => _largeBreaks[i].duration = v),
                      onSmallDurationChanged: (v) =>
                          setState(() => _smallBreakDuration = v),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SubjectsSection(
                    subjects: _subjects,
                    classColor: widget.accentColor,
                    onEdit: (i) => _showSubjectSheet(index: i),
                    onDelete: _deleteSubject,
                    onAdd: () => _showSubjectSheet(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _SaveBar(saving: _saving, onSave: _saveAndPop),
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final ClassGroupModel group;
  final VoidCallback onBack;

  const _Header({required this.group, required this.onBack});

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
          padding: const EdgeInsets.fromLTRB(8, 8, 20, 20),
          child: Row(
            children: [
              _CircleBtn(icon: Icons.arrow_back_rounded, onTap: onBack),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Tahrirlash',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
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

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

// ── Section card ───────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final Color accentColor;
  final IconData icon;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.accentColor,
    required this.icon,
    required this.title,
    required this.child,
  });

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
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section title bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.06),
                border: Border(
                  bottom: BorderSide(color: accentColor.withValues(alpha: 0.15)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 15, color: accentColor),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Basic info section ─────────────────────────────────────────────────────────

class _BasicInfoSection extends StatelessWidget {
  final TextEditingController nameCtrl;
  final int selectedLang;
  final List<String> langs;
  final ValueChanged<int> onLangChanged;

  const _BasicInfoSection({
    required this.nameCtrl,
    required this.selectedLang,
    required this.langs,
    required this.onLangChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel('Sinf nomi'),
        const SizedBox(height: 8),
        TextField(
          controller: nameCtrl,
          style: GoogleFonts.inter(fontSize: 15, color: AppColors.onSurface),
          decoration: _inputDeco('Masalan: 10-A'),
        ),
        const SizedBox(height: 16),
        _FieldLabel("Ta'lim tili"),
        const SizedBox(height: 8),
        Row(
          children: List.generate(langs.length, (i) {
            final sel = i == selectedLang;
            return GestureDetector(
              onTap: () => onLangChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: EdgeInsets.only(right: i < langs.length - 1 ? 8 : 0),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? AppColors.primaryContainer : AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: sel ? AppColors.primaryContainer : AppColors.outlineVariant,
                  ),
                ),
                child: Text(
                  langs[i],
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: sel ? Colors.white : AppColors.onSurface,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  static InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: AppColors.outline, fontSize: 14),
        filled: true,
        fillColor: AppColors.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      );
}

// ── Schedule section ───────────────────────────────────────────────────────────

class _ScheduleSection extends StatelessWidget {
  final List<String> allDays;
  final Set<String> selectedDays;
  final double maxLessons;
  final int lessonDuration;
  final ValueChanged<String> onDayToggle;
  final ValueChanged<double> onMaxLessonsChanged;
  final ValueChanged<int> onDurationChanged;

  const _ScheduleSection({
    required this.allDays,
    required this.selectedDays,
    required this.maxLessons,
    required this.lessonDuration,
    required this.onDayToggle,
    required this.onMaxLessonsChanged,
    required this.onDurationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel('Dars kunlari'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: allDays.map((day) {
            final sel = selectedDays.contains(day);
            return GestureDetector(
              onTap: () => onDayToggle(day),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: sel ? AppColors.primaryContainer : AppColors.surfaceContainerLow,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: sel ? AppColors.primaryContainer : AppColors.outlineVariant,
                  ),
                ),
                child: Center(
                  child: Text(
                    day,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: sel ? Colors.white : AppColors.onSurface,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _FieldLabel('Kunlik max dars soni'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${maxLessons.round()} ta',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryContainer,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
          ),
          child: Slider(
            value: maxLessons,
            min: 3,
            max: 10,
            divisions: 7,
            activeColor: AppColors.primaryContainer,
            inactiveColor: AppColors.surfaceContainerHigh,
            onChanged: onMaxLessonsChanged,
          ),
        ),
        const SizedBox(height: 8),
        _FieldLabel('Dars davomiyligi'),
        const SizedBox(height: 10),
        Row(
          children: [45, 60, 90].map((mins) {
            final sel = lessonDuration == mins;
            return GestureDetector(
              onTap: () => onDurationChanged(mins),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  color: sel ? AppColors.primaryContainer : AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: sel ? AppColors.primaryContainer : AppColors.outlineVariant,
                  ),
                ),
                child: Text(
                  '$mins min',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: sel ? Colors.white : AppColors.onSurface,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ── Breaks section ─────────────────────────────────────────────────────────────

class _BreaksSection extends StatelessWidget {
  final List<LargeBreakConfig> largeBreaks;
  final int smallBreakDuration;
  final VoidCallback onAddLargeBreak;
  final ValueChanged<int> onRemoveLargeBreak;
  final void Function(int index, int value) onLargeAfterLessonChanged;
  final void Function(int index, int value) onLargeDurationChanged;
  final ValueChanged<int> onSmallDurationChanged;

  const _BreaksSection({
    required this.largeBreaks,
    required this.smallBreakDuration,
    required this.onAddLargeBreak,
    required this.onRemoveLargeBreak,
    required this.onLargeAfterLessonChanged,
    required this.onLargeDurationChanged,
    required this.onSmallDurationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _FieldLabel('Katta tanaffuslar'),
            if (largeBreaks.length < 2)
              GestureDetector(
                onTap: onAddLargeBreak,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded, size: 14, color: AppColors.primary),
                    const SizedBox(width: 3),
                    Text(
                      "Qo'shish",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        ...List.generate(
          largeBreaks.length,
          (i) => Padding(
            padding: EdgeInsets.only(bottom: i < largeBreaks.length - 1 ? 10 : 0),
            child: _LargeBreakCard(
              index: i,
              config: largeBreaks[i],
              canRemove: largeBreaks.length > 1,
              onRemove: () => onRemoveLargeBreak(i),
              onAfterLessonChanged: (v) => onLargeAfterLessonChanged(i, v),
              onDurationChanged: (v) => onLargeDurationChanged(i, v),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _SmallBreakRow(
          duration: smallBreakDuration,
          onChanged: onSmallDurationChanged,
        ),
      ],
    );
  }
}

class _LargeBreakCard extends StatelessWidget {
  final int index;
  final LargeBreakConfig config;
  final bool canRemove;
  final VoidCallback onRemove;
  final ValueChanged<int> onAfterLessonChanged;
  final ValueChanged<int> onDurationChanged;

  const _LargeBreakCard({
    required this.index,
    required this.config,
    required this.canRemove,
    required this.onRemove,
    required this.onAfterLessonChanged,
    required this.onDurationChanged,
  });

  static const _durations = [5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Katta tanaffus ${index + 1}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              const Spacer(),
              if (canRemove)
                GestureDetector(
                  onTap: onRemove,
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.error.withValues(alpha: 0.7),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Qaysi darsdan keyin',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              _BreakStepper(
                value: config.afterLesson,
                min: 1,
                max: 8,
                suffix: '-dars',
                onChanged: onAfterLessonChanged,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Davomiyligi',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          _MinutesWheelPicker(
            value: config.duration,
            values: _durations,
            suffix: ' daq.',
            onChanged: onDurationChanged,
          ),
        ],
      ),
    );
  }
}

class _SmallBreakRow extends StatelessWidget {
  final int duration;
  final ValueChanged<int> onChanged;

  const _SmallBreakRow({required this.duration, required this.onChanged});

  static const _durations = [
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kichik tanaffus',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Darslar orasidagi tanaffus davomiyligi',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          _MinutesWheelPicker(
            value: duration,
            values: _durations,
            suffix: ' daq.',
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _BreakStepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final String suffix;
  final ValueChanged<int> onChanged;

  const _BreakStepper({
    required this.value,
    required this.min,
    required this.max,
    required this.suffix,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepBtn(
            icon: Icons.remove_rounded,
            enabled: value > min,
            onTap: () => onChanged(value - 1),
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 52),
            alignment: Alignment.center,
            child: Text(
              '$value$suffix',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          _StepBtn(
            icon: Icons.add_rounded,
            enabled: value < max,
            onTap: () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }
}

class _MinutesWheelPicker extends StatefulWidget {
  final int value;
  final List<int> values;
  final String suffix;
  final ValueChanged<int> onChanged;

  const _MinutesWheelPicker({
    required this.value,
    required this.values,
    required this.suffix,
    required this.onChanged,
  });

  @override
  State<_MinutesWheelPicker> createState() => _MinutesWheelPickerState();
}

class _MinutesWheelPickerState extends State<_MinutesWheelPicker> {
  late FixedExtentScrollController _controller;
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.values.indexOf(widget.value);
    if (_selectedIndex < 0) _selectedIndex = 0;
    _controller = FixedExtentScrollController(initialItem: _selectedIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 34,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
          ),
          ListWheelScrollView.useDelegate(
            controller: _controller,
            itemExtent: 34,
            perspective: 0.003,
            diameterRatio: 1.8,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: (i) {
              setState(() => _selectedIndex = i);
              widget.onChanged(widget.values[i]);
            },
            childDelegate: ListWheelChildListDelegate(
              children: widget.values.asMap().entries.map((e) {
                final sel = e.key == _selectedIndex;
                return Center(
                  child: Text(
                    '${e.value}${widget.suffix}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: sel ? 17 : 13,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                      color: sel
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant.withValues(alpha: 0.45),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _StepBtn({required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 38,
          height: 42,
          child: Icon(
            icon,
            size: 18,
            color: enabled ? AppColors.primary : AppColors.outline,
          ),
        ),
      ),
    );
  }
}

// ── Subjects section ───────────────────────────────────────────────────────────

class _SubjectsSection extends StatelessWidget {
  final List<SubjectModel> subjects;
  final Color classColor;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onDelete;
  final VoidCallback onAdd;

  const _SubjectsSection({
    required this.subjects,
    required this.classColor,
    required this.onEdit,
    required this.onDelete,
    required this.onAdd,
  });

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
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            decoration: BoxDecoration(
              color: classColor.withValues(alpha: 0.06),
              border: Border(
                bottom: BorderSide(color: classColor.withValues(alpha: 0.15)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: classColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.menu_book_rounded, size: 15, color: classColor),
                ),
                const SizedBox(width: 10),
                Text(
                  'Fanlar',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: classColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${subjects.length} ta',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: classColor,
                    ),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          "Qo'shish",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Subject list
          if (subjects.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Center(
                child: Text(
                  "Fanlar qo'shilmagan. \"+Qo'shish\" tugmasini bosing.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: subjects.asMap().entries.map((e) {
                  final i = e.key;
                  final sub = e.value;
                  return Padding(
                    padding: EdgeInsets.only(bottom: i < subjects.length - 1 ? 8 : 0),
                    child: _SubjectRow(
                      subject: sub,
                      onEdit: () => onEdit(i),
                      onDelete: () => onDelete(i),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _SubjectRow extends StatelessWidget {
  final SubjectModel subject;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SubjectRow({
    required this.subject,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(subject.colorValue);
    final diff = subject.difficulty;
    final dColor = _diffColor(diff);

    return GestureDetector(
      onTap: onEdit,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 9, 6, 9),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
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
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded,
                          size: 11, color: AppColors.onSurfaceVariant),
                      const SizedBox(width: 3),
                      Text(
                        '${subject.hoursPerWeek} soat/hafta',
                        style: GoogleFonts.inter(
                            fontSize: 11, color: AppColors.onSurfaceVariant),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: dColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _diffLabel(diff),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: dColor,
                          ),
                        ),
                      ),
                      if (subject.manualDifficulty == null) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.auto_mode_rounded,
                            size: 10, color: AppColors.primary.withValues(alpha: 0.6)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.edit_outlined,
                  size: 18, color: AppColors.primary.withValues(alpha: 0.7)),
              onPressed: onEdit,
              visualDensity: VisualDensity.compact,
              tooltip: 'Tahrirlash',
            ),
            IconButton(
              icon: Icon(Icons.delete_outline_rounded,
                  size: 18, color: AppColors.error.withValues(alpha: 0.7)),
              onPressed: onDelete,
              visualDensity: VisualDensity.compact,
              tooltip: "O'chirish",
            ),
          ],
        ),
      ),
    );
  }
}

// ── Subject sheet (add / edit) ─────────────────────────────────────────────────

class _SubjectSheet extends StatefulWidget {
  final SubjectModel? initial;
  final void Function(String name, int hours, SubjectDifficulty? difficulty) onSave;

  const _SubjectSheet({this.initial, required this.onSave});

  @override
  State<_SubjectSheet> createState() => _SubjectSheetState();
}

class _SubjectSheetState extends State<_SubjectSheet> {
  late final TextEditingController _nameCtrl;
  final _nameFocus = FocusNode();
  late int _hours;
  SubjectDifficulty? _manualDiff;

  bool get _isEdit => widget.initial != null;
  bool get _canSave => _nameCtrl.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    _nameCtrl = TextEditingController(text: init?.name ?? '');
    _hours = init?.hoursPerWeek ?? 2;
    _manualDiff = init?.manualDifficulty;
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _nameFocus.requestFocus());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  SubjectDifficulty get _effectiveDiff {
    if (_manualDiff != null) return _manualDiff!;
    final known = lookupKnownSubjectDifficulty(_nameCtrl.text.trim());
    if (known != null) return known;
    if (_hours >= 6) return SubjectDifficulty.veryHard;
    if (_hours >= 4) return SubjectDifficulty.hard;
    if (_hours >= 3) return SubjectDifficulty.medium;
    if (_hours >= 2) return SubjectDifficulty.easy;
    return SubjectDifficulty.veryEasy;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                // Handle
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
                // Title row
                Row(
                  children: [
                    if (_isEdit && widget.initial != null)
                      Container(
                        width: 4,
                        height: 22,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: Color(widget.initial!.colorValue),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    Text(
                      _isEdit ? 'Fanni tahrirlash' : "Fan qo'shish",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Name field
                Text('Fan nomi',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurface)),
                const SizedBox(height: 6),
                TextField(
                  controller: _nameCtrl,
                  focusNode: _nameFocus,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.inter(fontSize: 15, color: AppColors.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Masalan: Matematika',
                    hintStyle: GoogleFonts.inter(
                        fontSize: 15, color: AppColors.onSurfaceVariant),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: AppColors.outlineVariant),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: AppColors.outlineVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Hours
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Haftada necha soat?',
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.onSurface)),
                          const SizedBox(height: 2),
                          Text('6+ soat → ★★★★★ Juda qiyin',
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    _HoursCounter(
                      hours: _hours,
                      onDecrement: () {
                        if (_hours > 1) setState(() => _hours--);
                      },
                      onIncrement: () {
                        if (_hours < 14) setState(() => _hours++);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Difficulty stars
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Qiyinlik darajasi',
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.onSurface)),
                          const SizedBox(height: 2),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: Text(
                              _manualDiff != null
                                  ? _diffLabel(_manualDiff!)
                                  : lookupKnownSubjectDifficulty(
                                              _nameCtrl.text.trim()) !=
                                          null
                                      ? 'Avto (nom asosida)'
                                      : 'Avto (soat asosida)',
                              key: ValueKey(_manualDiff),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: _manualDiff == null
                                    ? AppColors.primary
                                    : AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: List.generate(5, (i) {
                        final starDiff = SubjectDifficulty.values[i];
                        final filled = _effectiveDiff.index >= i;
                        final isAuto = _manualDiff == null;
                        return GestureDetector(
                          onTap: () => setState(() {
                            _manualDiff = _manualDiff == starDiff ? null : starDiff;
                          }),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Icon(
                              filled
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 32,
                              color: isAuto
                                  ? Colors.amber.withValues(alpha: 0.45)
                                  : filled
                                      ? Colors.amber
                                      : AppColors.outlineVariant,
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: _canSave
                          ? const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
                            )
                          : null,
                      color: _canSave ? null : AppColors.outlineVariant,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: _canSave
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _canSave
                            ? () {
                                widget.onSave(
                                  _nameCtrl.text.trim(),
                                  _hours,
                                  _manualDiff,
                                );
                                Navigator.pop(context);
                              }
                            : null,
                        borderRadius: BorderRadius.circular(12),
                        child: Center(
                          child: Text(
                            _isEdit ? 'Saqlash' : "Qo'shish",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
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

// ── Hours counter ──────────────────────────────────────────────────────────────

class _HoursCounter extends StatelessWidget {
  final int hours;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _HoursCounter({
    required this.hours,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _HourBtn(icon: Icons.remove_rounded, onTap: onDecrement),
          SizedBox(
            width: 44,
            child: Center(
              child: Text(
                '$hours',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
            ),
          ),
          _HourBtn(icon: Icons.add_rounded, onTap: onIncrement),
        ],
      ),
    );
  }
}

class _HourBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HourBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 40,
          height: 44,
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
      ),
    );
  }
}

// ── Save bar ───────────────────────────────────────────────────────────────────

class _SaveBar extends StatelessWidget {
  final VoidCallback onSave;
  final bool saving;

  const _SaveBar({required this.onSave, required this.saving});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.surface.withValues(alpha: 0),
            AppColors.surface,
            AppColors.surface,
          ],
          stops: const [0, 0.28, 1],
        ),
      ),
      padding: EdgeInsets.fromLTRB(
          16, 24, 16, MediaQuery.of(context).padding.bottom + 16),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: saving
                ? null
                : const LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
                  ),
            color: saving ? AppColors.outlineVariant : null,
            borderRadius: BorderRadius.circular(14),
            boxShadow: saving
                ? null
                : [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.32),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: saving ? null : onSave,
              child: Center(
                child: saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_rounded,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Saqlash',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
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
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.onSurfaceVariant,
      ),
    );
  }
}
