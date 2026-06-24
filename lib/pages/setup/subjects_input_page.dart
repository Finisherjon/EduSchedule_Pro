import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/subject_model.dart';
import '../../core/models/class_group_model.dart';
import '../../core/providers/class_group_provider.dart';
import '../../core/providers/schedule_provider.dart';
import '../loading/loading_page.dart';

// Fan kartalarida ishlatiladigan ranglar palitasi
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

class Subject {
  String name;
  int hoursPerWeek;
  SubjectDifficulty? manualDifficulty;

  Subject({required this.name, required this.hoursPerWeek, this.manualDifficulty});

  SubjectDifficulty get difficulty {
    if (manualDifficulty != null) return manualDifficulty!;
    final known = lookupKnownSubjectDifficulty(name);
    if (known != null) return known;
    if (hoursPerWeek >= 6) return SubjectDifficulty.veryHard;
    if (hoursPerWeek >= 4) return SubjectDifficulty.hard;
    if (hoursPerWeek >= 3) return SubjectDifficulty.medium;
    if (hoursPerWeek >= 2) return SubjectDifficulty.easy;
    return SubjectDifficulty.veryEasy;
  }
}

// ── Page ───────────────────────────────────────────────────────────────────────

class SubjectsInputPage extends StatefulWidget {
  final List<ClassGroupModel> classGroups;

  const SubjectsInputPage({super.key, required this.classGroups});

  @override
  State<SubjectsInputPage> createState() => _SubjectsInputPageState();
}

class _SubjectsInputPageState extends State<SubjectsInputPage> {
  late final List<List<Subject>> _subjectsByClass;
  int _selectedClass = 0;
  bool _saving = false;

  List<Subject> get _cur => _subjectsByClass[_selectedClass];

  @override
  void initState() {
    super.initState();
    _subjectsByClass = List.generate(
      widget.classGroups.length,
      (_) => [],
    );
  }

  int get _totalSubjects =>
      _subjectsByClass.fold(0, (sum, list) => sum + list.length);

