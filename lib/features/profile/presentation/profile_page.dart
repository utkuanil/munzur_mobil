import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../academic/data/academic_menu_helper.dart';
import '../../../core/navigation/home_tab_controller.dart';
import '../../academic_calendar/presentation/academic_calendar_page.dart';
import '../../ai/data/academic_calendar_ai_helper.dart';
import '../../ai/data/ai_insight_service.dart';
import '../../ai/data/models/ai_insight_item.dart';
import '../../ai/presentation/widgets/ai_insights_card.dart';
import '../../external/data/munzur_site_service.dart';
import '../../meals/presentation/meals_page.dart';
import '../data/academic_calendar_service.dart';
import '../data/academic_programs_service.dart';
import '../data/models/academic_calendar_event.dart';
import '../data/models/academic_program.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Future<void> _openUrl(BuildContext context, String url) async {
    if (url.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bağlantı bulunamadı.')),
      );
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bağlantı geçersiz.')),
      );
      return;
    }

    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bağlantı açılamadı.')),
      );
    }
  }

  Future<void> _changePassword({
    required BuildContext context,
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.email == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Oturum bilgisi bulunamadı.')),
        );
      }
      return;
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);

      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Şifren başarıyla güncellendi.')),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Şifre güncellenemedi.';

      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = 'Mevcut şifre hatalı.';
      } else if (e.code == 'weak-password') {
        message = 'Yeni şifre en az 6 karakter olmalıdır.';
      } else if (e.code == 'too-many-requests') {
        message = 'Çok fazla deneme yapıldı. Lütfen biraz sonra tekrar dene.';
      } else if (e.code == 'requires-recent-login') {
        message = 'Bu işlem için yeniden giriş yapman gerekiyor.';
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Beklenmeyen bir hata oluştu.')),
        );
      }
    }
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool loading = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Change Password'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: currentPasswordController,
                        obscureText: obscureCurrent,
                        decoration: InputDecoration(
                          labelText: 'Current Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setDialogState(() {
                                obscureCurrent = !obscureCurrent;
                              });
                            },
                            icon: Icon(
                              obscureCurrent
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Current password is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: newPasswordController,
                        obscureText: obscureNew,
                        decoration: InputDecoration(
                          labelText: 'New Password',
                          prefixIcon: const Icon(Icons.lock_reset_outlined),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setDialogState(() {
                                obscureNew = !obscureNew;
                              });
                            },
                            icon: Icon(
                              obscureNew
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'New password is required';
                          }
                          if (value.trim().length < 6) {
                            return 'New password must be at least 6 characters';
                          }
                          if (value.trim() ==
                              currentPasswordController.text.trim()) {
                            return 'New password cannot be the same as current password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: obscureConfirm,
                        decoration: InputDecoration(
                          labelText: 'Confirm New Password',
                          prefixIcon:
                          const Icon(Icons.verified_user_outlined),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setDialogState(() {
                                obscureConfirm = !obscureConfirm;
                              });
                            },
                            icon: Icon(
                              obscureConfirm
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Password confirmation is required';
                          }
                          if (value.trim() !=
                              newPasswordController.text.trim()) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                  loading ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: loading
                      ? null
                      : () async {
                    if (!formKey.currentState!.validate()) return;

                    setDialogState(() {
                      loading = true;
                    });

                    await _changePassword(
                      context: dialogContext,
                      currentPassword:
                      currentPasswordController.text.trim(),
                      newPassword: newPasswordController.text.trim(),
                    );

                    if (dialogContext.mounted) {
                      setDialogState(() {
                        loading = false;
                      });
                    }
                  },
                  child: loading
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  bool _isPasswordUser(User user) {
    return user.providerData.any((p) => p.providerId == 'password');
  }

  Future<void> _deleteUserRelatedData(String uid) async {
    final firestore = FirebaseFirestore.instance;

    await firestore.collection('users').doc(uid).delete();

    // İleride kullanıcıya bağlı başka koleksiyonlar varsa buraya ekleyebilirsin.
    // await firestore.collection('favorites').doc(uid).delete();
    // await firestore.collection('settings').doc(uid).delete();
  }

  Future<void> _deleteAccount({
    required BuildContext context,
    String? currentPassword,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Oturum bilgisi bulunamadı.')),
        );
      }
      return;
    }

    try {
      if (_isPasswordUser(user)) {
        final email = user.email;

        if (email == null || email.trim().isEmpty) {
          throw FirebaseAuthException(
            code: 'invalid-user',
            message: 'Kullanıcı e-posta bilgisi bulunamadı.',
          );
        }

        if (currentPassword == null || currentPassword.trim().isEmpty) {
          throw FirebaseAuthException(
            code: 'missing-password',
            message: 'Mevcut şifre gerekli.',
          );
        }

        final credential = EmailAuthProvider.credential(
          email: email.trim(),
          password: currentPassword.trim(),
        );

        await user.reauthenticateWithCredential(credential);
      }

      final uid = user.uid;

      await _deleteUserRelatedData(uid);
      await user.delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your account has been permanently deleted.'),
          ),
        );
        context.go('/login');
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Account could not be deleted.';

      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = 'Current password is incorrect.';
      } else if (e.code == 'requires-recent-login') {
        message =
        'Re-authentication is required for security reasons. Please try again.';
      } else if (e.code == 'missing-password') {
        message = 'Please enter your current password.';
      } else if (e.code == 'too-many-requests') {
        message = 'Too many attempts. Please try again later.';
      } else if (e.code == 'network-request-failed') {
        message = 'Network error. Please check your internet connection.';
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An unexpected error occurred.'),
          ),
        );
      }
    }
  }

  void _showDeleteAccountConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: const Text(
            'Are you sure you want to permanently delete your account?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton.tonal(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _showDeleteAccountDialog(context);
              },
              style: FilledButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final requiresPassword = user != null && _isPasswordUser(user);

    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    bool loading = false;
    bool obscurePassword = true;

    showDialog(
      context: context,
      barrierDismissible: !loading,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Delete Account'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'This action will permanently delete your account and associated user data. This cannot be undone.',
                      ),
                      if (requiresPassword) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: passwordController,
                          obscureText: obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Current Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setDialogState(() {
                                  obscurePassword = !obscurePassword;
                                });
                              },
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (!requiresPassword) return null;
                            if (value == null || value.trim().isEmpty) {
                              return 'Current password is required';
                            }
                            return null;
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                  loading ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton.tonal(
                  onPressed: loading
                      ? null
                      : () async {
                    if (!formKey.currentState!.validate()) return;

                    setDialogState(() {
                      loading = true;
                    });

                    await _deleteAccount(
                      context: dialogContext,
                      currentPassword: requiresPassword
                          ? passwordController.text.trim()
                          : null,
                    );

                    if (dialogContext.mounted) {
                      setDialogState(() {
                        loading = false;
                      });
                    }
                  },
                  style: FilledButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: loading
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('Delete Account'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _extractStudentNoFromEmail(String email) {
    final normalized = email.trim().toLowerCase();

    if (!normalized.endsWith('@munzur.edu.tr')) {
      return '';
    }

    final localPart = normalized.split('@').first.trim();

    if (RegExp(r'^\d{9,}$').hasMatch(localPart)) {
      return localPart;
    }

    return '';
  }

  String _resolveStudentNo(Map<String, dynamic> data) {
    final rawStudentNo = (data['studentNo'] ?? '').toString().trim();
    if (rawStudentNo.isNotEmpty) return rawStudentNo;

    final email = (data['email'] ?? '').toString().trim();
    return _extractStudentNoFromEmail(email);
  }

  int? _extractEntryYearFromStudentNo(String studentNo) {
    if (studentNo.length < 2) return null;

    final prefix = int.tryParse(studentNo.substring(0, 2));
    if (prefix == null) return null;

    final fullYear = 2000 + prefix;
    final now = DateTime.now();

    if (fullYear < 2000 || fullYear > now.year + 1) {
      return null;
    }

    return fullYear;
  }

  int? _estimateClassYearFromStudentNo(String studentNo) {
    final entryYear = _extractEntryYearFromStudentNo(studentNo);
    if (entryYear == null) return null;

    final now = DateTime.now();

    int classYear = now.year - entryYear;
    if (now.month >= 9) {
      classYear += 1;
    }

    if (classYear < 1) classYear = 1;
    if (classYear > 6) classYear = 6;

    return classYear;
  }

  String _studentClassLabel(Map<String, dynamic> data) {
    final studentNo = _resolveStudentNo(data);
    if (studentNo.isEmpty) return '-';

    final classYear = _estimateClassYearFromStudentNo(studentNo);
    if (classYear == null) return '-';

    return '$classYear. Sınıf';
  }

  String _valueOrDash(dynamic value) {
    final text = (value ?? '').toString().trim();
    return text.isEmpty ? '-' : text;
  }

  Future<AcademicProgram?> _fetchProgram(Map<String, dynamic> userData) async {
    final educationLevel = (userData['educationLevel'] ?? '').toString().trim();
    final academicUnit = (userData['academicUnit'] ?? '').toString().trim();
    final department = (userData['department'] ?? '').toString().trim();

    if (educationLevel.isEmpty || academicUnit.isEmpty || department.isEmpty) {
      return null;
    }

    return AcademicProgramsService().findProgramForUser(
      educationLevel: educationLevel,
      academicUnit: academicUnit,
      department: department,
    );
  }

  Future<int> _fetchAnnouncementCount() async {
    try {
      final announcements = await FirebaseFirestore.instance
          .collection('announcements')
          .limit(20)
          .get();
      return announcements.docs.length;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _fetchEventCount() async {
    try {
      final events = await FirebaseFirestore.instance
          .collection('events')
          .limit(20)
          .get();
      return events.docs.length;
    } catch (_) {
      return 0;
    }
  }

  DateTime? _parseMealDate(String value) {
    final parts = value.split('.');
    if (parts.length != 3) return null;

    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);

    if (day == null || month == null || year == null) return null;

    return DateTime(year, month, day);
  }

  Future<bool> _hasMealToday() async {
    try {
      final meals = await MunzurSiteService().fetchMeals();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      for (final meal in meals) {
        final rawDate = (meal['date'] ?? '').trim();
        final parsed = _parseMealDate(rawDate);
        if (parsed == null) continue;

        final dateOnly = DateTime(parsed.year, parsed.month, parsed.day);
        if (dateOnly == today) return true;
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  Future<List<AiInsightItem>> _buildAiInsights(
      Map<String, dynamic> userData,
      ) async {
    final role = (userData['role'] ?? 'student').toString().toLowerCase();

    bool hasAcademicCalendar = false;
    AcademicCalendarEvent? ongoingAcademicEvent;
    AcademicCalendarEvent? upcomingAcademicEvent;

    try {
      final calendar = await AcademicCalendarService().fetchCalendar();
      hasAcademicCalendar = calendar.academicCalendarUrl.trim().isNotEmpty;

      final allEvents = calendar.datedItems;
      final preferredTypes =
      AcademicCalendarAiHelper.preferredTypesForUser(userData);

      ongoingAcademicEvent =
          AcademicCalendarAiHelper.findOngoingEvent(allEvents);

      upcomingAcademicEvent = AcademicCalendarAiHelper.findUpcomingEvent(
        allEvents,
        withinDays: 10,
        preferredTypes: preferredTypes,
      );
    } catch (_) {}

    bool hasMatchedProgram = false;
    bool hasCourseSchedule = false;
    bool hasMidterm = false;
    bool hasFinal = false;
    bool hasMakeup = false;

    if (role != 'staff') {
      try {
        final program = await _fetchProgram(userData);
        if (program != null) {
          hasMatchedProgram = true;
          hasCourseSchedule = program.courseSchedulePdf.trim().isNotEmpty;
          hasMidterm = program.midtermPdf.trim().isNotEmpty;
          hasFinal = program.finalPdf.trim().isNotEmpty;
          hasMakeup = program.makeupPdf.trim().isNotEmpty;
        }
      } catch (_) {}
    }

    final announcementCount = await _fetchAnnouncementCount();
    final eventCount = await _fetchEventCount();
    final hasMealToday = await _hasMealToday();

    final upcomingStartDate = upcomingAcademicEvent?.startDate;

    return AiInsightService().generateInsights(
      userData: userData,
      hasAcademicCalendar: hasAcademicCalendar,
      hasMatchedProgram: hasMatchedProgram,
      hasCourseSchedule: hasCourseSchedule,
      hasMidterm: hasMidterm,
      hasFinal: hasFinal,
      hasMakeup: hasMakeup,
      announcementCount: announcementCount,
      eventCount: eventCount,
      hasMealToday: hasMealToday,
      ongoingAcademicEventTitle: ongoingAcademicEvent?.title,
      upcomingAcademicEventTitle: upcomingAcademicEvent?.title,
      ongoingAcademicEventCategory: ongoingAcademicEvent == null
          ? null
          : AcademicCalendarAiHelper.classifyEvent(ongoingAcademicEvent).name,
      upcomingAcademicEventCategory: upcomingAcademicEvent == null
          ? null
          : AcademicCalendarAiHelper.classifyEvent(upcomingAcademicEvent).name,
      upcomingAcademicEventDaysLeft: upcomingStartDate == null
          ? null
          : AcademicCalendarAiHelper.daysUntil(upcomingStartDate),
    );
  }

  Future<void> _handleInsightAction(
      BuildContext context,
      AiInsightItem item,
      Map<String, dynamic> userData,
      ) async {
    await AiInsightService.recordInteraction(item);
    switch (item.actionType) {
      case 'academic_calendar':
        if (context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const AcademicCalendarPage(),
            ),
          );
        }
        break;

      case 'course_schedule':
        final program = await _fetchProgram(userData);
        if (program != null &&
            program.courseSchedulePdf.trim().isNotEmpty &&
            context.mounted) {
          await _openUrl(context, program.courseSchedulePdf);
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ders programı bulunamadı.')),
          );
        }
        break;

      case 'department_page':
        final academicUnit = (userData['academicUnit'] ?? '').toString();
        final department = (userData['department'] ?? '').toString();

        final url = await AcademicMenuHelper.findDepartmentUrl(
          academicUnit: academicUnit,
          department: department,
        );

        if (url != null && context.mounted) {
          await _openUrl(context, url);
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bölüm sayfası bulunamadı.')),
          );
        }
        break;

      case 'midterm':
        final program = await _fetchProgram(userData);
        if (program != null &&
            program.midtermPdf.trim().isNotEmpty &&
            context.mounted) {
          await _openUrl(context, program.midtermPdf);
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vize programı bulunamadı.')),
          );
        }
        break;

      case 'final':
        final program = await _fetchProgram(userData);
        if (program != null &&
            program.finalPdf.trim().isNotEmpty &&
            context.mounted) {
          await _openUrl(context, program.finalPdf);
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Final programı bulunamadı.')),
          );
        }
        break;

      case 'makeup':
        final program = await _fetchProgram(userData);
        if (program != null &&
            program.makeupPdf.trim().isNotEmpty &&
            context.mounted) {
          await _openUrl(context, program.makeupPdf);
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bütünleme programı bulunamadı.')),
          );
        }
        break;

      case 'announcements':
        HomeTabController.goTo(4);
        if (context.mounted) {
          context.go('/');
        }
        break;

      case 'events':
        HomeTabController.goTo(6);
        if (context.mounted) {
          context.go('/');
        }
        break;

      case 'meals':
        if (context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const MealsPage(),
            ),
          );
        }
        break;

      case 'academic_section':
        HomeTabController.goTo(2);
        if (context.mounted) {
          context.go('/');
        }
        break;

      case 'administrative_section':
        HomeTabController.goTo(3);
        if (context.mounted) {
          context.go('/');
        }
        break;

      case 'profile':
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil bilgilerini bu sayfadan inceleyebilirsin.'),
            ),
          );
        }
        break;

      case 'refresh':
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sayfayı kapatıp yeniden açarak güncelleyebilirsin.'),
            ),
          );
        }
        break;

      default:
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(item.title)),
          );
        }
        break;
    }
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(
                      'assets/images/app_icon.png',
                      width: 78,
                      height: 78,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Munzur Mobil',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'v1.0.0',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Munzur Mobil, Munzur Üniversitesi’nin dijital dönüşüm sürecine katkı sağlamak amacıyla geliştirilmiş resmi bir mobil uygulamadır. Uygulama; duyurular, haberler, etkinlikler ve akademik bilgilere hızlı, güvenilir ve merkezi bir platform üzerinden erişim imkânı sunar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    height: 1.45,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Kapat'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }

  Widget _buildProgramCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String url,
    required Color color,
  }) {
    final hasUrl = url.trim().isNotEmpty;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(hasUrl ? subtitle : 'Henüz yayınlanmadı'),
        trailing: hasUrl ? const Icon(Icons.open_in_new) : null,
        enabled: hasUrl,
        onTap: hasUrl ? () => _openUrl(context, url) : null,
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }

  Widget _buildStudentAcademicProgramsSection(
      BuildContext context,
      Map<String, dynamic> userData,
      ) {
    final educationLevel = (userData['educationLevel'] ?? '').toString();
    final academicUnit = (userData['academicUnit'] ?? '').toString();
    final department = (userData['department'] ?? '').toString();

    if (educationLevel.isEmpty || academicUnit.isEmpty || department.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bana Özel Akademik İçerikler',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Bölüm bilgilerin eksik görünüyor. Ders ve sınav programlarının sana özel gösterilebilmesi için kullanıcı kaydında öğrenim düzeyi, birim ve bölüm bilgilerinin bulunması gerekir.',
              ),
              const SizedBox(height: 12),
              Text(
                'Mevcut durum:\n'
                    'Öğrenim Düzeyi: ${educationLevel.isEmpty ? '-' : educationLevel}\n'
                    'Birim: ${academicUnit.isEmpty ? '-' : academicUnit}\n'
                    'Bölüm/ABD: ${department.isEmpty ? '-' : department}',
              ),
            ],
          ),
        ),
      );
    }

    return FutureBuilder<AcademicProgram?>(
      future: _fetchProgram(userData),
      builder: (context, programSnapshot) {
        if (programSnapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Akademik program bilgileri alınamadı: ${programSnapshot.error}',
              ),
            ),
          );
        }

        if (programSnapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final program = programSnapshot.data;

        if (program == null) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bana Özel Akademik İçerikler',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Bu kullanıcı için eşleşen ders/sınav programı bulunamadı.\n\n'
                        'Öğrenim Düzeyi: $educationLevel\n'
                        'Birim: $academicUnit\n'
                        'Bölüm/ABD: $department',
                  ),
                  const SizedBox(height: 12),
                  _buildActionCard(
                    context: context,
                    icon: Icons.event_note_outlined,
                    title: 'Akademik Takvim',
                    subtitle: 'Akademik takvimi uygulama içinde görüntüle',
                    color: Colors.indigo,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AcademicCalendarPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bana Özel Akademik İçerikler',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text('Öğrenim Düzeyi: ${program.educationLevel}'),
                    Text('Birim: ${program.academicUnit}'),
                    Text('Bölüm/ABD: ${program.department}'),
                    if ((program.updatedAt ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Son Güncelleme: ${program.updatedAt}',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              context: context,
              icon: Icons.event_note_outlined,
              title: 'Akademik Takvim',
              subtitle: 'Akademik takvimi uygulama içinde görüntüle',
              color: Colors.indigo,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AcademicCalendarPage(),
                  ),
                );
              },
            ),
            _buildProgramCard(
              context: context,
              icon: Icons.calendar_month_outlined,
              title: 'Ders Programım',
              subtitle: 'Bölümüne özel haftalık ders programı',
              url: program.courseSchedulePdf,
              color: const Color(0xFF1D8FA3),
            ),
            _buildProgramCard(
              context: context,
              icon: Icons.edit_note_outlined,
              title: 'Vize Programım',
              subtitle: 'Ara sınav programını görüntüle',
              url: program.midtermPdf,
              color: Colors.orange,
            ),
            _buildProgramCard(
              context: context,
              icon: Icons.fact_check_outlined,
              title: 'Final Programım',
              subtitle: 'Final sınav programını görüntüle',
              url: program.finalPdf,
              color: Colors.green,
            ),
            _buildProgramCard(
              context: context,
              icon: Icons.refresh_outlined,
              title: 'Bütünleme Programım',
              subtitle: 'Bütünleme sınav programını görüntüle',
              url: program.makeupPdf,
              color: Colors.deepPurple,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStaffSection(
      BuildContext context,
      Map<String, dynamic> data,
      ) {
    final staffType = _valueOrDash(data['staffType']);
    final isAcademic = staffType == 'Akademik';
    final isAdministrative = staffType == 'İdari';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Personel İçerikleri',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  isAcademic
                      ? 'Bu alanda akademik takvim, fakülte/bölüm bağlantıları, duyurular ve etkinlikler gibi akademik personele yönelik içeriklere erişebilirsin.'
                      : isAdministrative
                      ? 'Bu alanda kurumsal bağlantılar, idari birim erişimleri, duyurular ve etkinlikler gibi idari personele yönelik içeriklere erişebilirsin.'
                      : 'Bu alanda akademik takvim, kurumsal bağlantılar, duyurular ve etkinlikler gibi personel için yararlı içeriklere erişebilirsin.',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          context: context,
          icon: Icons.event_note_outlined,
          title: 'Akademik Takvim',
          subtitle: 'Akademik takvimi uygulama içinde görüntüle',
          color: Colors.indigo,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const AcademicCalendarPage(),
              ),
            );
          },
        ),
        if (isAcademic)
          _buildActionCard(
            context: context,
            icon: Icons.account_balance_outlined,
            title: 'Akademik Birimler',
            subtitle:
            'Fakülte, enstitü ve akademik birim bağlantılarını incele',
            color: const Color(0xFF1D8FA3),
            onTap: () {
              HomeTabController.goTo(2);
              context.go('/');
            },
          ),
        if (isAdministrative)
          _buildActionCard(
            context: context,
            icon: Icons.apartment_outlined,
            title: 'İdari Birimler',
            subtitle: 'İdari birim ve kurumsal bağlantılara eriş',
            color: Colors.deepPurple,
            onTap: () {
              HomeTabController.goTo(3);
              context.go('/');
            },
          ),
        _buildActionCard(
          context: context,
          icon: Icons.campaign_outlined,
          title: 'Duyurular',
          subtitle: 'Üniversite duyurularını görüntüle',
          color: Colors.orange,
          onTap: () {
            HomeTabController.goTo(4);
            context.go('/');
          },
        ),
      ],
    );
  }

  Widget _buildStudentInfoCard(Map<String, dynamic> data) {
    final resolvedStudentNo = _resolveStudentNo(data);
    final classLabel = _studentClassLabel(data);
    final entryYear = resolvedStudentNo.isEmpty
        ? null
        : _extractEntryYearFromStudentNo(resolvedStudentNo);

    return Card(
      child: Column(
        children: [
          _buildInfoTile(
            icon: Icons.badge_outlined,
            title: 'Öğrenci Numarası',
            subtitle: resolvedStudentNo.isEmpty ? '-' : resolvedStudentNo,
          ),
          const Divider(height: 1),
          _buildInfoTile(
            icon: Icons.school_outlined,
            title: 'Tahmini Sınıf',
            subtitle: classLabel,
          ),
          const Divider(height: 1),
          _buildInfoTile(
            icon: Icons.calendar_today_outlined,
            title: 'Giriş Yılı',
            subtitle: entryYear?.toString() ?? '-',
          ),
          const Divider(height: 1),
          _buildInfoTile(
            icon: Icons.layers_outlined,
            title: 'Öğrenim Düzeyi',
            subtitle: _valueOrDash(data['educationLevel']),
          ),
          const Divider(height: 1),
          _buildInfoTile(
            icon: Icons.account_balance_outlined,
            title: 'Birim',
            subtitle: _valueOrDash(data['academicUnit']),
          ),
          const Divider(height: 1),
          _buildInfoTile(
            icon: Icons.apartment_outlined,
            title: 'Bölüm / ABD',
            subtitle: _valueOrDash(data['department']),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffInfoCard(Map<String, dynamic> data) {
    final staffType = _valueOrDash(data['staffType']);
    final isAcademic = staffType == 'Akademik';
    final isAdministrative = staffType == 'İdari';

    return Card(
      child: Column(
        children: [
          _buildInfoTile(
            icon: Icons.work_outline,
            title: 'Personel Türü',
            subtitle: staffType,
          ),
          const Divider(height: 1),
          if (isAcademic) ...[
            _buildInfoTile(
              icon: Icons.account_balance_outlined,
              title: 'Akademik Birim',
              subtitle: _valueOrDash(data['academicUnit']),
            ),
            const Divider(height: 1),
            _buildInfoTile(
              icon: Icons.apartment_outlined,
              title: 'Bölüm / ABD',
              subtitle: _valueOrDash(data['department']),
            ),
            const Divider(height: 1),
            _buildInfoTile(
              icon: Icons.workspace_premium_outlined,
              title: 'Ünvan',
              subtitle: _valueOrDash(data['academicTitle']),
            ),
            const Divider(height: 1),
          ],
          if (isAdministrative) ...[
            _buildInfoTile(
              icon: Icons.business_outlined,
              title: 'İdari Birim',
              subtitle: _valueOrDash(data['administrativeUnit']),
            ),
            const Divider(height: 1),
            _buildInfoTile(
              icon: Icons.badge_outlined,
              title: 'Kadro Türü',
              subtitle: _valueOrDash(data['employmentType']),
            ),
            const Divider(height: 1),
          ],
          if (!isAcademic && !isAdministrative) ...[
            _buildInfoTile(
              icon: Icons.account_balance_outlined,
              title: 'Birim',
              subtitle: _valueOrDash(data['academicUnit']),
            ),
            const Divider(height: 1),
            _buildInfoTile(
              icon: Icons.apartment_outlined,
              title: 'Görev / Bölüm',
              subtitle: _valueOrDash(data['department']),
            ),
            const Divider(height: 1),
          ],
          _buildInfoTile(
            icon: Icons.email_outlined,
            title: 'Kurumsal E-posta',
            subtitle: _valueOrDash(data['email']),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteAccountCard(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0x1AFF0000),
          child: Icon(
            Icons.delete_forever_outlined,
            color: Colors.red,
          ),
        ),
        title: const Text(
          'Delete Account',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: const Text(
          'Permanently delete your account and associated data',
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Colors.red,
        ),
        onTap: () => _showDeleteAccountConfirmation(context),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.lock_reset_outlined),
            title: const Text('Şifreni Değiştir'),
            subtitle: const Text('Hesabının giriş şifresini güncelle'),
            onTap: () => _showChangePasswordDialog(context),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Uygulama Hakkında'),
            subtitle: const Text('Munzur Mobil - Kampüs Cebinde'),
            onTap: () => _showAboutDialog(context),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Çıkış Yap',
              style: TextStyle(color: Colors.red),
            ),
            subtitle: const Text('Mevcut hesabından çıkış yap'),
            onTap: () async {
              await FirebaseAuth.instance.signOut();

              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(
        child: Text('Oturum bulunamadı.'),
      );
    }

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Bir hata oluştu: ${snapshot.error}'),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data?.data();

        if (data == null) {
          return const Center(
            child: Text('Kullanıcı bilgisi bulunamadı.'),
          );
        }

        final enrichedData = Map<String, dynamic>.from(data);
        final resolvedStudentNo = _resolveStudentNo(data);
        if (resolvedStudentNo.isNotEmpty) {
          enrichedData['studentNo'] = resolvedStudentNo;
        }

        final role = (enrichedData['role'] ?? 'student')
            .toString()
            .toLowerCase();
        final isStaff = role == 'staff';

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 38,
                      backgroundColor: const Color(0xFF1D8FA3),
                      child: Icon(
                        isStaff ? Icons.badge_outlined : Icons.person_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      (enrichedData['fullName'] ?? '').toString(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _valueOrDash(enrichedData['email']),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            _buildDeleteAccountCard(context),

            const SizedBox(height: 16),
            FutureBuilder<List<AiInsightItem>>(
              future: _buildAiInsights(enrichedData),
              builder: (context, aiSnapshot) {
                return AiInsightsCard(
                  insights: aiSnapshot.data ?? const [],
                  isLoading:
                  aiSnapshot.connectionState == ConnectionState.waiting,
                  error: aiSnapshot.hasError
                      ? aiSnapshot.error.toString()
                      : null,
                  onActionTap: (item) => _handleInsightAction(
                    context,
                    item,
                    enrichedData,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            if (isStaff)
              _buildStaffSection(context, enrichedData)
            else
              _buildStudentAcademicProgramsSection(context, enrichedData),
            const SizedBox(height: 16),
            if (isStaff)
              _buildStaffInfoCard(enrichedData)
            else
              _buildStudentInfoCard(enrichedData),
            const SizedBox(height: 16),
            _buildSettingsCard(context),
          ],
        );
      },
    );
  }
}