import 'package:uuid/uuid.dart';

enum SubjectDifficulty { veryEasy, easy, medium, hard, veryHard }

/// Fan nomi bo'yicha oldindan belgilangan qiyinlik darajasini qaytaradi.
/// Noma'lum fanlar uchun null qaytaradi.
SubjectDifficulty? lookupKnownSubjectDifficulty(String name) =>
    _kKnownSubjects[name.toLowerCase().trim()];

// Fan nomi → qiyinlik darajasi (kichik harflar bilan saqlanadi)
const _kKnownSubjects = <String, SubjectDifficulty>{
  // ★★★★★
  'algebra': SubjectDifficulty.veryHard,
  'fizika': SubjectDifficulty.veryHard,
  'geometriya': SubjectDifficulty.veryHard,
  'matematika': SubjectDifficulty.veryHard,
  // ★★★★
  'kimyo': SubjectDifficulty.hard,
  'informatika': SubjectDifficulty.hard,
  'chet tili': SubjectDifficulty.hard,
  // ★★★
  'davlat va huquq asoslari': SubjectDifficulty.medium,
  'biologiya': SubjectDifficulty.medium,
  'geografiya': SubjectDifficulty.medium,
  "o'zbekiston tarixi": SubjectDifficulty.medium,
  'jahon tarixi': SubjectDifficulty.medium,
  'ona tili': SubjectDifficulty.medium,
  'adabiyot': SubjectDifficulty.medium,
  'rus tili': SubjectDifficulty.medium,
  'chizmachilik': SubjectDifficulty.medium,
  'iqtisodiyot asoslari': SubjectDifficulty.medium,
  'tabiiy fanlar': SubjectDifficulty.medium,
  // ★★
  'chqbt': SubjectDifficulty.easy,
  'texnologiya': SubjectDifficulty.easy,
  "o'qish savodxonligi": SubjectDifficulty.easy,
  // ★
  'tarbiya': SubjectDifficulty.veryEasy,
  'musiqa madaniyati': SubjectDifficulty.veryEasy,
  "tasviriy san'at": SubjectDifficulty.veryEasy,
  'jismoniy tarbiya': SubjectDifficulty.veryEasy,
};

class SubjectModel {
  final String id;
  String name;
  int hoursPerWeek;
  SubjectDifficulty? manualDifficulty;
  int colorValue;

  SubjectModel({
    String? id,
    required this.name,
    required this.hoursPerWeek,
    this.manualDifficulty,
    required this.colorValue,
  }) : id = id ?? const Uuid().v4();

  SubjectDifficulty get difficulty {
    if (manualDifficulty != null) return manualDifficulty!;
    final known = _kKnownSubjects[name.toLowerCase().trim()];
    if (known != null) return known;
    if (hoursPerWeek >= 6) return SubjectDifficulty.veryHard;
    if (hoursPerWeek >= 4) return SubjectDifficulty.hard;
    if (hoursPerWeek >= 3) return SubjectDifficulty.medium;
    if (hoursPerWeek >= 2) return SubjectDifficulty.easy;
    return SubjectDifficulty.veryEasy;
  }

  // ─── Serialization ───────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'hoursPerWeek': hoursPerWeek,
        'manualDifficulty': manualDifficulty?.index,
        'colorValue': colorValue,
      };

  factory SubjectModel.fromMap(Map<String, dynamic> map) => SubjectModel(
        id: map['id'] as String,
        name: map['name'] as String,
        hoursPerWeek: map['hoursPerWeek'] as int,
        manualDifficulty: map['manualDifficulty'] != null
            ? SubjectDifficulty.values[map['manualDifficulty'] as int]
            : null,
        colorValue: map['colorValue'] as int,
      );

  // ─── Utility ─────────────────────────────────────────────────────────────────

  SubjectModel copyWith({
    String? name,
    int? hoursPerWeek,
    SubjectDifficulty? manualDifficulty,
    bool clearManualDifficulty = false,
    int? colorValue,
  }) =>
      SubjectModel(
        id: id,
        name: name ?? this.name,
        hoursPerWeek: hoursPerWeek ?? this.hoursPerWeek,
        manualDifficulty: clearManualDifficulty
            ? null
            : (manualDifficulty ?? this.manualDifficulty),
        colorValue: colorValue ?? this.colorValue,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is SubjectModel && id == other.id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'SubjectModel(id: $id, name: $name, hours: $hoursPerWeek, difficulty: $difficulty)';
}
