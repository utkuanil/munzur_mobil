import 'dart:convert';

import 'package:charset/charset.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'package:html/dom.dart' as dom;
import 'models/site_post.dart';

class MunzurSiteService {
  static const String _base = 'https://www.munzur.edu.tr';

  Future<List<SitePost>> fetchAnnouncements() async {
    final response = await http.get(Uri.parse('$_base/duyurular.aspx'));

    if (response.statusCode != 200) {
      throw Exception('Duyurular sayfası alınamadı');
    }

    final body = _decodeHtmlBody(
      response.bodyBytes,
      contentTypeHeader: response.headers['content-type'],
    );
    final document = html_parser.parse(body);

    final anchors = document.querySelectorAll('a[href*="duyurudetay.aspx"]');
    final links = <String>[];

    for (final a in anchors) {
      final href = a.attributes['href'] ?? '';
      final fullLink = _normalizeUrl(href);
      if (fullLink.isEmpty) continue;
      links.add(fullLink);
    }

    final text = document.body?.text ?? '';
    final parsedItems = _parseAnnouncementsFromText(text);

    final results = <SitePost>[];
    final seen = <String>{};

    final count =
    parsedItems.length < links.length ? parsedItems.length : links.length;

    for (int i = 0; i < count; i++) {
      final item = parsedItems[i];
      final link = links[i];

      final key = '${item['date']}|${item['title']}|$link';
      if (seen.contains(key)) continue;
      seen.add(key);

      results.add(
        SitePost(
          title: _clean(item['title'] ?? ''),
          summary: '',
          link: link,
          date: _clean(item['date'] ?? ''),
          imageUrl: '',
        ),
      );
    }

    return results;
  }

  List<Map<String, String>> _parseAnnouncementsFromText(String rawText) {
    final lines = rawText
        .split('\n')
        .map(_clean)
        .where((e) => e.isNotEmpty)
        .toList();

    final results = <Map<String, String>>[];
    final seenTitles = <String>{};

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (!_looksLikeAnnouncementDate(line)) continue;

      String title = '';
      int detailIndex = -1;

      for (int j = i + 1; j < lines.length && j <= i + 6; j++) {
        final current = lines[j];
        final lower = current.toLowerCase();

        if (_isAnnouncementNoise(current)) continue;

        if (lower.startsWith('detay')) {
          detailIndex = j;
          break;
        }

        if (title.isEmpty && !_looksLikeAnnouncementDate(current)) {
          title = current;
        }
      }

      if (title.isEmpty && detailIndex > i + 1) {
        final maybeTitle = lines[detailIndex - 1];
        if (!_isAnnouncementNoise(maybeTitle) &&
            !_looksLikeAnnouncementDate(maybeTitle)) {
          title = maybeTitle;
        }
      }

      if (title.isEmpty) continue;
      if (_isAnnouncementNoise(title)) continue;

      final normalizedTitle = title.toLowerCase();
      if (seenTitles.contains(normalizedTitle)) continue;
      seenTitles.add(normalizedTitle);

      results.add({
        'date': line,
        'title': title,
      });
    }

