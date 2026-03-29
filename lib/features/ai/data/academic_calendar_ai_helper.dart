import '../../profile/data/models/academic_calendar_event.dart';

enum AcademicCalendarEventType {
  registration,
  course,
  examMidterm,
  examFinal,
  examMakeup,
  graduation,
  holiday,
  administrative,
  other,
}

class AcademicCalendarAiHelper {
  static AcademicCalendarEvent? findOngoingEvent(
      List<AcademicCalendarEvent> events,
      ) {
    final now = _todayOnly(DateTime.now());

    for (final event in events) {
      if (!event.hasDateRange) continue;

      final start = _todayOnly(event.startDate!);
      final end = _todayOnly(event.endDate!);

      final isOngoing =
          (now.isAtSameMomentAs(start) || now.isAfter(start)) &&
              (now.isAtSameMomentAs(end) || now.isBefore(end));

      if (isOngoing) {
        return event;
      }
    }

    return null;
  }

  static AcademicCalendarEvent? findUpcomingEvent(
      List<AcademicCalendarEvent> events, {
        int withinDays = 10,
        Set<AcademicCalendarEventType>? preferredTypes,
      }) {
    final now = _todayOnly(DateTime.now());

    AcademicCalendarEvent? nearest;
    int? nearestDiff;

    for (final event in events) {
      if (event.startDate == null) continue;

      final eventType = classifyEvent(event);

      if (preferredTypes != null &&
          preferredTypes.isNotEmpty &&
          !preferredTypes.contains(eventType)) {
        continue;
      }

      final start = _todayOnly(event.startDate!);

      if (start.isAfter(now)) {
        final diff = start.difference(now).inDays;
        if (diff <= withinDays) {
          if (nearestDiff == null || diff < nearestDiff) {
            nearestDiff = diff;
            nearest = event;
          }
        }
      }
    }

    return nearest;
  }

  static int daysUntil(DateTime date) {
    final now = _todayOnly(DateTime.now());
    final target = _todayOnly(date);
    return target.difference(now).inDays;
  }

  static AcademicCalendarEventType classifyEvent(
      AcademicCalendarEvent event,
      ) {
    final title = event.title.toLowerCase().trim();
    final category = event.category.toLowerCase().trim();
    final note = (event.note ?? '').toLowerCase().trim();
    final text = '$title $category $note';

    if (_containsAny(text, [
      'kayıt',
      'kayıt yenileme',
      'ders kayıt',
      'ekle-sil',
      'ekle sil',
      'harç',
    ])) {
      return AcademicCalendarEventType.registration;
    }

    if (_containsAny(text, [
      'vize',
      'ara sınav',
      'arasınav',
      'midterm',
    ])) {
      return AcademicCalendarEventType.examMidterm;
    }

    if (_containsAny(text, [
      'final',
      'yarıyıl sonu sınav',
      'dönem sonu sınav',
    ])) {
      return AcademicCalendarEventType.examFinal;
    }

    if (_containsAny(text, [
      'bütünleme',
      'tek ders',
      'makeup',
    ])) {
      return AcademicCalendarEventType.examMakeup;
    }

    if (_containsAny(text, [
      'mezuniyet',
      'graduation',
    ])) {
      return AcademicCalendarEventType.graduation;
    }

    if (_containsAny(text, [
      'tatil',
      'bayram',
      'resmi tatil',
      'holiday',
    ])) {
      return AcademicCalendarEventType.holiday;
    }

    if (_containsAny(text, [
      'ders başlama',
      'derslerin başlaması',
      'ders başlangıç',
      'eğitim öğretim',
      'akademik yıl',
      'dönem başlangıç',
      'dönem başlangıcı',
      'dönem sonu',
    ])) {
      return AcademicCalendarEventType.course;
    }

    if (_containsAny(text, [
      'senato',
      'yönetim kurulu',
      'idari',
      'başvuru',
      'komisyon',
      'görevlendirme',
    ])) {
      return AcademicCalendarEventType.administrative;
    }

    return AcademicCalendarEventType.other;
  }

  static Set<AcademicCalendarEventType> preferredTypesForUser(
      Map<String, dynamic> userData,
      ) {
    final role = (userData['role'] ?? 'student').toString().toLowerCase();
    final staffType = (userData['staffType'] ?? '').toString().trim();

    if (role == 'staff' && staffType == 'Akademik') {
      return {
        AcademicCalendarEventType.course,
        AcademicCalendarEventType.examMidterm,
        AcademicCalendarEventType.examFinal,
        AcademicCalendarEventType.examMakeup,
        AcademicCalendarEventType.administrative,
        AcademicCalendarEventType.registration,
      };
    }

    if (role == 'staff' && staffType == 'İdari') {
      return {
        AcademicCalendarEventType.administrative,
        AcademicCalendarEventType.registration,
        AcademicCalendarEventType.holiday,
      };
    }

    return {
      AcademicCalendarEventType.registration,
      AcademicCalendarEventType.course,
      AcademicCalendarEventType.examMidterm,
      AcademicCalendarEventType.examFinal,
      AcademicCalendarEventType.examMakeup,
      AcademicCalendarEventType.graduation,
      AcademicCalendarEventType.holiday,
    };
  }

  static bool _containsAny(String text, List<String> keywords) {
    for (final keyword in keywords) {
      if (text.contains(keyword)) return true;
    }
    return false;
  }

  static DateTime _todayOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}