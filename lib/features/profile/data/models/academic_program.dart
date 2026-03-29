class AcademicProgram {
  final String educationLevel;
  final String academicUnit;
  final String department;
  final String courseSchedulePdf;
  final String midtermPdf;
  final String finalPdf;
  final String makeupPdf;
  final String? updatedAt;

  const AcademicProgram({
    required this.educationLevel,
    required this.academicUnit,
    required this.department,
    required this.courseSchedulePdf,
    required this.midtermPdf,
    required this.finalPdf,
    required this.makeupPdf,
    this.updatedAt,
  });

  factory AcademicProgram.fromMap(Map<String, dynamic> map) {
    return AcademicProgram(
      educationLevel: (map['educationLevel'] ?? '').toString(),
      academicUnit: (map['academicUnit'] ?? '').toString(),
      department: (map['department'] ?? '').toString(),
      courseSchedulePdf: (map['courseSchedulePdf'] ?? '').toString(),
      midtermPdf: (map['midtermPdf'] ?? '').toString(),
      finalPdf: (map['finalPdf'] ?? '').toString(),
      makeupPdf: (map['makeupPdf'] ?? '').toString(),
      updatedAt: map['updatedAt']?.toString(),
    );
  }

  bool matchesUser({
    required String educationLevel,
    required String academicUnit,
    required String department,
  }) {
    return this.educationLevel.trim() == educationLevel.trim() &&
        this.academicUnit.trim() == academicUnit.trim() &&
        this.department.trim() == department.trim();
  }
}