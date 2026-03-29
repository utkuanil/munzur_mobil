import 'academic_calendar_event.dart';

class AcademicCalendarData {
  final String year;
  final String scope;
  final String academicCalendarUrl;
  final List<AcademicCalendarEvent> events;
  final List<AcademicCalendarEvent> holidays;
  final List<AcademicCalendarEvent> notes;

  const AcademicCalendarData({
    required this.year,
    required this.scope,
    required this.academicCalendarUrl,
    required this.events,
    required this.holidays,
    required this.notes,
  });

  factory AcademicCalendarData.fromJson(Map<String, dynamic> json) {
    List<AcademicCalendarEvent> parseList(String key) {
      final raw = json[key];
      if (raw is! List) return [];

      return raw
          .map((e) => AcademicCalendarEvent.fromJson(
        Map<String, dynamic>.from(e as Map),
      ))
          .toList();
    }

    return AcademicCalendarData(
      year: (json['year'] ?? '').toString(),
      scope: (json['scope'] ?? '').toString(),
      academicCalendarUrl: (json['academicCalendarUrl'] ?? '').toString(),
      events: parseList('events'),
      holidays: parseList('holidays'),
      notes: parseList('notes'),
    );
  }

  List<AcademicCalendarEvent> get datedItems => [
    ...events.where((e) => e.hasDateRange),
    ...holidays.where((e) => e.hasDateRange),
    ...notes.where((e) => e.hasDateRange),
  ];
}