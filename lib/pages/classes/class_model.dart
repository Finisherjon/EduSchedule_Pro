import 'package:flutter/material.dart';

class ClassSubject {
  String name;
  int hoursPerWeek;
  final Color color;

  ClassSubject({
    required this.name,
    required this.hoursPerWeek,
    required this.color,
  });

  String get priority {
    if (hoursPerWeek >= 4) return 'Yuqori';
    if (hoursPerWeek >= 2) return "O'rta";
    return 'Past';
  }

  Color get priorityColor {
    if (hoursPerWeek >= 4) return const Color(0xFF388E3C);
    if (hoursPerWeek >= 2) return const Color(0xFFF57C00);
    return const Color(0xFF757575);
  }
}

class ClassEntry {
  final String name;
  final String year;
  final String category;
  final Color color;
  final List<ClassSubject> subjects;
  bool expanded;

  ClassEntry({
    required this.name,
    required this.year,
    required this.category,
    required this.color,
    required this.subjects,
    this.expanded = false,
  });
}
