import 'package:uuid/uuid.dart';

class ScheduleLesson {
  final String subjectId;
  final String subjectName;
  final int colorValue;
  final int lessonNumber;
  final String startTime; // "08:00"
  final String endTime;   // "08:45"

  const ScheduleLesson({
    required this.subjectId,
    required this.subjectName,
    required this.colorValue,
    required this.lessonNumber,
    required this.startTime,
    required this.endTime,
  });

  Map<String, dynamic> toMap() => {
        'subjectId': subjectId,
        'subjectName': subjectName,
        'colorValue': colorValue,
        'lessonNumber': lessonNumber,
        'startTime': startTime,
        'endTime': endTime,
      };

  factory ScheduleLesson.fromMap(Map<String, dynamic> map) => ScheduleLesson(
        subjectId: map['subjectId'] as String,
        subjectName: map['subjectName'] as String,
        colorValue: map['colorValue'] as int,
        lessonNumber: map['lessonNumber'] as int,
        startTime: map['startTime'] as String,
        endTime: map['endTime'] as String,
      );
}

class ScheduleBreak {
  final String time;    // "08:45"
  final int duration;  // minutes
  final bool isLarge;

  const ScheduleBreak({
    required this.time,
    required this.duration,
    required this.isLarge,
  });

  Map<String, dynamic> toMap() => {
        'time': time,
        'duration': duration,
        'isLarge': isLarge,
      };

  factory ScheduleBreak.fromMap(Map<String, dynamic> map) => ScheduleBreak(
        time: map['time'] as String,
        duration: map['duration'] as int,
        isLarge: map['isLarge'] as bool,
      );
}

class ScheduleDay {
  final String day;                    // "Du", "Se", "Ch", "Pa", "Ju", "Sh"
  final List<ScheduleLesson> lessons;
  final List<ScheduleBreak> breaks;   // breaks[i] = break after lessons[i]

  const ScheduleDay({
    required this.day,
    required this.lessons,
    this.breaks = const [],
  });

  int get lessonCount => lessons.length;

  Map<String, dynamic> toMap() => {
        'day': day,
        'lessons': lessons.map((l) => l.toMap()).toList(),
        'breaks': breaks.map((b) => b.toMap()).toList(),
      };

  factory ScheduleDay.fromMap(Map<String, dynamic> map) => ScheduleDay(
        day: map['day'] as String,
        lessons: (map['lessons'] as List)
            .map((l) => ScheduleLesson.fromMap(
                Map<String, dynamic>.from(l as Map)))
            .toList(),
        breaks: (map['breaks'] as List)
            .map((b) => ScheduleBreak.fromMap(
                Map<String, dynamic>.from(b as Map)))
            .toList(),
      );
}

class ScheduleModel {
  final String id;
  final String groupId;
  final DateTime generatedAt;
  final List<ScheduleDay> days;

  ScheduleModel({
    String? id,
    required this.groupId,
    required this.generatedAt,
    required this.days,
  }) : id = id ?? const Uuid().v4();

  int get totalLessons => days.fold(0, (s, d) => s + d.lessonCount);

  Map<String, dynamic> toMap() => {
        'id': id,
        'groupId': groupId,
        'generatedAt': generatedAt.millisecondsSinceEpoch,
        'days': days.map((d) => d.toMap()).toList(),
      };

  factory ScheduleModel.fromMap(Map<String, dynamic> map) => ScheduleModel(
        id: map['id'] as String,
        groupId: map['groupId'] as String,
        generatedAt: DateTime.fromMillisecondsSinceEpoch(
            map['generatedAt'] as int),
        days: (map['days'] as List)
            .map((d) => ScheduleDay.fromMap(
                Map<String, dynamic>.from(d as Map)))
            .toList(),
      );
}
