class CustomHoliday {
  final DateTime startDate;
  final DateTime endDate;
  final String name;

  const CustomHoliday({
    required this.startDate,
    required this.endDate,
    required this.name,
  });

  bool covers(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final s = DateTime(startDate.year, startDate.month, startDate.day);
    final e = DateTime(endDate.year, endDate.month, endDate.day);
    return !d.isBefore(s) && !d.isAfter(e);
  }

  Map<String, dynamic> toMap() => {
        'start': startDate.millisecondsSinceEpoch,
        'end': endDate.millisecondsSinceEpoch,
        'name': name,
      };

  factory CustomHoliday.fromMap(Map<String, dynamic> map) => CustomHoliday(
        startDate:
            DateTime.fromMillisecondsSinceEpoch(map['start'] as int),
        endDate:
            DateTime.fromMillisecondsSinceEpoch(map['end'] as int),
        name: map['name'] as String,
      );
}
