import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models/ai_insight_item.dart';

class AiInsightService {
  static const String _interactionStorageKey = 'ai_insight_interactions_v1';

  Future<List<AiInsightItem>> generateInsights({
    required Map<String, dynamic> userData,
    required bool hasAcademicCalendar,
    required bool hasMatchedProgram,
    required bool hasCourseSchedule,
    required bool hasMidterm,
    required bool hasFinal,
    required bool hasMakeup,
    required int announcementCount,
    required int eventCount,
    required bool hasMealToday,
    required String? ongoingAcademicEventTitle,
    required String? upcomingAcademicEventTitle,
    required int? upcomingAcademicEventDaysLeft,
    String? ongoingAcademicEventCategory,
    String? upcomingAcademicEventCategory,
  }) async {
    final role = (userData['role'] ?? 'student').toString().toLowerCase();
    final staffType = (userData['staffType'] ?? '').toString().trim();
    final interactionScores = await _loadInteractionScores();

    List<AiInsightItem> items;

    if (role == 'staff') {
      if (staffType == 'Akademik') {
        items = _buildAcademicStaffInsights(
          userData: userData,
          hasAcademicCalendar: hasAcademicCalendar,
          announcementCount: announcementCount,
          eventCount: eventCount,
          hasMealToday: hasMealToday,
          ongoingAcademicEventTitle: ongoingAcademicEventTitle,
          upcomingAcademicEventTitle: upcomingAcademicEventTitle,
          upcomingAcademicEventDaysLeft: upcomingAcademicEventDaysLeft,
          ongoingAcademicEventCategory: ongoingAcademicEventCategory,
          upcomingAcademicEventCategory: upcomingAcademicEventCategory,
        );
      } else if (staffType == 'İdari') {
        items = _buildAdministrativeStaffInsights(
          userData: userData,
          hasAcademicCalendar: hasAcademicCalendar,
          announcementCount: announcementCount,
          eventCount: eventCount,
          hasMealToday: hasMealToday,
          ongoingAcademicEventTitle: ongoingAcademicEventTitle,
          upcomingAcademicEventTitle: upcomingAcademicEventTitle,
          upcomingAcademicEventDaysLeft: upcomingAcademicEventDaysLeft,
          ongoingAcademicEventCategory: ongoingAcademicEventCategory,
          upcomingAcademicEventCategory: upcomingAcademicEventCategory,
        );
      } else {
        items = _buildGenericStaffInsights(
          userData: userData,
          hasAcademicCalendar: hasAcademicCalendar,
          announcementCount: announcementCount,
          eventCount: eventCount,
          hasMealToday: hasMealToday,
          ongoingAcademicEventTitle: ongoingAcademicEventTitle,
          upcomingAcademicEventTitle: upcomingAcademicEventTitle,
          upcomingAcademicEventDaysLeft: upcomingAcademicEventDaysLeft,
          ongoingAcademicEventCategory: ongoingAcademicEventCategory,
          upcomingAcademicEventCategory: upcomingAcademicEventCategory,
        );
      }
    } else {
      items = _buildStudentInsights(
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
        ongoingAcademicEventTitle: ongoingAcademicEventTitle,
        upcomingAcademicEventTitle: upcomingAcademicEventTitle,
        upcomingAcademicEventDaysLeft: upcomingAcademicEventDaysLeft,
        ongoingAcademicEventCategory: ongoingAcademicEventCategory,
        upcomingAcademicEventCategory: upcomingAcademicEventCategory,
      );
    }

    items = _applyTimeOfDayBoost(items);
    items = _applyInteractionBoost(items, interactionScores);
    items = _deduplicateInsights(items);
    items.sort((a, b) => b.priority.compareTo(a.priority));

    return items.take(6).toList();
  }

  static Future<void> recordInteraction(AiInsightItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_interactionStorageKey);

    Map<String, dynamic> decoded = {};
    if (raw != null && raw.isNotEmpty) {
      try {
        decoded = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {
        decoded = {};
      }
    }

    final actionType = item.actionType.trim();
    final category = item.category.trim().toLowerCase();

    final actionCount = (decoded[actionType] ?? 0) as int? ?? 0;
    decoded[actionType] = actionCount + 1;

    final categoryKey = 'cat_$category';
    final categoryCount = (decoded[categoryKey] ?? 0) as int? ?? 0;
    decoded[categoryKey] = categoryCount + 1;

    await prefs.setString(_interactionStorageKey, jsonEncode(decoded));
  }

