import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../../../core/utils/validators.dart';
import '../data/auth_repository.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _studentNoController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _repo = AuthRepository();

  bool _loading = false;
  bool _loadingAcademicData = true;
  bool _loadingAdministrativeData = true;
  String? _error;
  bool _obscurePassword = true;

  String? _educationLevel;
  String? _unit;
  String? _department;

  String? _staffType;
  String? _staffUnit;
  String? _staffDepartment;
  String? _academicTitle;
  String? _adminEmploymentType;

  String? _currentRole;

  Map<String, Map<String, List<String>>> _academicStructure = {
    'Ön Lisans': {},
    'Lisans': {},
    'Lisansüstü': {},
  };

  List<String> _staffAcademicUnits = [];
  List<String> _administrativeUnits = [];

  static const List<String> _educationLevels = [
    'Ön Lisans',
    'Lisans',
    'Lisansüstü',
  ];

  static const List<String> _staffTypes = [
    'Akademik',
    'İdari',
  ];

  static const List<String> _academicTitles = [
    'Arş. Gör.',
    'Öğr. Gör.',
    'Dr. Öğr. Üyesi',
    'Doç. Dr.',
    'Prof. Dr.',
  ];

  static const List<String> _adminEmploymentTypes = [
    'Genel İdari Hizmetler',
    'Teknik Hizmetler',
    'Sağlık Hizmetleri',
    'Avukatlık Hizmetleri',
    'Yardımcı Hizmetler',
    'Sözleşmeli Personel',
    'Sürekli İşçi',
  ];

  static const String _academicMenuUrl =
      'https://raw.githubusercontent.com/utkuanil/munzur_mobil_data/main/data/menus/academic_menu.json';

  static const String _administrativeMenuUrl =
      'https://raw.githubusercontent.com/utkuanil/munzur_mobil_data/main/data/menus/administrative_menu.json';

  @override
  void initState() {
    super.initState();
    _loadAcademicStructure();
    _loadAdministrativeUnits();
  }

  Future<void> _loadAcademicStructure() async {
    try {
      final response = await http.get(Uri.parse(_academicMenuUrl));

      if (response.statusCode != 200) {
        throw Exception('academic_menu.json alınamadı');
      }

      final decoded = json.decode(response.body);

      if (decoded is! List) {
        throw Exception('academic_menu.json formatı geçersiz');
      }

      final parsed = _parseAcademicStructure(decoded);
      final staffAcademicUnits = _parseStaffAcademicUnits(decoded);

      if (!mounted) return;
      setState(() {
        _academicStructure = parsed;
        _staffAcademicUnits = staffAcademicUnits;
        _loadingAcademicData = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingAcademicData = false;
        _error = 'Akademik veriler yüklenemedi: $e';
      });
    }
  }

  Future<void> _loadAdministrativeUnits() async {
    try {
      final response = await http.get(Uri.parse(_administrativeMenuUrl));

      if (response.statusCode != 200) {
        throw Exception('administrative_menu.json alınamadı');
      }

      final decoded = json.decode(response.body);

      if (decoded is! List) {
        throw Exception('administrative_menu.json formatı geçersiz');
      }

      final units = _parseAdministrativeUnits(decoded);

      if (!mounted) return;
      setState(() {
        _administrativeUnits = units;
        _loadingAdministrativeData = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingAdministrativeData = false;
        _error = 'İdari birim verileri yüklenemedi: $e';
      });
    }
  }

  Map<String, Map<String, List<String>>> _parseAcademicStructure(
      List<dynamic> data,
      ) {
    final Map<String, Map<String, List<String>>> result = {
      'Ön Lisans': {},
      'Lisans': {},
      'Lisansüstü': {},
    };

    for (final rawSection in data) {
      if (rawSection is! Map<String, dynamic>) continue;

      final sectionTitle = (rawSection['title'] ?? '').toString().trim();
      final items = rawSection['items'];

      if (items is! List) continue;

      if (sectionTitle == 'Meslek Yüksekokulları') {
        for (final rawItem in items) {
          if (rawItem is! Map<String, dynamic>) continue;

          final unitTitle = (rawItem['title'] ?? '').toString().trim();
          final children = rawItem['children'];

          if (unitTitle.isEmpty || children is! List) continue;

          final departments = children
              .whereType<Map<String, dynamic>>()
              .map((e) => (e['title'] ?? '').toString().trim())
              .where((e) => e.isNotEmpty)
              .toList();

          result['Ön Lisans']![unitTitle] = departments;
        }
      } else if (sectionTitle == 'Fakülteler') {
        for (final rawItem in items) {
          if (rawItem is! Map<String, dynamic>) continue;

          final unitTitle = (rawItem['title'] ?? '').toString().trim();
          final children = rawItem['children'];

          if (unitTitle.isEmpty || children is! List) continue;

          final departments = children
              .whereType<Map<String, dynamic>>()
              .map((e) => (e['title'] ?? '').toString().trim())
              .where((e) => e.isNotEmpty)
              .toList();

          result['Lisans']![unitTitle] = departments;
        }
      } else if (sectionTitle == 'Enstitü') {
        for (final rawItem in items) {
          if (rawItem is! Map<String, dynamic>) continue;

          final unitTitle = (rawItem['title'] ?? '').toString().trim();
          final children = rawItem['children'];

          if (unitTitle.isEmpty || children is! List) continue;

          final departments = children
              .whereType<Map<String, dynamic>>()
              .map((e) => (e['title'] ?? '').toString().trim())
              .where((e) => e.isNotEmpty)
              .toList();

          result['Lisansüstü']![unitTitle] = departments;
        }
      }
    }

    return result;
  }

  List<String> _parseStaffAcademicUnits(List<dynamic> data) {
    final units = <String>{};

    for (final rawSection in data) {
      if (rawSection is! Map<String, dynamic>) continue;

      final items = rawSection['items'];
      if (items is! List) continue;

      for (final rawItem in items) {
        if (rawItem is! Map<String, dynamic>) continue;

        final title = (rawItem['title'] ?? '').toString().trim();
        if (title.isNotEmpty) {
          units.add(title);
        }
      }
    }

    final sorted = units.toList()..sort((a, b) => a.compareTo(b));
    return sorted;
  }

  List<String> _parseAdministrativeUnits(List<dynamic> data) {
    final units = <String>[];

    for (final rawSection in data) {
      if (rawSection is! Map<String, dynamic>) continue;

      final items = rawSection['items'];
      if (items is! List) continue;

      for (final rawItem in items) {
        if (rawItem is! Map<String, dynamic>) continue;

        final title = (rawItem['title'] ?? '').toString().trim();
        if (title.isNotEmpty) {
          units.add(title);
        }
      }
    }

    return units;
  }

  String? _detectRoleFromEmail(String email) {
    final normalized = email.trim().toLowerCase();

    if (normalized.isEmpty) return null;
    if (!normalized.endsWith('@munzur.edu.tr')) return null;

    final localPart = normalized.split('@').first;

    if (RegExp(r'^\d+$').hasMatch(localPart)) {
      return 'student';
    }

    return 'staff';
  }

  String _extractStudentNoFromEmail(String email) {
    final normalized = email.trim().toLowerCase();
    final localPart = normalized.split('@').first;
    return RegExp(r'^\d+$').hasMatch(localPart) ? localPart : '';
  }

  bool get _isStudent => _currentRole == 'student';
  bool get _isStaff => _currentRole == 'staff';
  bool get _hasTypedEmail => _emailController.text.trim().isNotEmpty;

  List<String> get _unitOptions {
    if (_educationLevel == null) return [];
    return _academicStructure[_educationLevel]?.keys.toList() ?? [];
  }

  List<String> get _departmentOptions {
    if (_educationLevel == null || _unit == null) return [];
    return _academicStructure[_educationLevel]?[_unit] ?? [];
  }

  List<String> get _staffUnitOptions {
    if (_staffType == 'Akademik') return _staffAcademicUnits;
    if (_staffType == 'İdari') return _administrativeUnits;
    return [];
  }

  List<String> get _staffDepartmentOptions {
    if (_staffUnit == null) return [];

    for (final level in _academicStructure.values) {
      if (level.containsKey(_staffUnit)) {
        return level[_staffUnit]!;
      }
    }

    return [];
  }

  void _resetStudentFields() {
    _studentNoController.clear();
    _educationLevel = null;
    _unit = null;
    _department = null;
  }

  void _resetStaffFields() {
    _staffType = null;
    _staffUnit = null;
    _staffDepartment = null;
    _academicTitle = null;
    _adminEmploymentType = null;
  }

  void _onEmailChanged(String value) {
    final detectedRole = _detectRoleFromEmail(value);
    final extractedStudentNo = _extractStudentNoFromEmail(value);

    setState(() {
      _error = null;

      if (detectedRole != _currentRole) {
        _currentRole = detectedRole;

        if (detectedRole == 'student') {
          _resetStaffFields();
        } else if (detectedRole == 'staff') {
          _resetStudentFields();
        } else {
          _resetStudentFields();
          _resetStaffFields();
        }
      }

      if (detectedRole == 'student') {
        _studentNoController.text = extractedStudentNo;
      }
    });
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_currentRole == null) {
      setState(() {
        _error =
        'Lütfen geçerli bir Munzur Üniversitesi e-posta adresi giriniz.';
      });
      return;
    }

    if (_isStudent) {
      if (_educationLevel == null || _unit == null || _department == null) {
        setState(() {
          _error =
          'Lütfen öğrenim düzeyi, akademik birim ve bölüm/anabilim dalı seçiniz.';
        });
        return;
      }
    }

    if (_isStaff) {
      if (_staffType == null || _staffUnit == null) {
        setState(() {
          _error = 'Lütfen personel türü ve bağlı bulunduğu birimi seçiniz.';
        });
        return;
      }

      if (_staffType == 'Akademik') {
        if (_staffDepartment == null) {
          setState(() {
            _error = 'Lütfen bölüm/anabilim dalı seçiniz.';
          });
          return;
        }
        if (_academicTitle == null) {
          setState(() {
            _error = 'Lütfen ünvan seçiniz.';
          });
          return;
        }
      }

      if (_staffType == 'İdari' && _adminEmploymentType == null) {
        setState(() {
          _error = 'Lütfen kadro türü seçiniz.';
        });
        return;
      }
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _repo.register(
        fullName: _fullNameController.text.trim(),
        studentNo: _isStudent ? _studentNoController.text.trim() : '',
        email: _emailController.text.trim(),
        password: _passwordController.text,
        educationLevel: _isStudent ? (_educationLevel ?? '') : '',
        academicUnit: _isStudent
            ? (_unit ?? '')
            : (_isStaff && _staffType == 'Akademik' ? (_staffUnit ?? '') : ''),
        department: _isStudent
            ? (_department ?? '')
            : (_isStaff && _staffType == 'Akademik'
            ? (_staffDepartment ?? '')
            : ''),
        staffType: _isStaff ? (_staffType ?? '') : '',
        administrativeUnit:
        (_isStaff && _staffType == 'İdari') ? (_staffUnit ?? '') : '',
        academicTitle:
        (_isStaff && _staffType == 'Akademik') ? (_academicTitle ?? '') : '',
        employmentType: (_isStaff && _staffType == 'İdari')
            ? (_adminEmploymentType ?? '')
            : '',
      );

      if (!mounted) return;

      context.go(
        '/verify-email?email=${Uri.encodeComponent(_emailController.text.trim())}',
      );
    } catch (e) {
      setState(() {
        _error = 'Kayıt sırasında hata oluştu: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _studentNoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final studentUnitLabel = _educationLevel == 'Ön Lisans'
        ? 'Meslek Yüksekokulu'
        : _educationLevel == 'Lisans'
        ? 'Fakülte'
        : 'Enstitü';

    final studentDepartmentLabel =
    _educationLevel == 'Lisansüstü' ? 'Anabilim Dalı (ABD)' : 'Bölüm';

    final isLoadingRemoteData =
        _loadingAcademicData || _loadingAdministrativeData;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kayıt Ol'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const Icon(
                          Icons.person_add_alt_1_outlined,
                          size: 56,
                          color: Color(0xFF1D8FA3),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Yeni Hesap Oluştur',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Sadece @munzur.edu.tr uzantılı e-posta ile kayıt olunabilir',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        TextFormField(
                          controller: _fullNameController,
                          decoration: _inputDecoration(
                            label: 'Ad Soyad',
                            icon: Icons.person_outline,
                          ),
                          validator: (v) =>
                              Validators.validateRequired(v, 'Ad Soyad'),
                        ),
                        const SizedBox(height: 14),

                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          onChanged: _onEmailChanged,
                          decoration: _inputDecoration(
                            label: 'Üniversite E-postası',
                            icon: Icons.email_outlined,
                          ),
                          validator: (v) {
                            final baseValidation = Validators.validateEmail(v);
                            if (baseValidation != null) return baseValidation;

                            final email = (v ?? '').trim().toLowerCase();
                            if (!email.endsWith('@munzur.edu.tr')) {
                              return 'Lütfen @munzur.edu.tr uzantılı e-posta giriniz';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        if (_hasTypedEmail && isLoadingRemoteData)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 14),
                            child: LinearProgressIndicator(),
                          ),

                        if (_isStudent) ...[
                          TextFormField(
                            controller: _studentNoController,
                            readOnly: true,
                            decoration: _inputDecoration(
                              label: 'Öğrenci Numarası',
                              icon: Icons.badge_outlined,
                            ),
                            validator: (v) => _isStudent
                                ? Validators.validateRequired(
                              v,
                              'Öğrenci Numarası',
                            )
                                : null,
                          ),
                          const SizedBox(height: 14),

                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: _educationLevel,
                            hint: const Text('Öğrenim düzeyi seçiniz'),
                            decoration: _inputDecoration(
                              label: 'Öğrenim Düzeyi',
                              icon: Icons.school_outlined,
                            ),
                            items: _educationLevels
                                .map(
                                  (e) => DropdownMenuItem<String>(
                                value: e,
                                child: Text(
                                  e,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                                .toList(),
                            onChanged: (_loading || _loadingAcademicData)
                                ? null
                                : (value) {
                              setState(() {
                                _educationLevel = value;
                                _unit = null;
                                _department = null;
                              });
                            },
                            validator: (v) {
                              if (!_isStudent) return null;
                              return v == null ? 'Öğrenim düzeyi seçiniz' : null;
                            },
                          ),
                          const SizedBox(height: 14),

                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: _unit,
                            hint: const Text('Önce öğrenim düzeyi seçiniz'),
                            decoration: _inputDecoration(
                              label: studentUnitLabel,
                              icon: Icons.account_balance_outlined,
                            ),
                            items: _unitOptions
                                .map(
                                  (e) => DropdownMenuItem<String>(
                                value: e,
                                child: Text(
                                  e,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                                .toList(),
                            onChanged: (_educationLevel == null ||
                                _loading ||
                                _loadingAcademicData)
                                ? null
                                : (value) {
                              setState(() {
                                _unit = value;
                                _department = null;
                              });
                            },
                            validator: (v) {
                              if (!_isStudent) return null;
                              if (_educationLevel == null) return null;
                              return v == null ? '$studentUnitLabel seçiniz' : null;
                            },
                          ),
                          const SizedBox(height: 14),

                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: _department,
                            hint: Text('Önce $studentUnitLabel seçiniz'),
                            decoration: _inputDecoration(
                              label: studentDepartmentLabel,
                              icon: Icons.apartment_outlined,
                            ),
                            items: _departmentOptions
                                .map(
                                  (e) => DropdownMenuItem<String>(
                                value: e,
                                child: Text(
                                  e,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                                .toList(),
                            onChanged: (_educationLevel == null ||
                                _unit == null ||
                                _loading ||
                                _loadingAcademicData)
                                ? null
                                : (value) {
                              setState(() {
                                _department = value;
                              });
                            },
                            validator: (v) {
                              if (!_isStudent) return null;
                              if (_educationLevel == null || _unit == null) {
                                return null;
                              }
                              return v == null
                                  ? '$studentDepartmentLabel seçiniz'
                                  : null;
                            },
                          ),
                          const SizedBox(height: 14),
                        ],

                        if (_isStaff) ...[
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: _staffType,
                            hint: const Text('Akademik veya İdari seçiniz'),
                            decoration: _inputDecoration(
                              label: 'Personel Türü',
                              icon: Icons.work_outline,
                            ),
                            items: _staffTypes
                                .map(
                                  (e) => DropdownMenuItem<String>(
                                value: e,
                                child: Text(e),
                              ),
                            )
                                .toList(),
                            onChanged: (_loading || isLoadingRemoteData)
                                ? null
                                : (value) {
                              setState(() {
                                _staffType = value;
                                _staffUnit = null;
                                _staffDepartment = null;
                                _academicTitle = null;
                                _adminEmploymentType = null;
                              });
                            },
                            validator: (v) {
                              if (!_isStaff) return null;
                              return v == null ? 'Personel türü seçiniz' : null;
                            },
                          ),
                          const SizedBox(height: 14),

                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: _staffUnit,
                            hint: const Text('Önce personel türü seçiniz'),
                            decoration: _inputDecoration(
                              label: 'Bağlı Bulunduğu Birim',
                              icon: Icons.business_outlined,
                            ),
                            items: _staffUnitOptions
                                .map(
                                  (e) => DropdownMenuItem<String>(
                                value: e,
                                child: Text(
                                  e,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                                .toList(),
                            onChanged: (_staffType == null ||
                                _loading ||
                                isLoadingRemoteData)
                                ? null
                                : (value) {
                              setState(() {
                                _staffUnit = value;
                                _staffDepartment = null;
                              });
                            },
                            validator: (v) {
                              if (!_isStaff) return null;
                              if (_staffType == null) return null;
                              return v == null
                                  ? 'Bağlı bulunduğu birimi seçiniz'
                                  : null;
                            },
                          ),
                          const SizedBox(height: 14),

                          if (_staffType == 'Akademik') ...[
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: _staffDepartment,
                              hint: const Text('Önce birim seçiniz'),
                              decoration: _inputDecoration(
                                label: 'Bölüm / ABD',
                                icon: Icons.apartment_outlined,
                              ),
                              items: _staffDepartmentOptions
                                  .map(
                                    (e) => DropdownMenuItem<String>(
                                  value: e,
                                  child: Text(
                                    e,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                                  .toList(),
                              onChanged: (_staffUnit == null ||
                                  _loading ||
                                  _loadingAcademicData)
                                  ? null
                                  : (value) {
                                setState(() {
                                  _staffDepartment = value;
                                });
                              },
                              validator: (v) {
                                if (!_isStaff) return null;
                                if (_staffType != 'Akademik') return null;
                                if (_staffUnit == null) return null;
                                return v == null ? 'Bölüm / ABD seçiniz' : null;
                              },
                            ),
                            const SizedBox(height: 14),

                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: _academicTitle,
                              hint: const Text('Ünvan seçiniz'),
                              decoration: _inputDecoration(
                                label: 'Ünvan',
                                icon: Icons.workspace_premium_outlined,
                              ),
                              items: _academicTitles
                                  .map(
                                    (e) => DropdownMenuItem<String>(
                                  value: e,
                                  child: Text(
                                    e,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                                  .toList(),
                              onChanged: (_loading)
                                  ? null
                                  : (value) {
                                setState(() {
                                  _academicTitle = value;
                                });
                              },
                              validator: (v) {
                                if (!_isStaff) return null;
                                if (_staffType != 'Akademik') return null;
                                return v == null ? 'Ünvan seçiniz' : null;
                              },
                            ),
                            const SizedBox(height: 14),
                          ],

                          if (_staffType == 'İdari') ...[
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: _adminEmploymentType,
                              hint: const Text('Kadro türü seçiniz'),
                              decoration: _inputDecoration(
                                label: 'Kadro Türü',
                                icon: Icons.badge_outlined,
                              ),
                              items: _adminEmploymentTypes
                                  .map(
                                    (e) => DropdownMenuItem<String>(
                                  value: e,
                                  child: Text(
                                    e,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                                  .toList(),
                              onChanged: (_loading)
                                  ? null
                                  : (value) {
                                setState(() {
                                  _adminEmploymentType = value;
                                });
                              },
                              validator: (v) {
                                if (!_isStaff) return null;
                                if (_staffType != 'İdari') return null;
                                return v == null ? 'Kadro türü seçiniz' : null;
                              },
                            ),
                            const SizedBox(height: 14),
                          ],
                        ],

                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Şifre',
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: Validators.validatePassword,
                        ),
                        const SizedBox(height: 18),

                        if (_error != null)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.red.shade100,
                              ),
                            ),
                            child: Text(
                              _error!,
                              style: TextStyle(
                                color: Colors.red.shade800,
                              ),
                            ),
                          ),

                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _loading ? null : _register,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _loading
                                ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                                : const Text('Kayıt Ol'),
                          ),
                        ),
                        const SizedBox(height: 12),

                        TextButton(
                          onPressed: _loading ? null : () => context.pop(),
                          child: const Text('Zaten hesabın var mı? Giriş yap'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}