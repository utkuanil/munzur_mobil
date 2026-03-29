import 'dart:convert';

import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import 'meal_day.dart';

class MealService {
  static const String url =
      'https://munzur.edu.tr/birimler/idari/sks/Pages/yemeklistesi.aspx';

  Future<List<MealDay>> fetchMeals() async {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      throw Exception('Yemek listesi sayfası alınamadı.');
    }

    // Türkçe karakter bozulmaması için bodyBytes -> utf8 / latin1 fallback
    String content;
    try {
      content = utf8.decode(response.bodyBytes);
    } catch (_) {
      content = latin1.decode(response.bodyBytes);
    }

    final document = html_parser.parse(content);

    // Sayfadaki tüm metni al
    final text = document.body?.text ?? '';

    // Metin bazlı ayrıştırma:
    // Beklenen örnek yapı:
    // 02.03.2026
    // Yemek: Tarhana Çorbası
    // 1. Yemek: Tarhana Çorbası
    // 2. Yemek: ...
    // 3. Yemek: ...
    // 4. Yemek: ...

    final lines = text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final List<MealDay> result = [];

    final dateRegex = RegExp(r'^\d{2}\.\d{2}\.\d{4}$');
    final mealRegex = RegExp(r'^[1-4]\.\s*Yemek\s*:\s*(.+)$', caseSensitive: false);

    String? currentDate;
    List<String> currentMeals = [];

    void pushCurrent() {
      if (currentDate != null && currentMeals.isNotEmpty) {
        result.add(
          MealDay(
            date: currentDate!,
            meals: List<String>.from(currentMeals),
          ),
        );
      }
      currentDate = null;
      currentMeals = [];
    }

    for (final line in lines) {
      if (dateRegex.hasMatch(line)) {
        pushCurrent();
        currentDate = line;
        continue;
      }

      final match = mealRegex.firstMatch(line);
      if (match != null) {
        currentMeals.add(match.group(1)?.trim() ?? '');
      }
    }

    pushCurrent();

    // Eğer metin tabanlı parse başarısız olursa,
    // sayfadaki tablo yapısını denemek için yedek parse eklenebilir.
    if (result.isEmpty) {
      final tables = document.querySelectorAll('table');
      for (final table in tables) {
        final rows = table.querySelectorAll('tr');
        for (final row in rows) {
          final cols = row.querySelectorAll('td, th')
              .map((e) => e.text.trim())
              .where((e) => e.isNotEmpty)
              .toList();

          if (cols.length >= 5 && dateRegex.hasMatch(cols.first)) {
            result.add(
              MealDay(
                date: cols.first,
                meals: cols.sublist(1, cols.length > 5 ? 5 : cols.length),
              ),
            );
          }
        }
      }
    }

    return result;
  }
}