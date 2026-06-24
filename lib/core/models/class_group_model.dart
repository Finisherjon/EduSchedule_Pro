import 'package:uuid/uuid.dart';
import 'subject_model.dart';

// ─── Break configs ────────────────────────────────────────────────────────────

class LargeBreakConfig {
  int afterLesson; // X-darsdan keyin bo'ladi
  int duration;   // necha daqiqa

  LargeBreakConfig({this.afterLesson = 3, this.duration = 20});

  Map<String, dynamic> toMap() => {
        'afterLesson': afterLesson,
        'duration': duration,
      };

  factory LargeBreakConfig.fromMap(Map<String, dynamic> map) => LargeBreakConfig(
        afterLesson: map['afterLesson'] as int,
        duration: map['duration'] as int,
      );

  LargeBreakConfig copyWith({int? afterLesson, int? duration}) =>
      LargeBreakConfig(
        afterLesson: afterLesson ?? this.afterLesson,
        duration: duration ?? this.duration,
      );

  @override
  String toString() => 'LargeBreak(after: $afterLesson, ${duration}min)';
}

// ─── ClassGroupModel ──────────────────────────────────────────────────────────

class ClassGroupModel {
  final String id;
  String name;
  String language;
  List<String> workDays;
  int maxLessonsPerDay;
  int lessonDuration;
  List<LargeBreakConfig> largeBreaks;
  int smallBreakDuration;
  List<SubjectModel> subjects;

  ClassGroupModel({
    String? id,
    required this.name,
    required this.language,
    required this.workDays,
    required this.maxLessonsPerDay,
    required this.lessonDuration,
    required this.largeBreaks,
    required this.smallBreakDuration,
    required this.subjects,
  }) : id = id ?? const Uuid().v4();

  // ─── Serialization ─────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'language': language,
        'workDays': workDays,
        'maxLessonsPerDay': maxLessonsPerDay,
        'lessonDuration': lessonDuration,
        'largeBreaks': largeBreaks.map((b) => b.toMap()).toList(),
        'smallBreakDuration': smallBreakDuration,
        'subjects': subjects.map((s) => s.toMap()).toList(),
      };

  factory ClassGroupModel.fromMap(Map<String, dynamic> map) => ClassGroupModel(
        id: map['id'] as String,
        name: map['name'] as String,
        language: map['language'] as String,
        workDays: List<String>.from(map['workDays'] as List),
        maxLessonsPerDay: map['maxLessonsPerDay'] as int,
        lessonDuration: map['lessonDuration'] as int,
        largeBreaks: (map['largeBreaks'] as List)
            .map((b) => LargeBreakConfig.fromMap(
                Map<String, dynamic>.from(b as Map)))
            .toList(),
        smallBreakDuration: map['smallBreakDuration'] as int,
        subjects: (map['subjects'] as List)
            .map((s) =>
                SubjectModel.fromMap(Map<String, dynamic>.from(s as Map)))
            .toList(),
      );

  // ─── Utility ───────────────────────────────────────────────────────────────

  ClassGroupModel copyWith({
    String? name,
    String? language,
    List<String>? workDays,
    int? maxLessonsPerDay,
    int? lessonDuration,
    List<LargeBreakConfig>? largeBreaks,
    int? smallBreakDuration,
    List<SubjectModel>? subjects,
  }) =>
      ClassGroupModel(
        id: id,
        name: name ?? this.name,
        language: language ?? this.language,
        workDays: workDays ?? this.workDays,
        maxLessonsPerDay: maxLessonsPerDay ?? this.maxLessonsPerDay,
        lessonDuration: lessonDuration ?? this.lessonDuration,
        largeBreaks: largeBreaks ?? this.largeBreaks,
        smallBreakDuration: smallBreakDuration ?? this.smallBreakDuration,
        subjects: subjects ?? this.subjects,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClassGroupModel && id == other.id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ClassGroupModel(id: $id, name: $name, subjects: ${subjects.length})';
}