    return results;
  }

  bool _looksLikeTurkishDate(String text) {
    final t = text.trim();

    return RegExp(
      r'^\d{1,2}\s+(Ocak|Şubat|Mart|Nisan|Mayıs|Haziran|Temmuz|Ağustos|Eylül|Ekim|Kasım|Aralık)\s+\d{4}$',
    ).hasMatch(t);
  }

  String _extractImageFromStyle(String style) {
    final match = RegExp(r"url\(([^)]+)\)").firstMatch(style);
    if (match == null) return '';

    var url = match.group(1) ?? '';

    url = url.replaceAll('"', '').replaceAll("'", '');

    return _normalizeUrl(url);
  }

  bool _isAnnouncementNoise(String text) {
    final t = text.trim();
    final lower = t.toLowerCase();
    final upper = t.toUpperCase();

    if (t.isEmpty) return true;
    if (lower.startsWith('detay')) return true;
    if (upper == 'DUYURULAR') return true;
    if (upper == 'MUNZUR ÜNİVERSİTESİ') return true;
    if (upper == 'ANASAYFA') return true;
    if (t.length < 5) return true;

    return false;
  }

  bool _looksLikeAnnouncementDate(String text) {
    final t = text.trim();

    return RegExp(
      r'^\d{1,2}\s+(Ocak|Şubat|Mart|Nisan|Mayıs|Haziran|Temmuz|Ağustos|Eylül|Ekim|Kasım|Aralık)\s+\d{4}$',
    ).hasMatch(t) ||
        RegExp(r'^\d{1,2}[./-]\d{1,2}[./-]\d{2,4}$').hasMatch(t);
  }

  Future<List<SitePost>> fetchNews() async {
    final response = await http.get(Uri.parse('$_base/haberler.aspx'));
    if (response.statusCode != 200) {
      throw Exception('Haberler sayfası alınamadı: ${response.statusCode}');
    }

    final body = _decodeHtmlBody(
      response.bodyBytes,
      contentTypeHeader: response.headers['content-type'],
    );
    final document = html_parser.parse(body);

    final cards = document.querySelectorAll('#anadiv');
    final posts = <SitePost>[];
    final seen = <String>{};

    for (final card in cards.take(30)) {
      final linkEl = card.querySelector('a[href*="haberdetay.aspx"]');
      if (linkEl == null) continue;

      final href = linkEl.attributes['href'] ?? '';
      final fullLink = _normalizeUrl(href);
      if (fullLink.isEmpty || seen.contains(fullLink)) continue;
      seen.add(fullLink);

      final titleEl = card.querySelector('h5');
      final imgEl = card.querySelector('img.img-thumbnail');

      final title = _clean(titleEl?.text ?? '');
      final imageUrl = _normalizeUrl(imgEl?.attributes['src'] ?? '');
      final date = _extractDate(card);

      posts.add(
        SitePost(
          title: title.isEmpty ? 'Haber' : title,
          summary: '',
          link: fullLink,
          date: _clean(date),
          imageUrl: imageUrl,
        ),
      );
    }

    return posts;
  }

  Future<List<SitePost>> fetchEvents() async {
    final response = await http.get(Uri.parse('$_base/etkinlikler.aspx'));
    if (response.statusCode != 200) {
      throw Exception('Etkinlikler sayfası alınamadı: ${response.statusCode}');
    }

    final body = _decodeHtmlBody(
      response.bodyBytes,
      contentTypeHeader: response.headers['content-type'],
    );

    final document = html_parser.parse(body);
    final contentRoot =
        document.querySelector('div[style*="margin-left: 30px"]') ?? document.body;

    if (contentRoot == null) return [];

    final nodes = contentRoot.nodes;
    final results = <SitePost>[];
    final seen = <String>{};

    String currentDate = '';

    for (final node in nodes) {
      if (node.nodeType == dom.Node.TEXT_NODE) {
        final text = _clean(node.text ?? '');
        if (_looksLikeTurkishDate(text)) {
          currentDate = text;
        }
        continue;
      }

      if (node is! dom.Element) continue;

      if (node.localName == 'h5') {
        final title = _clean(node.text);
        if (title.isEmpty) continue;

        dom.Element? sibling = node.nextElementSibling;
        while (sibling != null &&
            sibling.localName != 'a' &&
            sibling.localName != 'hr' &&
            sibling.localName != 'h5') {
          sibling = sibling.nextElementSibling;
        }

        if (sibling == null || sibling.localName != 'a') continue;

        final href = sibling.attributes['href'] ?? '';
        final fullLink = _normalizeUrl(href);

        if (fullLink.isEmpty || seen.contains(fullLink)) continue;
        seen.add(fullLink);

        results.add(
          SitePost(
            title: title,
            summary: '',
            link: fullLink,
            date: currentDate,
            imageUrl: '',
          ),
        );
      }
    }

    return results;
  }

  Future<SitePost> fetchEventDetail(
      String url, {
        String fallbackTitle = '',
        String fallbackDate = '',
      }) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Etkinlik detayı alınamadı: ${response.statusCode}');
    }

    final body = _decodeHtmlBody(
      response.bodyBytes,
      contentTypeHeader: response.headers['content-type'],
    );

    final document = html_parser.parse(body);

    String title = fallbackTitle;
    String date = fallbackDate;
    String summary = '';
    String imageUrl = '';

    // Ana içerik bloğu
    final contentBox = document.querySelector('div.row.golge');

    // Başlık
    final titleEl = document.querySelector('#ContentPlaceHolder1_Label4');
    if (titleEl != null && _clean(titleEl.text).isNotEmpty) {
      title = _clean(titleEl.text);
    }

    // Görsel
    final imgEl = contentBox?.querySelector('img.img-responsive');
    if (imgEl != null) {
      imageUrl = _normalizeUrl(imgEl.attributes['src'] ?? '');
    }

    // Tarih sayfada görünmüyorsa listeden gelen fallback kalsın
    final bodyText = _clean(document.body?.text ?? '');
    final dateMatch = RegExp(
      r'\b\d{1,2}\s+(Ocak|Şubat|Mart|Nisan|Mayıs|Haziran|Temmuz|Ağustos|Eylül|Ekim|Kasım|Aralık)\s+\d{4}\b',
    ).firstMatch(bodyText);

    if (dateMatch != null) {
      date = _clean(dateMatch.group(0) ?? fallbackDate);
    }

    // Özet/içerik:
    // Bu sayfada çoğu etkinlikte başlık + görsel dışında uzun bir açıklama olmayabiliyor.
    // O yüzden sadece içerik bloğundan metin alalım; menü/footer karışmasın.
    if (contentBox != null) {
      // Başlık metnini içerikten çıkar
      var text = _clean(contentBox.text);
      if (title.isNotEmpty) {
        text = text.replaceFirst(title, '').trim();
      }
      summary = _clean(text);
    }

    // Çok kısa veya anlamsızsa boş bırak
    if (summary == title || summary.length < 10) {
      summary = '';
    }

    return SitePost(
      title: _clean(title),
      summary: summary,
      link: url,
      date: _clean(date),
      imageUrl: imageUrl,
    );
  }

  Future<List<SitePost>> _fetchListPage({
    required String url,
    required String detailPathKeyword,
    required String fallbackTitle,
  }) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Sayfa alınamadı: ${response.statusCode}');
    }

    final body = _decodeHtmlBody(
      response.bodyBytes,
      contentTypeHeader: response.headers['content-type'],
    );
    final document = html_parser.parse(body);

    final anchors = document
        .querySelectorAll('a[href*="$detailPathKeyword"]')
        .take(20)
        .toList();

    final seen = <String>{};
    final posts = <SitePost>[];

    for (final a in anchors) {
      final href = a.attributes['href'] ?? '';
      final fullLink = _normalizeUrl(href);

      if (fullLink.isEmpty || seen.contains(fullLink)) continue;
      seen.add(fullLink);

      final container = _findNearestCardContainer(a);

      String title = _clean(a.text);
      if (title.isEmpty) {
        title = _extractCardTitle(container, detailPathKeyword);
      }

      String date = _extractDate(container);
      String summary = _extractCardSummary(container, exclude: title);
      String imageUrl = _extractImage(container);

      final lowerTitle = title.toLowerCase().trim();
      if (title.isEmpty ||
          lowerTitle == 'detay' ||
          lowerTitle == 'detay.' ||
          lowerTitle == 'detay .' ||
          lowerTitle == 'haber') {
        title = fallbackTitle;
      }

      title = _clean(title);
      summary = _clean(summary);
      date = _clean(date);

      if (summary == title) {
        summary = '';
      }

      posts.add(
        SitePost(
          title: title,
          summary: summary,
          link: fullLink,
          date: date,
          imageUrl: imageUrl,
        ),
      );
    }

    return posts;
  }

  Future<List<Map<String, String>>> fetchMeals() async {
    final response = await http.get(
      Uri.parse('$_base/birimler/idari/sks/Pages/yemeklistesi.aspx'),
    );

    if (response.statusCode != 200) {
      throw Exception('Yemek listesi sayfası alınamadı');
    }

    final body = _decodeHtmlBody(
      response.bodyBytes,
      contentTypeHeader: response.headers['content-type'],
    );
    final document = html_parser.parse(body);

    final mealList = <Map<String, String>>[];

    final allText = _clean(document.body?.text ?? '');
    final parsedFromText = _parseMealsFromWholeText(allText);
    if (parsedFromText.isNotEmpty) {
      return _sortMealsByDateAsc(parsedFromText);
    }

    final rows = document.querySelectorAll('tr');
    for (final row in rows) {
      final rowText = _clean(row.text);
      final parsed = _parseSingleMealBlock(rowText);
      if (parsed != null) {
        mealList.add(parsed);
      }
    }



    final blocks = document.querySelectorAll('div, td, p, li');
    for (final block in blocks) {
      final text = _clean(block.text);
      final parsed = _parseSingleMealBlock(text);
      if (parsed != null) {
        mealList.add(parsed);
      }
    }

    return _sortMealsByDateAsc(_deduplicateMeals(mealList));
  }

  Future<SitePost> fetchDetail(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Detay sayfası alınamadı');
    }

    final body = _decodeHtmlBody(
      response.bodyBytes,
      contentTypeHeader: response.headers['content-type'],
    );
    final document = html_parser.parse(body);

    final title = _extractDetailTitle(document);
    final date = _extractDate(document.body);
    final imageUrl = _extractDetailImage(document);
    final content = _extractFullContent(document.body);
    final summary =
    content.isNotEmpty ? content : _extractFirstLongParagraph(document.body);

    return SitePost(
      title: _clean(title),
      summary: _clean(summary),
      link: url,
      date: _clean(date),
      imageUrl: imageUrl,
    );
  }



  List<Map<String, String>> _parseMealsFromWholeText(String text) {
    final normalized = text
        .replaceAll('Tarih:', '\nTarih:')
        .replaceAll('Kalori:', '\nKalori:')
        .replaceAll('1.Yemek', '\n1.Yemek')
        .replaceAll('2.Yemek', '\n2.Yemek')
        .replaceAll('3.Yemek', '\n3.Yemek')
        .replaceAll('4.Yemek', '\n4.Yemek')
        .replaceAllMapped(
      RegExp(r'(\d{2}\.\d{2}\.\d{4})'),
          (m) => '\n${m.group(1)}',
    );

    final dateRegex = RegExp(r'\b\d{2}\.\d{2}\.\d{4}\b');
    final lines = normalized
        .split('\n')
        .map(_clean)
        .where((e) => e.isNotEmpty)
        .toList();

    final results = <Map<String, String>>[];
    String? currentDate;
    String meal1 = '';
    String meal2 = '';
    String meal3 = '';
    String meal4 = '';
    String calorie = '';

    void pushCurrent() {
      if (currentDate != null &&
          (meal1.isNotEmpty ||
              meal2.isNotEmpty ||
              meal3.isNotEmpty ||
              meal4.isNotEmpty)) {
        results.add({
          'date': _clean(currentDate!),
          'calorie': _normalizeCalorie(calorie),
          'meal1': _cleanMealText(meal1),
          'meal2': _cleanMealText(meal2),
          'meal3': _cleanMealText(meal3),
          'meal4': _cleanMealText(meal4),
        });
      }

      meal1 = '';
      meal2 = '';
      meal3 = '';
      meal4 = '';
      calorie = '';
    }

    for (final line in lines) {
      final dateMatch = dateRegex.firstMatch(line);

      if (line.startsWith('Tarih:')) {
        final extracted = _clean(line.replaceFirst('Tarih:', ''));
        if (currentDate != null) {
          pushCurrent();
        }
        currentDate = extracted;
        continue;
      }

      if (dateMatch != null &&
          !line.startsWith('1.Yemek:') &&
          !line.startsWith('2.Yemek:') &&
          !line.startsWith('3.Yemek:') &&
          !line.startsWith('4.Yemek:')) {
        if (currentDate != null) {
          pushCurrent();
        }
        currentDate = dateMatch.group(0);
        continue;
      }

      if (line.startsWith('Kalori:')) {
        calorie = _clean(line.replaceFirst('Kalori:', ''));
      } else if (line.startsWith('1.Yemek:')) {
        meal1 = _clean(line.replaceFirst('1.Yemek:', ''));
      } else if (line.startsWith('2.Yemek:')) {
        meal2 = _clean(line.replaceFirst('2.Yemek:', ''));
      } else if (line.startsWith('3.Yemek:')) {
        meal3 = _clean(line.replaceFirst('3.Yemek:', ''));
      } else if (line.startsWith('4.Yemek:')) {
        meal4 = _clean(line.replaceFirst('4.Yemek:', ''));
      }
    }

    pushCurrent();
    return _deduplicateMeals(results);
  }

  Map<String, String>? _parseSingleMealBlock(String text) {
    if (text.isEmpty) return null;

    final dateRegex = RegExp(r'\b\d{2}\.\d{2}\.\d{4}\b');
    final hasDate = dateRegex.hasMatch(text);
    final hasMeal = text.contains('1.Yemek:') ||
        text.contains('2.Yemek:') ||
        text.contains('3.Yemek:') ||
        text.contains('4.Yemek:');

    if (!hasDate || !hasMeal) return null;

    String date = '';
    if (text.contains('Tarih:')) {
      date = _extractField(text, 'Tarih:', ['Kalori:', '1.Yemek:']);
    } else {
      final match = dateRegex.firstMatch(text);
      date = match?.group(0) ?? '';
    }

    final calorie = _extractField(
      text,
      'Kalori:',
      ['1.Yemek:', '2.Yemek:', '3.Yemek:', '4.Yemek:'],
    );

    final meal1 = _extractField(
      text,
      '1.Yemek:',
      ['Kalori:', '2.Yemek:', '3.Yemek:', '4.Yemek:'],
    );

    final meal2 = _extractField(
      text,
      '2.Yemek:',
      ['Kalori:', '3.Yemek:', '4.Yemek:'],
    );

    final meal3 = _extractField(
      text,
      '3.Yemek:',
      ['Kalori:', '4.Yemek:'],
    );

    final meal4 = _extractField(
      text,
      '4.Yemek:',
      ['Kalori:'],
    );

    if (date.isEmpty) return null;

    return {
      'date': _clean(date),
      'calorie': _normalizeCalorie(calorie),
      'meal1': _cleanMealText(meal1),
      'meal2': _cleanMealText(meal2),
      'meal3': _cleanMealText(meal3),
      'meal4': _cleanMealText(meal4),
    };
  }

  List<Map<String, String>> _deduplicateMeals(
      List<Map<String, String>> meals,
      ) {
    final seen = <String>{};
    final result = <Map<String, String>>[];

    for (final item in meals) {
      final key = [
        item['date'] ?? '',
        item['meal1'] ?? '',
        item['meal2'] ?? '',
        item['meal3'] ?? '',
        item['meal4'] ?? '',
      ].join('|');

      if (key.trim().replaceAll('|', '').isEmpty) continue;
      if (seen.contains(key)) continue;

      seen.add(key);
      result.add(item);
    }

    return result;
  }

  List<Map<String, String>> _sortMealsByDateAsc(
      List<Map<String, String>> meals,
      ) {
    final result = List<Map<String, String>>.from(meals);

    DateTime? parseDate(String value) {
      final parts = value.split('.');
      if (parts.length != 3) return null;

      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);

      if (day == null || month == null || year == null) return null;

      return DateTime(year, month, day);
    }

    result.sort((a, b) {
      final da = parseDate(a['date'] ?? '');
      final db = parseDate(b['date'] ?? '');

      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;

      return da.compareTo(db);
    });

    return result;
  }

  String _extractField(String text, String startLabel, List<String> endLabels) {
    final startIndex = text.indexOf(startLabel);
    if (startIndex == -1) return '';

    final contentStart = startIndex + startLabel.length;
    int endIndex = text.length;

    for (final label in endLabels) {
      final idx = text.indexOf(label, contentStart);
      if (idx != -1 && idx < endIndex) {
        endIndex = idx;
      }
    }

    return _clean(text.substring(contentStart, endIndex).trim());
  }

  String _normalizeUrl(String href) {
    if (href.isEmpty) return '';
    if (href.startsWith('http')) return href;
    if (href.startsWith('/')) return '$_base$href';
    return '$_base/$href';
  }

  Element _bestContentContainer(Element a) {
    Element current = a;

    for (int i = 0; i < 5; i++) {
      final parent = current.parent;
      if (parent == null) break;

      final text = _clean(parent.text);
      if (text.length > 40) {
        current = parent;
      } else {
        break;
      }
    }

    return current;
  }

  dom.Element _findNearestCardContainer(dom.Element anchor) {
    dom.Element current = anchor;

    for (int i = 0; i < 6; i++) {
      final parent = current.parent;
      if (parent == null) break;

      final text = _clean(parent.text);
      final linkCount = parent.querySelectorAll('a').length;
      final imageCount = parent.querySelectorAll('img').length;

      // Çok büyük genel sayfa bloklarını ele
      if (text.length > 40 && text.length < 1200) {
        // Birden fazla link içerse bile aşırı büyük değilse kart olabilir
        if (linkCount <= 8) {
          return parent;
        }

        // Görsel + makul metin varsa yine kabul et
        if (imageCount > 0 && linkCount <= 12) {
          return parent;
        }
      }

      current = parent;
    }

    return anchor.parent ?? anchor;
  }

  String _extractCardTitle(Element? container, String detailPathKeyword) {
    if (container == null) return '';

    final headingSelectors = ['h1', 'h2', 'h3', 'h4', 'strong', 'b', '.title'];

    for (final selector in headingSelectors) {
      final el = container.querySelector(selector);
      final txt = _clean(el?.text ?? '');
      if (_isGoodTitle(txt)) return txt;
    }

    final lines = container.text
        .split('\n')
        .map(_clean)
        .where((e) => e.isNotEmpty)
        .toList();

    for (final line in lines) {
      if (_isGoodTitle(line) &&
          !line.toLowerCase().startsWith('detay') &&
          !_looksLikeDate(line)) {
        return line;
      }
    }

    final links = container.querySelectorAll('a');
    for (final link in links) {
      final href = link.attributes['href'] ?? '';
      final txt = _clean(link.text);

      if (!href.contains(detailPathKeyword)) continue;
      if (_isGoodTitle(txt) && !txt.toLowerCase().startsWith('detay')) {
        return txt;
      }
    }

    return '';
  }

  String _extractCardSummary(Element? container, {required String exclude}) {
    if (container == null) return '';

    final texts = container.text
        .split('\n')
        .map(_clean)
        .where((e) => e.isNotEmpty)
        .where((e) => e != exclude)
        .where((e) => !e.toLowerCase().startsWith('detay'))
        .where((e) => !_looksLikeDate(e))
        .toList();

    if (texts.isEmpty) return '';

    final summary = texts.first;
    return summary.length > 180 ? '${summary.substring(0, 180)}...' : summary;
  }

  String _extractDate(Element? container) {
    if (container == null) return '';

    final text = _clean(container.text);

    final regexNumeric = RegExp(r'(\d{1,2}[./-]\d{1,2}[./-]\d{2,4})');
    final numericMatch = regexNumeric.firstMatch(text);
    if (numericMatch != null) {
      return _clean(numericMatch.group(1) ?? '');
    }

    final regexTurkishMonth = RegExp(
      r'(\d{1,2}\s+(Ocak|Şubat|Mart|Nisan|Mayıs|Haziran|Temmuz|Ağustos|Eylül|Ekim|Kasım|Aralık)\s+\d{4})',
    );
    final monthMatch = regexTurkishMonth.firstMatch(text);
    if (monthMatch != null) {
      return _clean(monthMatch.group(1) ?? '');
    }

    return '';
  }

  String _extractImage(Element? container) {
    if (container == null) return '';

    final images = container.querySelectorAll('img');

    for (final img in images) {
      final src = img.attributes['src'] ?? '';
      final normalized = _normalizeUrl(src);

      if (normalized.isEmpty) continue;
      if (_isPlaceholderImage(normalized)) continue;

      return normalized;
    }

    return '';
  }

  String _extractDetailImage(Document document) {
    String pickMetaImage(String selector, String attr) {
      final el = document.querySelector(selector);
      final value = el?.attributes[attr] ?? '';
      final normalized = _normalizeUrl(value);

      if (normalized.isEmpty) return '';
      if (_isPlaceholderImage(normalized)) return '';

      return normalized;
    }

    // 1) Önce meta görselleri kontrol et
    final metaCandidates = [
      pickMetaImage('meta[property="og:image"]', 'content'),
      pickMetaImage('meta[name="og:image"]', 'content'),
      pickMetaImage('meta[property="twitter:image"]', 'content'),
      pickMetaImage('meta[name="twitter:image"]', 'content'),
      pickMetaImage('link[rel="image_src"]', 'href'),
    ];

    for (final img in metaCandidates) {
      if (img.isNotEmpty) return img;
    }

    // 2) İçerik alanına yakın blokları tara
    final roots = <Element?>[
      document.querySelector('.haberDetay'),
      document.querySelector('.news-detail'),
      document.querySelector('.duyuruDetay'),
      document.querySelector('.icerik'),
      document.querySelector('.content'),
      document.querySelector('#content'),
      document.querySelector('article'),
      document.querySelector('main'),
      document.body,
    ];

    for (final root in roots) {
      if (root == null) continue;

      final images = root.querySelectorAll('img');

      for (final img in images) {
        final src = img.attributes['src'] ?? '';
        final normalized = _normalizeUrl(src);

        if (normalized.isEmpty) continue;
        if (_isPlaceholderImage(normalized)) continue;

        final alt = (img.attributes['alt'] ?? '').toLowerCase();
        final cls = (img.attributes['class'] ?? '').toLowerCase();
        final style = (img.attributes['style'] ?? '').toLowerCase();

        final width = int.tryParse(img.attributes['width'] ?? '') ?? 0;
        final height = int.tryParse(img.attributes['height'] ?? '') ?? 0;

        final metaText = '$alt $cls $style $normalized';

        if (metaText.contains('logo') ||
            metaText.contains('icon') ||
            metaText.contains('banner') ||
            metaText.contains('header') ||
            metaText.contains('footer') ||
            metaText.contains('facebook') ||
            metaText.contains('instagram') ||
            metaText.contains('twitter') ||
            metaText.contains('youtube') ||
            metaText.contains('share')) {
          continue;
        }

        if ((width > 0 && width < 180) || (height > 0 && height < 180)) {
          continue;
        }

        return normalized;
      }
    }

    // 3) Son çare: gövde içindeki tüm img'ler ama sıkı filtreyle
    final allImages = document.body?.querySelectorAll('img') ?? const [];
    for (final img in allImages) {
      final src = img.attributes['src'] ?? '';
      final normalized = _normalizeUrl(src);

      if (normalized.isEmpty) continue;
      if (_isPlaceholderImage(normalized)) continue;

      final alt = (img.attributes['alt'] ?? '').toLowerCase();
      final cls = (img.attributes['class'] ?? '').toLowerCase();
      final metaText = '$alt $cls $normalized';

      if (metaText.contains('logo') ||
          metaText.contains('icon') ||
          metaText.contains('banner') ||
          metaText.contains('header') ||
          metaText.contains('footer') ||
          metaText.contains('facebook') ||
          metaText.contains('instagram') ||
          metaText.contains('twitter') ||
          metaText.contains('youtube') ||
          metaText.contains('share')) {
        continue;
      }

      return normalized;
    }

    return '';
  }

  bool _isPlaceholderImage(String url) {
    final u = url.toLowerCase();

    const badKeywords = [
      'logo',
      'default',
      'placeholder',
      'icon',
      'icons',
      'blank',
      'noimage',
      'no-image',
      'dummy',
      'thumb',
      'thumbnail',
      'duyuru.png',
      'duyuru.jpg',
      'banner',
      'header',
      'footer',
      'social',
      'facebook',
      'instagram',
      'twitter',
      'youtube',
      'whatsapp',
      'share',
      'sprite',
      'loading',
      'spinner',
    ];

    for (final keyword in badKeywords) {
      if (u.contains(keyword)) return true;
    }

    return false;
  }

  String _extractDetailTitle(Document document) {
    final selectors = [
      'h1',
      'h2',
      'h3',
      '.title',
      '.newsTitle',
      '.duyuruBaslik',
      '.haberBaslik',
      'strong',
    ];

    for (final selector in selectors) {
      final el = document.querySelector(selector);
      final text = _clean(el?.text ?? '');
      if (_isGoodTitle(text)) return text;
    }

    final bodyText = document.body?.text ?? '';
    final lines = bodyText
        .split('\n')
        .map(_clean)
        .where((e) => e.isNotEmpty)
        .toList();

    for (final line in lines) {
      if (_isGoodTitle(line) && !_looksLikeDate(line)) {
        return line;
      }
    }

    return '';
  }

  String _extractFirstLongParagraph(Element? root) {
    if (root == null) return '';

    final paragraphs = root
        .querySelectorAll('p')
        .map((e) => _clean(e.text))
        .where((e) => e.length > 40)
        .toList();

    return paragraphs.isNotEmpty ? paragraphs.first : '';
  }

  String _extractFullContent(Element? root) {
    if (root == null) return '';

    final paragraphs = root
        .querySelectorAll('p')
        .map((e) => _clean(e.text))
        .where((e) => e.isNotEmpty)
        .toList();

    if (paragraphs.isNotEmpty) {
      return paragraphs.join('\n\n');
    }

    return _clean(root.text);
  }

  bool _isGoodTitle(String text) {
    final t = text.trim();
    if (t.isEmpty) return false;
    if (t.length < 6) return false;

    final lower = t.toLowerCase();
    if (lower == 'detay') return false;
    if (lower == 'detay...') return false;
    if (lower == 'detay ...') return false;
    if (lower == 'devamı') return false;

    return true;
  }

  bool _looksLikeDate(String text) {
    final t = text.trim();

    return RegExp(r'^\d{1,2}[./-]\d{1,2}[./-]\d{2,4}$').hasMatch(t) ||
        RegExp(
          r'^\d{1,2}\s+(Ocak|Şubat|Mart|Nisan|Mayıs|Haziran|Temmuz|Ağustos|Eylül|Ekim|Kasım|Aralık)\s+\d{4}$',
        ).hasMatch(t);
  }

  String _decodeHtmlBody(
      List<int> bytes, {
        String? contentTypeHeader,
      }) {
    final header = (contentTypeHeader ?? '').toLowerCase();
    final asciiPreview = latin1.decode(bytes, allowInvalid: true);

    String? detectedCharset;

    final headerMatch = RegExp(
      'charset\\s*=\\s*([a-zA-Z0-9._-]+)',
      caseSensitive: false,
    ).firstMatch(header);

    if (headerMatch != null) {
      detectedCharset = headerMatch.group(1)?.toLowerCase().trim();
    }

    detectedCharset ??= RegExp(
      "<meta[^>]+charset\\s*=\\s*['\\\"]?\\s*([a-zA-Z0-9._-]+)",
      caseSensitive: false,
    ).firstMatch(asciiPreview)?.group(1)?.toLowerCase().trim();

    detectedCharset ??= RegExp(
      'charset\\s*=\\s*([a-zA-Z0-9._-]+)',
      caseSensitive: false,
    ).firstMatch(asciiPreview)?.group(1)?.toLowerCase().trim();

    const turkishCharsets = {
      'iso-8859-9',
      'iso8859-9',
      'latin5',
      'windows-1254',
      'cp1254',
      'x-cp1254',
    };

    if (detectedCharset != null && turkishCharsets.contains(detectedCharset)) {
      try {
        final text = latin5.decode(bytes);
        return _fixBrokenTurkish(text);
      } catch (_) {}
    }

    try {
      final utf = utf8.decode(bytes);
      if (!_looksBrokenTurkish(utf)) {
        return _fixBrokenTurkish(utf);
      }
    } catch (_) {}

    try {
      final l5 = latin5.decode(bytes);
      return _fixBrokenTurkish(l5);
    } catch (_) {}

    try {
      return _fixBrokenTurkish(latin1.decode(bytes, allowInvalid: true));
    } catch (_) {
      return _fixBrokenTurkish(String.fromCharCodes(bytes));
    }
  }

  bool _looksBrokenTurkish(String text) {
    return text.contains('Ã') ||
        text.contains('Ä') ||
        text.contains('Å') ||
        text.contains('�') ||
        text.contains('Ý') ||
        text.contains('ý') ||
        text.contains('Ð') ||
        text.contains('ð') ||
        text.contains('Þ') ||
        text.contains('þ');
  }

  String _fixBrokenTurkish(String text) {
    return text
        .replaceAll('Ý', 'İ')
        .replaceAll('ý', 'ı')
        .replaceAll('Ð', 'Ğ')
        .replaceAll('ð', 'ğ')
        .replaceAll('Þ', 'Ş')
        .replaceAll('þ', 'ş')
        .replaceAll('Û', 'Ü')
        .replaceAll('û', 'ü');
  }

  String _clean(String value) {
    return _fixBrokenTurkish(
      value.replaceAll('\u00A0', ' ').replaceAll(RegExp(r'\s+'), ' ').trim(),
    );
  }

  String _normalizeCalorie(String value) {
    var text = _clean(value);

    if (text.isEmpty) return '';

    text = text
        .replaceAll('Kalori', '')
        .replaceAll(':', '')
        .replaceAll(';', ' ')
        .replaceAll(',', '.')
        .trim();

    final numberMatch = RegExp(r'(\d{2,5})').firstMatch(text);
    if (numberMatch != null) {
      return '${numberMatch.group(1)} kcal';
    }

    final lower = text.toLowerCase().trim();
    if (lower == 'kcal' || lower == 'kalori' || lower == '-') {
      return '';
    }

    return text;
  }

  String _cleanMealText(String value) {
    var text = _clean(value);

    text = text.replaceAll(
      RegExp(r'\s*20\d{2}\s*Munzur Üniversitesi\s*$', caseSensitive: false),
      '',
    );

    return text.trim();
  }

}