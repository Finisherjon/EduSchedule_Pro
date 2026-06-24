import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/class_group_model.dart';
import 'subjects_input_page.dart';

class ClassSetupPage extends StatefulWidget {
  const ClassSetupPage({super.key});

  @override
  State<ClassSetupPage> createState() => _ClassSetupPageState();
}

class _ClassSetupPageState extends State<ClassSetupPage> {
  final List<_ClassData> _dataList = [_ClassData()];
  final List<String> _classNames = ['Sinf 1'];
  int _selectedClass = 0;

  _ClassData get _cur => _dataList[_selectedClass];

  static const _langs = ["O'zbek", 'Rus', 'English'];
  static const _days = ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'];

  void _addNewClass() {
    setState(() {
      _classNames.add('Sinf ${_classNames.length + 1}');
      _dataList.add(_ClassData());
      _selectedClass = _classNames.length - 1;
    });
  }

  void _switchClass(int index) {
    if (index == _selectedClass) return;
    setState(() => _selectedClass = index);
  }

  Future<void> _deleteClass(int index) async {
    if (_dataList.length <= 1) return;

    final name = _dataList[index].nameController.text.trim().isEmpty
        ? _classNames[index]
        : _dataList[index].nameController.text.trim();

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
          "'$name' sinfini ro'yxatdan olib tashlaysizmi?",
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

    if (confirmed != true) return;

    setState(() {
      _dataList[index].dispose();
      _dataList.removeAt(index);
      _classNames.removeAt(index);
      if (_selectedClass >= _dataList.length) {
        _selectedClass = _dataList.length - 1;
      }
    });
  }

  List<ClassGroupModel> _buildClassGroups() {
    return List.generate(_dataList.length, (i) {
      final data = _dataList[i];
      final name = data.nameController.text.trim().isEmpty
          ? _classNames[i]
          : data.nameController.text.trim();
      return ClassGroupModel(
        name: name,
        language: _langs[data.selectedLang],
        workDays: data.selectedDays.toList(),
        maxLessonsPerDay: data.maxLessons.round(),
        lessonDuration: data.lessonDuration,
        largeBreaks: data.largeBreaks
            .map((b) => LargeBreakConfig(
                  afterLesson: b.afterLesson,
                  duration: b.duration,
                ))
            .toList(),
        smallBreakDuration: data.smallBreakDuration,
        subjects: [],
      );
    });
  }

