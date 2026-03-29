class AcademicCalendarEvent {
  final String id;
  final String title;
  final String category;
  final String? term;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool allDay;
  final String? note;

  const AcademicCalendarEvent({
    required this.id,
    required this.title,
    required this.category,
    this.term,
    required this.startDate,
    required this.endDate,
    required this.allDay,
    this.note,
  });

  factory AcademicCalendarEvent.fromJson(Map<String, dynamic> json) {
    DateTime? parseNullableDate(dynamic value) {
      final raw = (value ?? '').toString().trim();
      if (raw.isEmpty) return null;

      try {
        return DateTime.parse(raw);
      } catch (_) {
        return null;
      }
    }

    return AcademicCalendarEvent(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      term: json['term']?.toString(),
      startDate: parseNullableDate(json['startDate']),
      endDate: parseNullableDate(json['endDate']),
      allDay: json['allDay'] == true,
      note: json['note']?.toString(),
    );
  }

  bool get hasDateRange => startDate != null && endDate != null;
}