import 'dart:convert';
import 'package:http/http.dart' as http;

class AcademicMenuHelper {
  static const String url =
      'https://raw.githubusercontent.com/utkuanil/munzur_mobil_data/main/data/menus/academic_menu.json';

  static Future<String?> findDepartmentUrl({
    required String academicUnit,
    required String department,
  }) async {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) return null;

    final data = jsonDecode(utf8.decode(response.bodyBytes));

    for (final section in data) {
      final items = section['items'] as List?;

      if (items == null) continue;

      for (final item in items) {
        // Fakülte eşleşmesi
        if ((item['title'] ?? '').toString().toLowerCase() ==
            academicUnit.toLowerCase()) {
          final children = item['children'] as List?;

          if (children == null) continue;

          for (final child in children) {
            if ((child['title'] ?? '').toString().toLowerCase() ==
                department.toLowerCase()) {
              return child['url'];
            }
          }
        }
      }
    }

    return null;
  }
}