import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models/menu_item_model.dart';

class MenuService {
  static const String _academicMenuUrl =
      'https://raw.githubusercontent.com/utkuanil/munzur_mobil_data/main/data/menus/academic_menu.json';

  static const String _administrativeMenuUrl =
      'https://raw.githubusercontent.com/utkuanil/munzur_mobil_data/main/data/menus/administrative_menu.json';

  static const String _universityMenuUrl =
      'https://raw.githubusercontent.com/utkuanil/munzur_mobil_data/main/data/menus/university_menu.json';

  Future<List<MenuSectionModel>> fetchAcademicMenu() async {
    return _fetchMenu(_academicMenuUrl);
  }

  Future<List<MenuSectionModel>> fetchAdministrativeMenu() async {
    return _fetchMenu(_administrativeMenuUrl);
  }

  Future<List<MenuSectionModel>> fetchUniversityMenu() async {
    return _fetchMenu(_universityMenuUrl);
  }

  Future<List<MenuSectionModel>> _fetchMenu(String url) async {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      throw Exception('Menü verisi alınamadı.');
    }

    final decoded = jsonDecode(response.body);

    List<dynamic> items;

    if (decoded is List) {
      items = decoded;
    } else if (decoded is Map<String, dynamic> && decoded['sections'] is List) {
      items = decoded['sections'] as List<dynamic>;
    } else {
      throw Exception('Menü JSON formatı geçersiz.');
    }

    return items
        .map((e) => MenuSectionModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }
}