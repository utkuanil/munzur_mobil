import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models/academic_calendar_data.dart';
import 'models/academic_calendar_event.dart';

class AcademicCalendarService {
  static const String academicCalendarJsonUrl =
      'https://raw.githubusercontent.com/utkuanil/munzur_mobil_data/main/data/academic_calendar.json';

  Future<AcademicCalendarData> fetchCalendar() async {
    final response = await http.get(Uri.parse(academicCalendarJsonUrl));

    if (response.statusCode != 200) {
      throw Exception('Akademik takvim JSON dosyası alınamadı.');
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Akademik takvim JSON formatı geçersiz.');
    }

    return AcademicCalendarData.fromJson(decoded);
  }

  Future<String?> fetchCalendarUrl() async {
    final calendar = await fetchCalendar();
    final url = calendar.academicCalendarUrl.trim();
    return url.isEmpty ? null : url;
  }

  Future<List<AcademicCalendarEvent>> fetchAllDatedItems() async {
    final calendar = await fetchCalendar();
    return calendar.datedItems;
  }
}