  @override
  void dispose() {
    for (final d in _dataList) {
      d.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          _GradientHeader(onBack: () => Navigator.pop(context)),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PageTitle(),
                  const SizedBox(height: 16),
                  _ClassTabsBar(
                    classes: _classNames,
                    selectedIndex: _selectedClass,
                    onSelect: _switchClass,
                    onAdd: _addNewClass,
                    onDelete: _deleteClass,
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    accentColor: AppColors.primary.withValues(alpha: 0.8),
                    child: _BasicInfoSection(
                      key: ValueKey(_selectedClass),
                      nameController: _cur.nameController,
                      selectedLang: _cur.selectedLang,
                      langs: _langs,
                      onLangChanged: (i) =>
                          setState(() => _cur.selectedLang = i),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    accentColor: AppColors.secondary,
                    child: _ScheduleSection(
                      key: ValueKey(_selectedClass),
                      days: _days,
                      selectedDays: _cur.selectedDays,
                      maxLessons: _cur.maxLessons,
                      lessonDuration: _cur.lessonDuration,
                      onDayToggle: (day) => setState(() {
                        if (day == 'Ya') return;
                        if (_cur.selectedDays.contains(day)) {
                          _cur.selectedDays.remove(day);
                        } else {
                          _cur.selectedDays.add(day);
                        }
                      }),
                      onMaxLessonsChanged: (v) =>
                          setState(() => _cur.maxLessons = v),
                      onDurationChanged: (v) =>
                          setState(() => _cur.lessonDuration = v),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    accentColor: AppColors.tertiary,
                    child: _BreaksSection(
                      key: ValueKey(_selectedClass),
                      largeBreaks: _cur.largeBreaks,
                      smallBreakDuration: _cur.smallBreakDuration,
                      onAddLargeBreak: () => setState(() {
                        if (_cur.largeBreaks.length < 2) {
                          _cur.largeBreaks.add(LargeBreakConfig());
                        }
                      }),
                      onRemoveLargeBreak: (i) =>
                          setState(() => _cur.largeBreaks.removeAt(i)),
                      onLargeAfterLessonChanged: (i, v) =>
                          setState(() => _cur.largeBreaks[i].afterLesson = v),
                      onLargeDurationChanged: (i, v) =>
                          setState(() => _cur.largeBreaks[i].duration = v),
                      onSmallDurationChanged: (v) =>
                          setState(() => _cur.smallBreakDuration = v),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomBar(
        onNext: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SubjectsInputPage(
              classGroups: _buildClassGroups(),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Per-class data model ───────────────────────────────────────────────────────

class _ClassData {
  final TextEditingController nameController = TextEditingController();
  int selectedLang = 0;
  Set<String> selectedDays = {'Du', 'Se', 'Ch', 'Pa', 'Ju'};
  double maxLessons = 6;
  int lessonDuration = 45;
  List<LargeBreakConfig> largeBreaks = [LargeBreakConfig()];
  int smallBreakDuration = 5;

  void dispose() => nameController.dispose();
}

// ── Gradient header ────────────────────────────────────────────────────────────

class _GradientHeader extends StatelessWidget {
  final VoidCallback onBack;

  const _GradientHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 16, 20),
          child: Column(
            children: [
              Row(
                children: [
                  _BackButton(onBack: onBack),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Sozlamalar',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onBack;

  const _BackButton({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onBack,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}

// ── Page title ─────────────────────────────────────────────────────────────────

class _PageTitle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sinflar / Guruhlar yaratish',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Guruhning asosiy ma'lumotlari va dars jadvali qoidalarini kiriting.",
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

// ── Class tabs bar ─────────────────────────────────────────────────────────────

class _ClassTabsBar extends StatelessWidget {
  final List<String> classes;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;
  final void Function(int index)? onDelete;

  const _ClassTabsBar({
    required this.classes,
    required this.selectedIndex,
    required this.onSelect,
    required this.onAdd,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'SAVATDAGI SINFLAR',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            Text(
              'Jami: ${classes.length} ta sinf',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...List.generate(classes.length, (i) {
                final selected = i == selectedIndex;
                final canDelete = classes.length > 1 && onDelete != null;
                return GestureDetector(
                  onTap: () => onSelect(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding: EdgeInsets.only(
                      left: 16,
                      right: canDelete ? 6 : 16,
                      top: 8,
                      bottom: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : AppColors.outlineVariant,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          classes[i],
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? Colors.white
                                : AppColors.onSurfaceVariant,
                          ),
                        ),
                        if (canDelete) ...[
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => onDelete!(i),
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: selected
                                    ? Colors.white.withValues(alpha: 0.25)
                                    : AppColors.surfaceContainerHigh,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                size: 11,
                                color: selected
                                    ? Colors.white
                                    : AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
              GestureDetector(
                onTap: onAdd,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.outlineVariant,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    size: 18,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Section card wrapper ───────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final Color accentColor;
  final Widget child;

  const _SectionCard({required this.accentColor, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: accentColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Basic info section ─────────────────────────────────────────────────────────

class _BasicInfoSection extends StatelessWidget {
  final TextEditingController nameController;
  final int selectedLang;
  final List<String> langs;
  final ValueChanged<int> onLangChanged;

  const _BasicInfoSection({
    super.key,
    required this.nameController,
    required this.selectedLang,
    required this.langs,
    required this.onLangChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.info_outline_rounded,
          label: "Tanlangan sinf ma'lumotlari",
          iconColor: AppColors.primary,
        ),
        const SizedBox(height: 14),
        _FieldLabel("Sinf / Guruh nomi"),
        const SizedBox(height: 6),
        TextField(
          controller: nameController,
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurface),
          decoration: InputDecoration(
            hintText: "Masalan: 10-A sinf",
            hintStyle: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.onSurfaceVariant,
            ),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _FieldLabel("O'qitish tili"),
        const SizedBox(height: 8),
        _LanguageSegment(
          langs: langs,
          selected: selectedLang,
          onChanged: onLangChanged,
        ),
      ],
    );
  }
}


class _LanguageSegment extends StatelessWidget {
  final List<String> langs;
  final int selected;
  final ValueChanged<int> onChanged;

  const _LanguageSegment({
    required this.langs,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: List.generate(langs.length, (i) {
          final isSelected = i == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    langs[i],
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant,
                    ),
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

// ── Schedule section ───────────────────────────────────────────────────────────

class _ScheduleSection extends StatelessWidget {
  final List<String> days;
  final Set<String> selectedDays;
  final double maxLessons;
  final int lessonDuration;
  final ValueChanged<String> onDayToggle;
  final ValueChanged<double> onMaxLessonsChanged;
  final ValueChanged<int> onDurationChanged;

  const _ScheduleSection({
    super.key,
    required this.days,
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
        _SectionTitle(
          icon: Icons.calendar_today_rounded,
          label: 'Sinf jadvali qoidalari',
          iconColor: AppColors.secondary,
        ),
        const SizedBox(height: 14),
        _FieldLabel("O'qish kunlari"),
        const SizedBox(height: 10),
        _DayChips(
          days: days,
          selectedDays: selectedDays,
          onToggle: onDayToggle,
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _FieldLabel('Kundalik maksimal darslar'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${maxLessons.round()} ta',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.surfaceContainerHigh,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withValues(alpha: 0.12),
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
          ),
          child: Slider(
            value: maxLessons,
            min: 4,
            max: 8,
            divisions: 4,
            onChanged: onMaxLessonsChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['4', '5', '6', '7', '8']
                .map(
                  (t) => Text(
                    t,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 18),
        _FieldLabel('Bir dars davomiyligi'),
        const SizedBox(height: 10),
        _DurationRadio(
          selected: lessonDuration,
          onChanged: onDurationChanged,
        ),
      ],
    );
  }
}

class _DayChips extends StatelessWidget {
  final List<String> days;
  final Set<String> selectedDays;
  final ValueChanged<String> onToggle;

  const _DayChips({
    required this.days,
    required this.selectedDays,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: days.map((day) {
        final selected = selectedDays.contains(day);
        final disabled = day == 'Ya';
        return GestureDetector(
          onTap: disabled ? null : () => onToggle(day),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: disabled ? 0.45 : 1,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected && !disabled ? AppColors.primary : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected && !disabled
                      ? AppColors.primary
                      : AppColors.outlineVariant,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  day,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected && !disabled
                        ? Colors.white
                        : AppColors.onSurface,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DurationRadio extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  static const _options = [45, 60, 90];

  const _DurationRadio({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _options.asMap().entries.map((entry) {
        final v = entry.value;
        final i = entry.key;
        final isSelected = v == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(v),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 48,
              margin: EdgeInsets.only(right: i < _options.length - 1 ? 8 : 0),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.outlineVariant,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Center(
                child: Text(
                  '$v daq.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.onSurface,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
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
    super.key,
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
        _SectionTitle(
          icon: Icons.timer_outlined,
          label: 'Tanaffuslar',
          iconColor: AppColors.tertiary,
        ),
        const SizedBox(height: 14),
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
                    const Icon(
                      Icons.add_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
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
        ...List.generate(largeBreaks.length, (i) => Padding(
          padding: EdgeInsets.only(bottom: i < largeBreaks.length - 1 ? 10 : 0),
          child: _LargeBreakCard(
            index: i,
            config: largeBreaks[i],
            canRemove: largeBreaks.length > 1,
            onRemove: () => onRemoveLargeBreak(i),
            onAfterLessonChanged: (v) => onLargeAfterLessonChanged(i, v),
            onDurationChanged: (v) => onLargeDurationChanged(i, v),
          ),
        )),
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

  static const _durations = [
    5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60,
  ];

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
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
            ),
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
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Darslar orasidagi tanaffus davomiyligi',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
            ),
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
  final int step;
  final String suffix;
  final ValueChanged<int> onChanged;

  const _BreakStepper({
    required this.value,
    required this.min,
    required this.max,
    this.step = 1,
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
          _StepButton(
            icon: Icons.remove_rounded,
            onTap: value > min ? () => onChanged(value - step) : null,
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
          _StepButton(
            icon: Icons.add_rounded,
            onTap: value < max ? () => onChanged(value + step) : null,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 28,
        height: 28,
        margin: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: enabled ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled ? AppColors.primary.withValues(alpha: 0.35) : AppColors.outlineVariant,
          ),
        ),
        child: Icon(
          icon,
          size: 15,
          color: enabled ? AppColors.primary : AppColors.outlineVariant,
        ),
      ),
    );
  }
}

// ── Minutes wheel picker ───────────────────────────────────────────────────────

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
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
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

// ── Shared helpers ─────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;

  const _SectionTitle({
    required this.icon,
    required this.label,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
      ],
    );
  }
}

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
        color: AppColors.onSurface,
      ),
    );
  }
}

// ── Bottom bar ─────────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final VoidCallback onNext;

  const _BottomBar({required this.onNext});

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
          stops: const [0, 0.35, 1],
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        24,
        16,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
            ),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onNext,
              borderRadius: BorderRadius.circular(999),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Keyingisi',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