  Future<Map<String, int>> _loadInteractionScores() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_interactionStorageKey);

    if (raw == null || raw.isEmpty) return {};

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
            (key, value) => MapEntry(key, (value as num).toInt()),
      );
    } catch (_) {
      return {};
    }
  }

  List<AiInsightItem> _buildAcademicStaffInsights({
    required Map<String, dynamic> userData,
    required bool hasAcademicCalendar,
    required int announcementCount,
    required int eventCount,
    required bool hasMealToday,
    required String? ongoingAcademicEventTitle,
    required String? upcomingAcademicEventTitle,
    required int? upcomingAcademicEventDaysLeft,
    required String? ongoingAcademicEventCategory,
    required String? upcomingAcademicEventCategory,
  }) {
    final items = <AiInsightItem>[];

    final academicTitle = (userData['academicTitle'] ?? '').toString().trim();
    final academicUnit = (userData['academicUnit'] ?? '').toString().trim();
    final department = (userData['department'] ?? '').toString().trim();

    _addCalendarInsights(
      items: items,
      hasAcademicCalendar: hasAcademicCalendar,
      ongoingAcademicEventTitle: ongoingAcademicEventTitle,
      upcomingAcademicEventTitle: upcomingAcademicEventTitle,
      upcomingAcademicEventDaysLeft: upcomingAcademicEventDaysLeft,
      ongoingAcademicEventCategory: ongoingAcademicEventCategory,
      upcomingAcademicEventCategory: upcomingAcademicEventCategory,
      defaultMessage:
      'Akademik takvimi düzenli kontrol ederek ders, sınav ve dönemsel süreçleri kaçırmaman faydalı olur.',
      defaultPriority: 90,
    );

    if (academicTitle.isEmpty) {
      items.add(
        const AiInsightItem(
          title: 'Akademik Ünvan Bilgin Eksik',
          message:
          'Ünvan bilgin profilinde eksik görünüyor. Sana daha hedefli akademik öneriler sunabilmem için profilini güncellemen faydalı olur.',
          category: 'Profil',
          actionLabel: 'Profili İncele',
          actionType: 'profile',
          priority: 97,
        ),
      );
    } else {
      items.add(
        AiInsightItem(
          title: _academicTitleInsightTitle(academicTitle),
          message: _academicTitleInsightMessage(academicTitle),
          category: 'Akademik',
          actionLabel: _academicTitleActionLabel(academicTitle),
          actionType: _academicTitleActionType(academicTitle),
          priority: _academicTitlePriority(academicTitle),
        ),
      );
    }

    if (academicUnit.isEmpty || department.isEmpty) {
      items.add(
        const AiInsightItem(
          title: 'Akademik Birim Bilgilerin Eksik',
          message:
          'Akademik birim veya bölüm bilgin eksik olduğu için sana uygun bağlantılar ve içerikler daha sınırlı gösteriliyor.',
          category: 'Profil',
          actionLabel: 'Bilgileri Güncelle',
          actionType: 'profile',
          priority: 95,
        ),
      );
    } else {
      items.add(
        AiInsightItem(
          title: 'Bölüm Sayfana Hızlı Eriş',
          message:
          '$academicUnit / $department için bölüm sayfası, akademik bağlantılar ve ilgili içeriklere doğrudan erişebilirsin.',
          category: 'Akademik',
          actionLabel: 'Bölüm Sayfasını Aç',
          actionType: 'department_page',
          priority: 86,
        ),
      );
    }

    if (announcementCount > 0) {
      items.add(
        AiInsightItem(
          title: 'Akademik ve Kurumsal Duyurular Var',
          message:
          'Sistemde $announcementCount duyuru görünüyor. Ders, sınav ve kurumsal süreçleri ilgilendiren içerikleri kontrol etmen yararlı olabilir.',
          category: 'Duyuru',
          actionLabel: 'Duyurulara Git',
          actionType: 'announcements',
          priority: 84,
        ),
      );
    }

    if (eventCount > 0) {
      items.add(
        AiInsightItem(
          title: 'Akademik Etkinlikleri İncele',
          message:
          'Sistemde $eventCount etkinlik kaydı bulunuyor. Seminer, panel veya akademik katılım gerektirebilecek etkinliklere göz atabilirsin.',
          category: 'Etkinlik',
          actionLabel: 'Etkinliklere Git',
          actionType: 'events',
          priority: 76,
        ),
      );
    }

    if (hasMealToday) {
      items.add(
        const AiInsightItem(
          title: 'Bugünün Yemek Listesi Hazır',
          message:
          'Yoğun gün planında kampüs içi zamanlamanı kolaylaştırmak için yemek listesini kontrol edebilirsin.',
          category: 'Yemek',
          actionLabel: 'Yemek Listesine Git',
          actionType: 'meals',
          priority: 64,
        ),
      );
    }

    return items;
  }

  List<AiInsightItem> _buildAdministrativeStaffInsights({
    required Map<String, dynamic> userData,
    required bool hasAcademicCalendar,
    required int announcementCount,
    required int eventCount,
    required bool hasMealToday,
    required String? ongoingAcademicEventTitle,
    required String? upcomingAcademicEventTitle,
    required int? upcomingAcademicEventDaysLeft,
    required String? ongoingAcademicEventCategory,
    required String? upcomingAcademicEventCategory,
  }) {
    final items = <AiInsightItem>[];

    final administrativeUnit =
    (userData['administrativeUnit'] ?? '').toString().trim();
    final employmentType =
    (userData['employmentType'] ?? '').toString().trim();

    _addCalendarInsights(
      items: items,
      hasAcademicCalendar: hasAcademicCalendar,
      ongoingAcademicEventTitle: ongoingAcademicEventTitle,
      upcomingAcademicEventTitle: upcomingAcademicEventTitle,
      upcomingAcademicEventDaysLeft: upcomingAcademicEventDaysLeft,
      ongoingAcademicEventCategory: ongoingAcademicEventCategory,
      upcomingAcademicEventCategory: upcomingAcademicEventCategory,
      defaultMessage:
      'Üniversite içi süreçleri ve dönemsel takvimi takip etmek için akademik takvime göz atman faydalı olabilir.',
      defaultPriority: 88,
    );

    if (employmentType.isEmpty) {
      items.add(
        const AiInsightItem(
          title: 'Kadro Türü Bilgin Eksik',
          message:
          'Kadro türün profilinde eksik görünüyor. Sana daha uygun idari öneriler gösterebilmem için bu alanı tamamlaman faydalı olur.',
          category: 'Profil',
          actionLabel: 'Profili İncele',
          actionType: 'profile',
          priority: 97,
        ),
      );
    } else {
      items.add(
        AiInsightItem(
          title: _employmentInsightTitle(employmentType),
          message: _employmentInsightMessage(employmentType),
          category: 'Kurumsal',
          actionLabel: 'İdari Bölümü Aç',
          actionType: 'administrative_section',
          priority: _employmentPriority(employmentType),
        ),
      );
    }

    if (administrativeUnit.isEmpty) {
      items.add(
        const AiInsightItem(
          title: 'İdari Birim Bilgin Eksik',
          message:
          'Bağlı olduğun idari birim bilgisi eksik olduğu için sana uygun kurumsal bağlantılar tam eşleşmiyor olabilir.',
          category: 'Profil',
          actionLabel: 'Bilgileri Güncelle',
          actionType: 'profile',
          priority: 95,
        ),
      );
    } else {
      items.add(
        AiInsightItem(
          title: 'İdari Birimine Hızlı Git',
          message:
          '$administrativeUnit için kurumsal bağlantılar ve birim içeriklerine hızlıca erişebilirsin.',
          category: 'Kurumsal',
          actionLabel: 'İdari Bölümü Aç',
          actionType: 'administrative_section',
          priority: 86,
        ),
      );
    }

    if (announcementCount > 0) {
      items.add(
        AiInsightItem(
          title: 'Kurumsal Duyurular Var',
          message:
          'Sistemde $announcementCount duyuru bulunuyor. Görev alanını ilgilendirebilecek güncellemeler için duyuruları incelemen faydalı olabilir.',
          category: 'Duyuru',
          actionLabel: 'Duyurulara Git',
          actionType: 'announcements',
          priority: 84,
        ),
      );
    }

    if (eventCount > 0) {
      items.add(
        AiInsightItem(
          title: 'Etkinlikleri Takip Et',
          message:
          'Sistemde $eventCount etkinlik bulunuyor. Üniversite içi sosyal ve kurumsal etkinlikleri inceleyebilirsin.',
          category: 'Etkinlik',
          actionLabel: 'Etkinliklere Git',
          actionType: 'events',
          priority: 72,
        ),
      );
    }

    if (hasMealToday) {
      items.add(
        const AiInsightItem(
          title: 'Bugünün Yemek Bilgisi Hazır',
          message:
          'Günlük kampüs planını yaparken yemek listesini kontrol etmen işini kolaylaştırabilir.',
          category: 'Yemek',
          actionLabel: 'Yemek Listesine Git',
          actionType: 'meals',
          priority: 66,
        ),
      );
    }

    return items;
  }

  List<AiInsightItem> _buildGenericStaffInsights({
    required Map<String, dynamic> userData,
    required bool hasAcademicCalendar,
    required int announcementCount,
    required int eventCount,
    required bool hasMealToday,
    required String? ongoingAcademicEventTitle,
    required String? upcomingAcademicEventTitle,
    required int? upcomingAcademicEventDaysLeft,
    required String? ongoingAcademicEventCategory,
    required String? upcomingAcademicEventCategory,
  }) {
    final items = <AiInsightItem>[];

    _addCalendarInsights(
      items: items,
      hasAcademicCalendar: hasAcademicCalendar,
      ongoingAcademicEventTitle: ongoingAcademicEventTitle,
      upcomingAcademicEventTitle: upcomingAcademicEventTitle,
      upcomingAcademicEventDaysLeft: upcomingAcademicEventDaysLeft,
      ongoingAcademicEventCategory: ongoingAcademicEventCategory,
      upcomingAcademicEventCategory: upcomingAcademicEventCategory,
      defaultMessage:
      'Önemli tarihler ve personeli ilgilendiren süreçler için akademik takvimi düzenli kontrol etmen yararlı olabilir.',
      defaultPriority: 88,
    );

    items.add(
      const AiInsightItem(
        title: 'Personel Bilgilerini Gözden Geçir',
        message:
        'Personel türün tam eşleşmediği için daha genel öneriler gösteriliyor. Profil bilgilerini güncellemen daha doğru yönlendirme sağlar.',
        category: 'Profil',
        actionLabel: 'Profili İncele',
        actionType: 'profile',
        priority: 92,
      ),
    );

    if (announcementCount > 0) {
      items.add(
        AiInsightItem(
          title: 'Güncel Duyurular Var',
          message:
          'Sistemde $announcementCount duyuru görünüyor. Kurumsal gelişmeleri takip etmek için inceleyebilirsin.',
          category: 'Duyuru',
          actionLabel: 'Duyurulara Git',
          actionType: 'announcements',
          priority: 82,
        ),
      );
    }

    if (eventCount > 0) {
      items.add(
        AiInsightItem(
          title: 'Etkinlikleri İncele',
          message:
          'Sistemde $eventCount etkinlik kaydı bulunuyor. Üniversite içi etkinlikleri inceleyebilirsin.',
          category: 'Etkinlik',
          actionLabel: 'Etkinliklere Git',
          actionType: 'events',
          priority: 70,
        ),
      );
    }

    if (hasMealToday) {
      items.add(
        const AiInsightItem(
          title: 'Yemek Listesini Kontrol Et',
          message:
          'Bugünün yemek listesi mevcut görünüyor. Günlük planın için göz atabilirsin.',
          category: 'Yemek',
          actionLabel: 'Yemek Listesine Git',
          actionType: 'meals',
          priority: 62,
        ),
      );
    }

    return items;
  }

  List<AiInsightItem> _buildStudentInsights({
    required Map<String, dynamic> userData,
    required bool hasAcademicCalendar,
    required bool hasMatchedProgram,
    required bool hasCourseSchedule,
    required bool hasMidterm,
    required bool hasFinal,
    required bool hasMakeup,
    required int announcementCount,
    required int eventCount,
    required bool hasMealToday,
    required String? ongoingAcademicEventTitle,
    required String? upcomingAcademicEventTitle,
    required int? upcomingAcademicEventDaysLeft,
    required String? ongoingAcademicEventCategory,
    required String? upcomingAcademicEventCategory,
  }) {
    final items = <AiInsightItem>[];

    final email = (userData['email'] ?? '').toString().trim();
    final educationLevel = (userData['educationLevel'] ?? '').toString().trim();
    final academicUnit = (userData['academicUnit'] ?? '').toString().trim();
    final department = (userData['department'] ?? '').toString().trim();

    final rawStudentNo = (userData['studentNo'] ?? '').toString().trim();
    final resolvedStudentNo = rawStudentNo.isNotEmpty
        ? rawStudentNo
        : _extractStudentNoFromEmail(email);

    final entryYear = _extractEntryYearFromStudentNo(resolvedStudentNo);
    final classYear = _estimateClassYearFromEntryYear(entryYear);

    final now = DateTime.now();
    final weekdayName = _weekdayName(now.weekday);

    if (resolvedStudentNo.isEmpty) {
      items.add(
        const AiInsightItem(
          title: 'Öğrenci Bilgin Doğrulanamadı',
          message:
          'Mail adresinden öğrenci numarası alınamadı. Profil bilgilerini kontrol ederek sana özel önerilerin daha doğru gösterilmesini sağlayabilirsin.',
          category: 'Profil',
          actionLabel: 'Profili İncele',
          actionType: 'profile',
          priority: 100,
        ),
      );
    } else {
      if (classYear != null) {
        items.add(
          AiInsightItem(
            title: _classYearTitle(classYear),
            message: _classYearMessage(classYear),
            category: 'Öğrenci',
            actionLabel: _classYearActionLabel(classYear),
            actionType: _classYearActionType(classYear),
            priority: _classYearPriority(classYear),
          ),
        );
      }
    }

    if (educationLevel.isEmpty || academicUnit.isEmpty || department.isEmpty) {
      items.add(
        const AiInsightItem(
          title: 'Akademik Bilgilerin Eksik',
          message:
          'Öğrenim düzeyi, birim veya bölüm bilgilerin eksik olduğu için sana özel akademik içerikler tam gösterilemiyor.',
          category: 'Akademik',
          actionLabel: 'Bilgileri Kontrol Et',
          actionType: 'profile',
          priority: 96,
        ),
      );
    } else {
      items.add(
        AiInsightItem(
          title: 'Bölüm Sayfasına Git',
          message:
          '$academicUnit / $department için akademik bağlantılar, birim sayfaları ve ilgili içeriklere Akademik sekmesinden ulaşabilirsin.',
          category: 'Akademik',
          actionLabel: 'Bölüm Sayfasına Git',
          actionType: 'department_page',
          priority: 72,
        ),
      );
    }

    if (ongoingAcademicEventTitle != null &&
        ongoingAcademicEventTitle.trim().isNotEmpty) {
      items.add(
        AiInsightItem(
          title: _calendarTitleFromCategory(
            ongoingAcademicEventCategory,
            fallback: 'Akademik Takvimde Aktif Süreç Var',
          ),
          message:
          '"$ongoingAcademicEventTitle" şu anda devam ediyor görünüyor. İlgili süreci kaçırmamak için akademik takvimi kontrol etmen faydalı olur.',
          category: 'Takvim',
          actionLabel: 'Takvimi Aç',
          actionType: 'academic_calendar',
          priority: 99,
        ),
      );
    } else if (upcomingAcademicEventTitle != null &&
        upcomingAcademicEventTitle.trim().isNotEmpty &&
        upcomingAcademicEventDaysLeft != null &&
        upcomingAcademicEventDaysLeft >= 0) {
      items.add(
        AiInsightItem(
          title: _calendarTitleFromCategory(
            upcomingAcademicEventCategory,
            fallback: 'Yaklaşan Akademik Süreç',
          ),
          message:
          '"$upcomingAcademicEventTitle" etkinliğine $upcomingAcademicEventDaysLeft gün kaldı. Planını buna göre yapman yararlı olabilir.',
          category: 'Takvim',
          actionLabel: 'Takvimi Aç',
          actionType: 'academic_calendar',
          priority: _priorityForUpcomingDays(upcomingAcademicEventDaysLeft),
        ),
      );
    } else if (hasAcademicCalendar) {
      items.add(
        AiInsightItem(
          title: 'Akademik Takvimi Kontrol Et',
          message:
          '$weekdayName günü için plan yapmadan önce önemli tarihler ve akademik süreçleri kontrol etmen faydalı olur.',
          category: 'Takvim',
          actionLabel: 'Takvimi Aç',
          actionType: 'academic_calendar',
          priority: 90,
        ),
      );
    }

    if (!hasMatchedProgram) {
      items.add(
        const AiInsightItem(
          title: 'Program Eşleşmesi Bulunamadı',
          message:
          'Bölümüne ait ders veya sınav programı eşleşmedi. Bölüm adının sistemde doğru tanımlandığını kontrol etmelisin.',
          category: 'Akademik',
          actionLabel: 'Bilgileri Kontrol Et',
          actionType: 'profile',
          priority: 92,
        ),
      );
    } else {
      if (hasCourseSchedule) {
        items.add(
          const AiInsightItem(
            title: 'Ders Programın Hazır',
            message:
            'Haftalık ders planını görmek ve gününü organize etmek için ders programını inceleyebilirsin.',
            category: 'Ders',
            actionLabel: 'Ders Programını Aç',
            actionType: 'course_schedule',
            priority: 88,
          ),
        );
      }

      if (hasMidterm) {
        items.add(
          const AiInsightItem(
            title: 'Vize Programın Mevcut',
            message:
            'Yaklaşan sınavlarını kaçırmamak için vize programını önceden incelemen yararlı olabilir.',
            category: 'Sınav',
            actionLabel: 'Vize Programını Aç',
            actionType: 'midterm',
            priority: 82,
          ),
        );
      }

      if (hasFinal) {
        items.add(
          const AiInsightItem(
            title: 'Final Programın Hazır',
            message:
            'Final sürecini planlamak için sınav tarihlerini erkenden kontrol etmen faydalı olur.',
            category: 'Sınav',
            actionLabel: 'Final Programını Aç',
            actionType: 'final',
            priority: 80,
          ),
        );
      }

      if (hasMakeup) {
        items.add(
          const AiInsightItem(
            title: 'Bütünleme Bilgilerini Kontrol Et',
            message:
            'Bütünleme sınavı bağlantıları mevcut görünüyor. Gerekli durumlar için önceden incelemen yararlı olabilir.',
            category: 'Sınav',
            actionLabel: 'Bütünleme Programını Aç',
            actionType: 'makeup',
            priority: 76,
          ),
        );
      }

      if (!hasMidterm && !hasFinal && !hasMakeup) {
        items.add(
          const AiInsightItem(
            title: 'Sınav Programları Henüz Görünmüyor',
            message:
            'Vize, final veya bütünleme bağlantıları şu anda mevcut değil. Uygulamayı düzenli takip etmen önerilir.',
            category: 'Sınav',
            actionLabel: 'Akademik Bölümü Gör',
            actionType: 'academic_section',
            priority: 66,
          ),
        );
      }
    }

    if (announcementCount > 0) {
      items.add(
        AiInsightItem(
          title: 'Yeni Duyurular Var',
          message:
          'Sistemde $announcementCount güncel duyuru görünüyor. Üniversitedeki yeni gelişmeleri kaçırmamak için incelemen faydalı olur.',
          category: 'Duyuru',
          actionLabel: 'Duyurulara Git',
          actionType: 'announcements',
          priority: 84,
        ),
      );
    }

    if (eventCount > 0) {
      items.add(
        AiInsightItem(
          title: 'Etkinlikleri İncele',
          message:
          'Sistemde $eventCount etkinlik kaydı bulunuyor. İlgini çeken akademik veya sosyal etkinlikleri inceleyebilirsin.',
          category: 'Etkinlik',
          actionLabel: 'Etkinliklere Git',
          actionType: 'events',
          priority: 78,
        ),
      );
    }

    if (hasMealToday) {
      items.add(
        const AiInsightItem(
          title: 'Günün Yemeği Hazır',
          message:
          'Bugünün yemek listesi görüntülenebiliyor. Kampüs planını yapmadan önce menüye göz atabilirsin.',
          category: 'Yemek',
          actionLabel: 'Yemek Listesine Git',
          actionType: 'meals',
          priority: 74,
        ),
      );
    }

    return items;
  }

  void _addCalendarInsights({
    required List<AiInsightItem> items,
    required bool hasAcademicCalendar,
    required String? ongoingAcademicEventTitle,
    required String? upcomingAcademicEventTitle,
    required int? upcomingAcademicEventDaysLeft,
    required String? ongoingAcademicEventCategory,
    required String? upcomingAcademicEventCategory,
    required String defaultMessage,
    required int defaultPriority,
  }) {
    if (ongoingAcademicEventTitle != null &&
        ongoingAcademicEventTitle.trim().isNotEmpty) {
      items.add(
        AiInsightItem(
          title: _calendarTitleFromCategory(
            ongoingAcademicEventCategory,
            fallback: 'Takvimde Aktif Süreç Var',
          ),
          message:
          '"$ongoingAcademicEventTitle" şu anda devam ediyor. İlgili süreci kaçırmamak için takvimi kontrol etmen faydalı olabilir.',
          category: 'Takvim',
          actionLabel: 'Takvimi Aç',
          actionType: 'academic_calendar',
          priority: 99,
        ),
      );
      return;
    }

    if (upcomingAcademicEventTitle != null &&
        upcomingAcademicEventTitle.trim().isNotEmpty &&
        upcomingAcademicEventDaysLeft != null &&
        upcomingAcademicEventDaysLeft >= 0) {
      items.add(
        AiInsightItem(
          title: _calendarTitleFromCategory(
            upcomingAcademicEventCategory,
            fallback: 'Yaklaşan Takvim Süreci',
          ),
          message:
          '"$upcomingAcademicEventTitle" etkinliğine $upcomingAcademicEventDaysLeft gün kaldı. Planlamanı buna göre gözden geçirmen yararlı olabilir.',
          category: 'Takvim',
          actionLabel: 'Takvimi Aç',
          actionType: 'academic_calendar',
          priority: _priorityForUpcomingDays(upcomingAcademicEventDaysLeft),
        ),
      );
      return;
    }

    if (hasAcademicCalendar) {
      items.add(
        AiInsightItem(
          title: 'Takvimi Kontrol Et',
          message: defaultMessage,
          category: 'Takvim',
          actionLabel: 'Takvimi Aç',
          actionType: 'academic_calendar',
          priority: defaultPriority,
        ),
      );
    }
  }

  List<AiInsightItem> _applyTimeOfDayBoost(List<AiInsightItem> items) {
    final hour = DateTime.now().hour;

    return items
        .map((item) {
      int boost = 0;

      if (hour < 11) {
        if (item.category == 'Takvim' ||
            item.category == 'Ders' ||
            item.category == 'Sınav') {
          boost += 6;
        }
      } else if (hour < 15) {
        if (item.category == 'Yemek') boost += 8;
        if (item.category == 'Duyuru') boost += 2;
      } else {
        if (item.category == 'Duyuru' || item.category == 'Etkinlik') {
          boost += 4;
        }
      }

      return _copyWithPriority(item, item.priority + boost);
    })
        .toList();
  }

  List<AiInsightItem> _applyInteractionBoost(
      List<AiInsightItem> items,
      Map<String, int> interactionScores,
      ) {
    return items.map((item) {
      final actionScore = interactionScores[item.actionType] ?? 0;
      final categoryScore =
          interactionScores['cat_${item.category.toLowerCase()}'] ?? 0;

      final boost = (actionScore * 2) + categoryScore;
      final cappedBoost = boost > 12 ? 12 : boost;

      return _copyWithPriority(item, item.priority + cappedBoost);
    }).toList();
  }

  List<AiInsightItem> _deduplicateInsights(List<AiInsightItem> items) {
    final Map<String, AiInsightItem> byAction = {};
    final Map<String, AiInsightItem> bySemanticGroup = {};

    for (final item in items) {
      final existingByAction = byAction[item.actionType];
      if (existingByAction == null || item.priority > existingByAction.priority) {
        byAction[item.actionType] = item;
      }
    }

    for (final item in byAction.values) {
      final group = _semanticGroup(item);
      final existing = bySemanticGroup[group];
      if (existing == null || item.priority > existing.priority) {
        bySemanticGroup[group] = item;
      }
    }

    return bySemanticGroup.values.toList();
  }

  String _semanticGroup(AiInsightItem item) {
    if (item.actionType == 'midterm' ||
        item.actionType == 'final' ||
        item.actionType == 'makeup') {
      return 'exam';
    }

    if (item.actionType == 'department_page' ||
        item.actionType == 'academic_section') {
      return 'academic_navigation';
    }

    if (item.actionType == 'administrative_section') {
      return 'administrative_navigation';
    }

    if (item.actionType == 'academic_calendar') {
      return 'calendar';
    }

    return item.actionType;
  }

  AiInsightItem _copyWithPriority(AiInsightItem item, int newPriority) {
    return AiInsightItem(
      title: item.title,
      message: item.message,
      category: item.category,
      actionLabel: item.actionLabel,
      actionType: item.actionType,
      priority: newPriority,
    );
  }

  String _calendarTitleFromCategory(String? category, {required String fallback}) {
    switch ((category ?? '').toLowerCase()) {
      case 'registration':
        return 'Kayıt Süreci Yaklaşıyor';
      case 'course':
        return 'Ders Süreci Takvimde Öne Çıkıyor';
      case 'exammidterm':
        return 'Vize Süreci Yaklaşıyor';
      case 'examfinal':
        return 'Final Süreci Yaklaşıyor';
      case 'exammakeup':
        return 'Bütünleme Süreci Yaklaşıyor';
      case 'graduation':
        return 'Mezuniyet Süreci Yaklaşıyor';
      case 'holiday':
        return 'Takvimde Tatil Dönemi Var';
      case 'administrative':
        return 'İdari Süreç Takvimde Öne Çıkıyor';
      default:
        return fallback;
    }
  }

  String _academicTitleInsightTitle(String academicTitle) {
    if (academicTitle.contains('Arş. Gör')) {
      return 'Araştırma Görevlisi İçin Öneri';
    }
    if (academicTitle.contains('Öğr. Gör')) {
      return 'Öğretim Görevlisi İçin Öneri';
    }
    if (academicTitle.contains('Dr. Öğr. Üyesi')) {
      return 'Dr. Öğr. Üyesi İçin Öneri';
    }
    if (academicTitle.contains('Doç. Dr.')) {
      return 'Doçent İçin Öneri';
    }
    if (academicTitle.contains('Prof. Dr.')) {
      return 'Profesör İçin Öneri';
    }
    return 'Akademik Personel İçin Öneri';
  }

  String _academicTitleInsightMessage(String academicTitle) {
    if (academicTitle.contains('Arş. Gör')) {
      return 'Sınav dönemleri, bölüm duyuruları ve akademik takvimi düzenli takip etmen günlük akademik iş akışını kolaylaştırabilir.';
    }
    if (academicTitle.contains('Öğr. Gör')) {
      return 'Ders planlaması, sınav süreçleri ve akademik takvimi birlikte takip etmen dönem içindeki iş akışını daha rahat yönetmeni sağlar.';
    }
    if (academicTitle.contains('Dr. Öğr. Üyesi')) {
      return 'Akademik takvim, kurumsal duyurular ve bölümündeki güncel gelişmeleri birlikte takip etmen yararlı olabilir.';
    }
    if (academicTitle.contains('Doç. Dr.')) {
      return 'Akademik süreçler, güncel duyurular ve üniversite etkinliklerini birlikte takip ederek dönemsel planlamanı daha rahat yapabilirsin.';
    }
    if (academicTitle.contains('Prof. Dr.')) {
      return 'Akademik takvim, üniversite duyuruları ve etkinlikler kurumsal ve akademik planlama açısından öncelikli olabilir.';
    }
    return 'Akademik takvim, duyurular ve üniversite içi gelişmeleri düzenli takip etmen faydalı olabilir.';
  }

  String _academicTitleActionLabel(String academicTitle) {
    if (academicTitle.contains('Arş. Gör')) return 'Takvimi Aç';
    if (academicTitle.contains('Öğr. Gör')) return 'Takvimi Aç';
    if (academicTitle.contains('Dr. Öğr. Üyesi')) return 'Duyurulara Git';
    if (academicTitle.contains('Doç. Dr.')) return 'Etkinliklere Git';
    if (academicTitle.contains('Prof. Dr.')) return 'Duyurulara Git';
    return 'Takvimi Aç';
  }

  String _academicTitleActionType(String academicTitle) {
    if (academicTitle.contains('Arş. Gör')) return 'academic_calendar';
    if (academicTitle.contains('Öğr. Gör')) return 'academic_calendar';
    if (academicTitle.contains('Dr. Öğr. Üyesi')) return 'announcements';
    if (academicTitle.contains('Doç. Dr.')) return 'events';
    if (academicTitle.contains('Prof. Dr.')) return 'announcements';
    return 'academic_calendar';
  }

  int _academicTitlePriority(String academicTitle) {
    if (academicTitle.contains('Arş. Gör')) return 91;
    if (academicTitle.contains('Öğr. Gör')) return 90;
    if (academicTitle.contains('Dr. Öğr. Üyesi')) return 89;
    if (academicTitle.contains('Doç. Dr.')) return 88;
    if (academicTitle.contains('Prof. Dr.')) return 87;
    return 86;
  }

  String _employmentInsightTitle(String employmentType) {
    if (employmentType.contains('Genel İdari Hizmetler')) {
      return 'Kurumsal Süreçleri Takip Et';
    }
    if (employmentType.contains('Teknik Hizmetler')) {
      return 'Teknik Birim İçeriklerini Kontrol Et';
    }
    if (employmentType.contains('Sağlık Hizmetleri')) {
      return 'Sağlık ve Kurumsal Duyuruları Takip Et';
    }
    if (employmentType.contains('Avukatlık Hizmetleri')) {
      return 'Kurumsal Güncellemeleri Gözden Geçir';
    }
    if (employmentType.contains('Yardımcı Hizmetler')) {
      return 'Günlük Kurumsal Akışı Kontrol Et';
    }
    if (employmentType.contains('Sözleşmeli Personel')) {
      return 'Güncel Duyuruları ve Birim Bilgilerini İncele';
    }
    if (employmentType.contains('Sürekli İşçi')) {
      return 'Günlük Kampüs Akışını Takip Et';
    }
    return 'İdari Personel İçin Öneri';
  }

  String _employmentInsightMessage(String employmentType) {
    if (employmentType.contains('Genel İdari Hizmetler')) {
      return 'Kurumsal duyurular, idari bağlantılar ve dönemsel süreçler senin için daha öncelikli olabilir.';
    }
    if (employmentType.contains('Teknik Hizmetler')) {
      return 'Teknik süreçleri etkileyebilecek kurumsal duyurular ve kampüs içi gelişmeleri düzenli takip etmen yararlı olabilir.';
    }
    if (employmentType.contains('Sağlık Hizmetleri')) {
      return 'Kurumsal bilgilendirmeler, etkinlikler ve günlük kampüs akışı iş planlamanı destekleyebilir.';
    }
    if (employmentType.contains('Avukatlık Hizmetleri')) {
      return 'Kurumsal duyurular ve idari yapıdaki güncellemeler görev alanın açısından önem taşıyabilir.';
    }
    if (employmentType.contains('Yardımcı Hizmetler')) {
      return 'Günlük kurumsal akış, yemek bilgisi ve duyurular kampüs içi planlamanı kolaylaştırabilir.';
    }
    if (employmentType.contains('Sözleşmeli Personel')) {
      return 'Kurumsal duyurular ve bağlı olduğun birime ait içerikleri birlikte takip etmen faydalı olabilir.';
    }
    if (employmentType.contains('Sürekli İşçi')) {
      return 'Günlük kampüs düzeni, yemek listesi ve duyurular pratik açıdan sana daha çok fayda sağlayabilir.';
    }
    return 'Kurumsal duyurular ve bağlı olduğun birime ait içerikleri takip etmen faydalı olabilir.';
  }

  int _employmentPriority(String employmentType) {
    if (employmentType.contains('Genel İdari Hizmetler')) return 91;
    if (employmentType.contains('Teknik Hizmetler')) return 89;
    if (employmentType.contains('Sağlık Hizmetleri')) return 88;
    if (employmentType.contains('Avukatlık Hizmetleri')) return 88;
    if (employmentType.contains('Yardımcı Hizmetler')) return 86;
    if (employmentType.contains('Sözleşmeli Personel')) return 87;
    if (employmentType.contains('Sürekli İşçi')) return 85;
    return 84;
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

  int? _extractEntryYearFromStudentNo(String studentNo) {
    if (studentNo.length < 2) return null;

    final yearPrefix = int.tryParse(studentNo.substring(0, 2));
    if (yearPrefix == null) return null;

    final fullYear = 2000 + yearPrefix;

    if (fullYear < 2000 || fullYear > DateTime.now().year + 1) {
      return null;
    }

    return fullYear;
  }

  int? _estimateClassYearFromEntryYear(int? entryYear) {
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

  int _priorityForUpcomingDays(int days) {
    if (days <= 1) return 98;
    if (days <= 3) return 96;
    if (days <= 7) return 94;
    return 90;
  }

  String _classYearTitle(int classYear) {
    if (classYear <= 1) return '1. Sınıf Öğrencisi İçin Öneri';
    if (classYear >= 4) return 'Üst Sınıf Öğrencisi İçin Öneri';
    return '$classYear. Sınıf Öğrencisi İçin Öneri';
  }

  String _classYearMessage(int classYear) {
    if (classYear <= 1) {
      return 'Üniversiteye yeni başladığın için akademik takvimi, bölüm sayfanı ve ders programını düzenli kontrol etmen uyum sürecini kolaylaştırabilir.';
    }
    if (classYear >= 4) {
      return 'Son sınıf veya üstü bir öğrenci olarak final, bütünleme ve mezuniyet sürecine ilişkin duyuru ve takvimleri yakından takip etmen faydalı olabilir.';
    }
    return 'Ders programın, sınav belgelerin ve akademik takvimini birlikte takip etmen dönem planlamanı daha kolay yapmanı sağlar.';
  }

  String _classYearActionLabel(int classYear) {
    if (classYear <= 1) return 'Akademik Bölümü Aç';
    if (classYear >= 4) return 'Takvimi Aç';
    return 'Ders Programını Aç';
  }

  String _classYearActionType(int classYear) {
    if (classYear <= 1) return 'academic_section';
    if (classYear >= 4) return 'academic_calendar';
    return 'course_schedule';
  }

  int _classYearPriority(int classYear) {
    if (classYear <= 1) return 89;
    if (classYear >= 4) return 87;
    return 85;
  }

  String _weekdayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Pazartesi';
      case 2:
        return 'Salı';
      case 3:
        return 'Çarşamba';
      case 4:
        return 'Perşembe';
      case 5:
        return 'Cuma';
      case 6:
        return 'Cumartesi';
      case 7:
        return 'Pazar';
      default:
        return 'Bugün';
    }
  }
}