  void _addSubject() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddSubjectSheet(
        onSave: (name, hours, difficulty) {
          setState(() {
            _cur.add(Subject(
              name: name,
              hoursPerWeek: hours,
              manualDifficulty: difficulty,
            ));
          });
        },
      ),
    );
  }

  void _editSubject(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddSubjectSheet(
        initial: _cur[index],
        onSave: (name, hours, difficulty) {
          setState(() {
            _cur[index] = Subject(
              name: name,
              hoursPerWeek: hours,
              manualDifficulty: difficulty,
            );
          });
        },
      ),
    );
  }

  void _deleteSubject(int index) {
    setState(() => _cur.removeAt(index));
  }

  Future<void> _saveAndGenerate() async {
    if (_saving) return;
    setState(() => _saving = true);

    final classProvider = context.read<ClassGroupProvider>();
    final scheduleProvider = context.read<ScheduleProvider>();

    for (int i = 0; i < widget.classGroups.length; i++) {
      final subjectModels = _subjectsByClass[i]
          .asMap()
          .entries
          .map((e) => SubjectModel(
                name: e.value.name,
                hoursPerWeek: e.value.hoursPerWeek,
                manualDifficulty: e.value.manualDifficulty,
                colorValue:
                    _kSubjectColors[e.key % _kSubjectColors.length].toARGB32(),
              ))
          .toList();

      final group =
          widget.classGroups[i].copyWith(subjects: subjectModels);
      await classProvider.save(group);
      await scheduleProvider.generateFor(group);
    }

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoadingPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          _Header(onBack: () => Navigator.pop(context)),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ClassTabsBar(
                    classNames:
                        widget.classGroups.map((g) => g.name).toList(),
                    selectedIndex: _selectedClass,
                    totalSubjects: _totalSubjects,
                    currentCount: _cur.length,
                    onSelect: (i) => setState(() => _selectedClass = i),
                  ),
                  const SizedBox(height: 16),
                  _InfoBanner(),
                  const SizedBox(height: 20),
                  _SectionHeader(count: _cur.length, onAdd: _addSubject),
                  const SizedBox(height: 12),
                  if (_cur.isEmpty)
                    _EmptyState(onAdd: _addSubject)
                  else
                    ...List.generate(
                      _cur.length,
                      (i) => _SubjectCard(
                        subject: _cur[i],
                        colorIndex: i,
                        onEdit: () => _editSubject(i),
                        onDelete: () => _deleteSubject(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomBar(
        enabled: _totalSubjects > 0 && !_saving,
        onGenerate: _saveAndGenerate,
      ),
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final VoidCallback onBack;

  const _Header({required this.onBack});

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
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _CircleBtn(
                    icon: Icons.arrow_back_rounded,
                    onTap: onBack,
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Fanlarni kiriting',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: -0.2,
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
          color: Colors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

// ── Class tabs bar ─────────────────────────────────────────────────────────────

class _ClassTabsBar extends StatelessWidget {
  final List<String> classNames;
  final int selectedIndex;
  final int totalSubjects;
  final int currentCount;
  final ValueChanged<int> onSelect;

  const _ClassTabsBar({
    required this.classNames,
    required this.selectedIndex,
    required this.totalSubjects,
    required this.currentCount,
    required this.onSelect,
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
              'SINFNI TANLANG',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            Text(
              'Jami: $totalSubjects ta fan',
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
              ...List.generate(classNames.length, (i) {
                final selected = i == selectedIndex;
                return GestureDetector(
                  onTap: () => onSelect(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          selected ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : AppColors.outlineVariant,
                      ),
                    ),
                    child: Text(
                      classNames[i],
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? Colors.white
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Info banner ────────────────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceDim.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Matematika, Fizika kabi taniqli fanlar avtomatik qiyinlik oladi. "
              "Boshqa fanlar uchun soat soniga qarab yoki yulduzcha bilan o'zingiz belgilang.",
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section header ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final int count;
  final VoidCallback onAdd;

  const _SectionHeader({required this.count, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Tanlangan fanlar',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.add_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  "Fan qo'shish",
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
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

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onAdd,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.library_add_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Fan qo'shing",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Bu sinf uchun hali fan qo'shilmagan",
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Subject card ───────────────────────────────────────────────────────────────

class _SubjectCard extends StatelessWidget {
  final Subject subject;
  final int colorIndex;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SubjectCard({
    required this.subject,
    required this.colorIndex,
    required this.onEdit,
    required this.onDelete,
  });

  Color get _dotColor => _kSubjectColors[colorIndex % _kSubjectColors.length];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onEdit,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surfaceVariant),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1565C0).withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: _dotColor,
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Text(
                subject.name,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            _HoursBadge(hours: subject.hoursPerWeek),
            const SizedBox(width: 6),
            _DifficultyChip(
              difficulty: subject.difficulty,
              isAuto: subject.manualDifficulty == null,
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onEdit,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: AppColors.primary.withValues(alpha: 0.7),
                ),
              ),
            ),
            GestureDetector(
              onTap: onDelete,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: AppColors.error.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HoursBadge extends StatelessWidget {
  final int hours;

  const _HoursBadge({required this.hours});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.schedule_rounded,
            size: 12,
            color: AppColors.onSurfaceVariant,
          ),
          const SizedBox(width: 3),
          Text(
            '${hours}h',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _DifficultyChip extends StatelessWidget {
  final SubjectDifficulty difficulty;
  final bool isAuto;

  const _DifficultyChip({required this.difficulty, required this.isAuto});

  int get _stars => difficulty.index + 1;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isAuto)
            const Padding(
              padding: EdgeInsets.only(right: 3),
              child: Icon(Icons.auto_mode_rounded, size: 10, color: AppColors.primary),
            ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              5,
              (i) => Icon(
                i < _stars ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 11,
                color: i < _stars ? Colors.amber : AppColors.outlineVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom bar ─────────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final bool enabled;
  final VoidCallback onGenerate;

  const _BottomBar({required this.enabled, required this.onGenerate});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        border: Border(top: BorderSide(color: AppColors.surfaceVariant)),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: enabled
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
                      )
                    : null,
                color: enabled ? null : AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(12),
                boxShadow: enabled
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
                  onTap: enabled ? onGenerate : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Jadval yaratish',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ],
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

// ── Add / Edit subject sheet ───────────────────────────────────────────────────

class _AddSubjectSheet extends StatefulWidget {
  final void Function(String name, int hours, SubjectDifficulty? difficulty) onSave;
  final Subject? initial; // non-null → edit mode

  const _AddSubjectSheet({required this.onSave, this.initial});

  @override
  State<_AddSubjectSheet> createState() => _AddSubjectSheetState();
}

class _AddSubjectSheetState extends State<_AddSubjectSheet> {
  late final TextEditingController _nameController;
  final _nameFocus = FocusNode();
  late int _hours;
  SubjectDifficulty? _manualDifficulty;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    _nameController = TextEditingController(text: init?.name ?? '');
    _hours = init?.hoursPerWeek ?? 2;
    _manualDifficulty = init?.manualDifficulty;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nameFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  bool get _canAdd => _nameController.text.trim().isNotEmpty;

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
                  _isEdit ? 'Fanni tahrirlash' : "Fan qo'shish",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 20),

                // Name field
                Text(
                  'Fan nomi',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _nameController,
                  focusNode: _nameFocus,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: AppColors.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Masalan: Matematika',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 15,
                      color: AppColors.onSurfaceVariant,
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: AppColors.outlineVariant),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: AppColors.outlineVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Hours stepper
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Haftada necha soat?',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '6+ soat → ★★★★★ Juda qiyin',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
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

                // Difficulty selector
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Qiyinlik darajasi',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: Text(
                              _manualDifficulty != null
                                  ? switch (_manualDifficulty!) {
                                      SubjectDifficulty.veryEasy => 'Juda yengil',
                                      SubjectDifficulty.easy => 'Yengil',
                                      SubjectDifficulty.medium => "O'rta",
                                      SubjectDifficulty.hard => 'Qiyin',
                                      SubjectDifficulty.veryHard => 'Juda qiyin',
                                    }
                                  : lookupKnownSubjectDifficulty(
                                          _nameController.text.trim()) !=
                                      null
                                      ? 'Avto (nom asosida)'
                                      : 'Avto (soat asosida)',
                              key: ValueKey(_manualDifficulty),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: _manualDifficulty == null
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
                        final effective = _manualDifficulty ??
                            lookupKnownSubjectDifficulty(
                                _nameController.text.trim()) ??
                            (_hours >= 6
                                ? SubjectDifficulty.veryHard
                                : _hours >= 4
                                    ? SubjectDifficulty.hard
                                    : _hours >= 3
                                        ? SubjectDifficulty.medium
                                        : _hours >= 2
                                            ? SubjectDifficulty.easy
                                            : SubjectDifficulty.veryEasy);
                        final filled = effective.index >= i;
                        final isAuto = _manualDifficulty == null;
                        return GestureDetector(
                          onTap: () => setState(() {
                            _manualDifficulty =
                                _manualDifficulty == starDiff ? null : starDiff;
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

                // Add button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: _canAdd
                          ? const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
                            )
                          : null,
                      color: _canAdd ? null : AppColors.outlineVariant,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: _canAdd
                          ? [
                              BoxShadow(
                                color: AppColors.primary
                                    .withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _canAdd
                            ? () {
                                widget.onSave(
                                  _nameController.text.trim(),
                                  _hours,
                                  _manualDifficulty,
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
          _StepBtn(icon: Icons.remove_rounded, onTap: onDecrement),
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
          _StepBtn(icon: Icons.add_rounded, onTap: onIncrement),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepBtn({required this.icon, required this.onTap});

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
