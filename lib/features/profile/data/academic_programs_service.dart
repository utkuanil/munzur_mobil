import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models/academic_program.dart';

class AcademicProgramsService {
  // Burayı kendi gerçek GitHub kullanıcı adınla değiştir
  static const String _jsonUrl =
      'https://raw.githubusercontent.com/utkuanil/munzur_mobil_data/main/data/academic_programs.json';

  Future<List<AcademicProgram>> fetchPrograms() async {
    final response = await http.get(Uri.parse(_jsonUrl));

    if (response.statusCode != 200) {
      throw Exception('Program JSON dosyası alınamadı.');
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! List) {
      throw Exception('Program JSON formatı geçersiz.');
    }

    return decoded
        .map((e) => AcademicProgram.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<AcademicProgram?> findProgramForUser({
    required String educationLevel,
    required String academicUnit,
    required String department,
  }) async {
    final programs = await fetchPrograms();

    try {
      return programs.firstWhere(
            (p) => p.matchesUser(
          educationLevel: educationLevel,
          academicUnit: academicUnit,
          department: department,
        ),
      );
    } catch (_) {
      return null;
    }
  }
}