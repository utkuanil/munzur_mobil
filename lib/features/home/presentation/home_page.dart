import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/navigation/home_tab_controller.dart';
import '../../announcements/presentation/announcements_page.dart';
import '../../events/presentation/events_page.dart';
import '../../external/data/munzur_site_service.dart';
import '../../meals/presentation/meals_page.dart';
import '../../news/presentation/news_page.dart';
import '../data/menu_service.dart';
import '../data/models/menu_item_model.dart';
import 'widgets/section_title.dart';

class HomePage extends StatefulWidget {
  final VoidCallback onOpenModules;
  final VoidCallback onOpenPersonal;

  const HomePage({
    super.key,
    required this.onOpenModules,
    required this.onOpenPersonal,
  });

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  late final Future<List<MenuSectionModel>> _universityMenuFuture;
  late final Future<List<MenuSectionModel>> _academicMenuFuture;
  late final Future<List<MenuSectionModel>> _administrativeMenuFuture;
  late final Future<List<Map<String, String>>> _mealsFuture;
  late final Future<DocumentSnapshot<Map<String, dynamic>>> _userFuture;

  final MenuService _menuService = MenuService();
  final MunzurSiteService _siteService = MunzurSiteService();

  void _listenExternalTabChanges() {
    HomeTabController.selectedTab.addListener(_handleExternalTabChange);
  }

  void _handleExternalTabChange() {
    final index = HomeTabController.selectedTab.value;

    if (!mounted) return;
    if (index < 0 || index >= _tabController.length) return;

    if (_tabController.index != index) {
      _tabController.animateTo(index);
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);

    _universityMenuFuture = _menuService.fetchUniversityMenu();
    _academicMenuFuture = _menuService.fetchAcademicMenu();
    _administrativeMenuFuture = _menuService.fetchAdministrativeMenu();
    _mealsFuture = _siteService.fetchMeals();
    _listenExternalTabChanges();
    _syncInitialTabFromController();

    final user = FirebaseAuth.instance.currentUser;
    _userFuture = FirebaseFirestore.instance
        .collection('users')
        .doc(user?.uid)
        .get();
  }

  void goToMainTab() {
    if (!_tabController.indexIsChanging) {
      _tabController.animateTo(0);
    } else {
      _tabController.index = 0;
    }
  }

  void _syncInitialTabFromController() {
    final index = HomeTabController.selectedTab.value;

    if (index < 0 || index >= _tabController.length) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_tabController.index != index) {
        _tabController.animateTo(index);
      }
    });
  }

  @override
  void dispose() {
    HomeTabController.selectedTab.removeListener(_handleExternalTabChange);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return;

    final uri = Uri.tryParse(trimmed);
    if (uri == null) return;

    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bağlantı açılamadı.')),
      );
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

  Map<String, String>? _findBestMealForHome(List<Map<String, String>> meals) {
    if (meals.isEmpty) return null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    Map<String, String>? exactToday;
    Map<String, String>? nearestFuture;
    DateTime? nearestFutureDate;
    Map<String, String>? latestPast;
    DateTime? latestPastDate;

    for (final meal in meals) {
      final rawDate = (meal['date'] ?? '').trim();
      final parsed = _parseMealDate(rawDate);
      if (parsed == null) continue;

      final dateOnly = DateTime(parsed.year, parsed.month, parsed.day);

      if (dateOnly == today) {
        exactToday = meal;
        break;
      }

      if (dateOnly.isAfter(today)) {
        if (nearestFutureDate == null || dateOnly.isBefore(nearestFutureDate)) {
          nearestFutureDate = dateOnly;
          nearestFuture = meal;
        }
      } else {
        if (latestPastDate == null || dateOnly.isAfter(latestPastDate)) {
          latestPastDate = dateOnly;
          latestPast = meal;
        }
      }
    }

    return exactToday ?? nearestFuture ?? latestPast ?? meals.first;
  }

  Widget _buildShortcutCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F6F8),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: const Color(0xFF1D8FA3)),
        ),
        title: Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            subtitle,
            style: const TextStyle(fontSize: 13),
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _socialIcon({
    required IconData icon,
    required Color color,
    required String url,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _openUrl(url),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: FaIcon(
            icon,
            color: color,
            size: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildSocialFooter() {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _socialIcon(
            icon: FontAwesomeIcons.facebookF,
            color: const Color(0xFF1877F2),
            url: 'https://www.facebook.com/UniMunzur/',
          ),
          const SizedBox(width: 16),
          _socialIcon(
            icon: FontAwesomeIcons.instagram,
            color: const Color(0xFFE1306C),
            url: 'https://www.instagram.com/munzur.university',
          ),
          const SizedBox(width: 16),
          _socialIcon(
            icon: FontAwesomeIcons.xTwitter,
            color: Colors.black,
            url: 'https://x.com/munzuruniv',
          ),
        ],
      ),
    );
  }

  Widget _buildMealPreviewCard(BuildContext context, Map<String, String> meal) {
    final date = meal['date'] ?? '';
    final calorie = (meal['calorie'] ?? '').trim();
    final meal1 = meal['meal1'] ?? '';
    final meal2 = meal['meal2'] ?? '';
    final meal3 = meal['meal3'] ?? '';
    final meal4 = meal['meal4'] ?? '';

    final normalizedCalorie = calorie.toLowerCase().trim();
    final showCalorie = calorie.isNotEmpty &&
        normalizedCalorie != 'kcal' &&
        normalizedCalorie != 'kalori' &&
        normalizedCalorie != '-' &&
        normalizedCalorie != ':';

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const MealsPage(),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F6F7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8EA)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x11000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              date,
              style: const TextStyle(
                color: Color(0xFF1D8FA3),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            if (showCalorie) ...[
              const SizedBox(height: 6),
              Text(
                'Kalori: $calorie',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (meal1.isNotEmpty) ...[
              Text('1. Yemek: $meal1'),
              const SizedBox(height: 6),
            ],
            if (meal2.isNotEmpty) ...[
              Text('2. Yemek: $meal2'),
              const SizedBox(height: 6),
            ],
            if (meal3.isNotEmpty) ...[
              Text('3. Yemek: $meal3'),
              const SizedBox(height: 6),
            ],
            if (meal4.isNotEmpty) ...[
              Text('4. Yemek: $meal4'),
              const SizedBox(height: 6),
            ],
            const SizedBox(height: 10),
            const Text(
              'Aylık yemek listesini görmek için dokun',
              style: TextStyle(
                color: Color(0xFF1D8FA3),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader({
    required String role,
  }) {
    final user = FirebaseAuth.instance.currentUser;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user?.uid).get(),
      builder: (context, snapshot) {
        String name = role == 'staff' ? 'Personel' : 'Öğrenci';

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          name = (data['fullName'] ?? name).toString();
        }

        return Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF0F6070),
                Color(0xFF33A6B8),
                Color(0xFF6DD5ED),
              ],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hoş geldin',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 6),
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                role == 'staff'
                    ? 'Bugün seni hangi kurumsal içerikler bekliyor?'
                    : 'Bugün seni neler bekliyor?',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDynamicLeaf(MenuItemModel item) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(item.title),
      trailing: item.url != null && item.url!.trim().isNotEmpty
          ? const Icon(Icons.chevron_right_rounded, size: 18)
          : null,
      onTap: (item.url != null && item.url!.trim().isNotEmpty)
          ? () => _openUrl(item.url!)
          : null,
    );
  }

  Widget _buildDynamicItem(MenuItemModel item) {
    if (item.hasChildren) {
      return ExpansionTile(
        title: Text(item.title),
        childrenPadding: const EdgeInsets.only(left: 12, right: 12),
        children: item.children.map(_buildDynamicItem).toList(),
      );
    }

    return _buildDynamicLeaf(item);
  }

  Widget _buildDynamicMenuSection(
      MenuSectionModel section, {
        required IconData icon,
        bool initiallyExpanded = false,
      }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        leading: Icon(icon, color: const Color(0xFF1D8FA3)),
        title: Text(
          section.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        children: section.items.map(_buildDynamicItem).toList(),
      ),
    );
  }

  IconData _universitySectionIcon(String title) {
    final normalized = title.toLowerCase().trim();

    if (normalized.contains('genel')) return Icons.public_outlined;
    if (normalized.contains('yönetim') || normalized.contains('yonetim')) {
      return Icons.account_balance_outlined;
    }
    if (normalized.contains('öğrenci') || normalized.contains('ogrenci')) {
      return Icons.school_outlined;
    }
    if (normalized.contains('araştırma') || normalized.contains('arastirma')) {
      return Icons.science_outlined;
    }
    return Icons.category_outlined;
  }

  Color _universitySectionColor(String title) {
    final normalized = title.toLowerCase().trim();

    if (normalized.contains('genel')) return const Color(0xFF1D8FA3);
    if (normalized.contains('yönetim') || normalized.contains('yonetim')) {
      return const Color(0xFF7C4DFF);
    }
    if (normalized.contains('öğrenci') || normalized.contains('ogrenci')) {
      return const Color(0xFF00A86B);
    }
    if (normalized.contains('araştırma') || normalized.contains('arastirma')) {
      return const Color(0xFFFF8F00);
    }
    return const Color(0xFF546E7A);
  }

  Widget _buildUniversitySectionCard(
      BuildContext context,
      MenuSectionModel section,
      ) {
    final color = _universitySectionColor(section.title);
    final icon = _universitySectionIcon(section.title);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5ECEF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 14),
            Text(
              section.title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            ...section.items.map(
                  (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: (item.url ?? '').trim().isNotEmpty
                      ? () => _openUrl(item.url!)
                      : null,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Icon(
                          Icons.circle,
                          size: 6,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.35,
                            color: (item.url ?? '').trim().isNotEmpty
                                ? const Color(0xFF2D3A40)
                                : Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUniversityTab() {
    return FutureBuilder<List<MenuSectionModel>>(
      future: _universityMenuFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Üniversitemiz menüsü alınamadı: ${snapshot.error}'),
                ),
              ),
            ],
          );
        }

        final sections = snapshot.data ?? [];

        if (sections.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Üniversitemiz menüsü bulunamadı.'),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: sections.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            return _buildUniversitySectionCard(context, sections[index]);
          },
        );
      },
    );
  }

  Widget _buildStudentHomeTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildWelcomeHeader(role: 'student'),
        const SizedBox(height: 24),
        const SectionTitle(title: 'Bana Özel'),
        const SizedBox(height: 10),
        _buildShortcutCard(
          icon: Icons.person_rounded,
          title: 'Ders & Sınav Programım',
          subtitle:
          'Bölümüne özel ders, vize, final ve bütünleme programlarını görüntüle',
          colors: const [
            Color(0xFF145C69),
            Color(0xFF1D8FA3),
            Color(0xFF4DB6C8),
          ],
          onTap: widget.onOpenPersonal,
        ),
        const SizedBox(height: 24),
        const SectionTitle(title: 'Günün Yemeği'),
        const SizedBox(height: 10),
        FutureBuilder<List<Map<String, String>>>(
          future: _mealsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Yemek listesi alınamadı: ${snapshot.error}'),
                ),
              );
            }

            final meals = snapshot.data ?? [];

            if (meals.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Yemek listesi bulunamadı.'),
                ),
              );
            }

            final meal = _findBestMealForHome(meals);

            if (meal == null) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Bugüne uygun yemek listesi bulunamadı.'),
                ),
              );
            }

            return _buildMealPreviewCard(context, meal);
          },
        ),
        _buildSocialFooter(),
      ],
    );
  }

  Widget _buildStaffHomeTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildWelcomeHeader(role: 'staff'),
        const SizedBox(height: 24),
        const SectionTitle(title: 'Personel Hızlı Erişim'),
        const SizedBox(height: 10),
        _buildShortcutCard(
          icon: Icons.badge_outlined,
          title: 'Kurumsal Bağlantılar',
          subtitle:
          'İdari birimler, akademik sayfalar ve kurumsal hizmetlere hızlı eriş',
          colors: const [
            Color(0xFF5B3F8C),
            Color(0xFF7C4DFF),
            Color(0xFF9C7BFF),
          ],
          onTap: widget.onOpenModules,
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          icon: Icons.event_note_outlined,
          title: 'Akademik Takvim',
          subtitle: 'Akademik süreçleri ve önemli tarihleri takip et',
          onTap: widget.onOpenPersonal,
        ),
        _buildInfoCard(
          icon: Icons.campaign_outlined,
          title: 'Duyurular',
          subtitle: 'Kurumsal ve güncel duyuruları incele',
          onTap: () => _tabController.animateTo(4),
        ),
        _buildInfoCard(
          icon: Icons.celebration_outlined,
          title: 'Etkinlikler',
          subtitle: 'Üniversitedeki etkinlikleri ve organizasyonları görüntüle',
          onTap: () => _tabController.animateTo(6),
        ),
        const SizedBox(height: 24),
        const SectionTitle(title: 'Günün Yemeği'),
        const SizedBox(height: 10),
        FutureBuilder<List<Map<String, String>>>(
          future: _mealsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Yemek listesi alınamadı: ${snapshot.error}'),
                ),
              );
            }

            final meals = snapshot.data ?? [];

            if (meals.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Yemek listesi bulunamadı.'),
                ),
              );
            }

            final meal = _findBestMealForHome(meals);

            if (meal == null) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Bugüne uygun yemek listesi bulunamadı.'),
                ),
              );
            }

            return _buildMealPreviewCard(context, meal);
          },
        ),
        _buildSocialFooter(),
      ],
    );
  }

  Widget _buildHomeTabByRole(String role) {
    if (role == 'staff') {
      return _buildStaffHomeTab();
    }
    return _buildStudentHomeTab();
  }

  Widget _buildAcademicTab(String role) {
    return FutureBuilder<List<MenuSectionModel>>(
      future: _academicMenuFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (role == 'student') ...[
                _buildShortcutCard(
                  icon: Icons.school_outlined,
                  title: 'Bana Özel Akademik Alan',
                  subtitle:
                  'Ders programım, vize, final ve bütünleme programlarına buradan ulaş',
                  colors: const [
                    Color(0xFF0A5F7A),
                    Color(0xFF118AB2),
                    Color(0xFF5BC0DE),
                  ],
                  onTap: widget.onOpenPersonal,
                ),
                const SizedBox(height: 16),
              ],
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Akademik menü alınamadı: ${snapshot.error}'),
                ),
              ),
            ],
          );
        }

        final sections = snapshot.data ?? [];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (role == 'student') ...[
              _buildShortcutCard(
                icon: Icons.school_outlined,
                title: 'Bana Özel Akademik Alan',
                subtitle:
                'Ders programım, vize, final ve bütünleme programlarına buradan ulaş',
                colors: const [
                  Color(0xFF0A5F7A),
                  Color(0xFF118AB2),
                  Color(0xFF5BC0DE),
                ],
                onTap: widget.onOpenPersonal,
              ),
              const SizedBox(height: 16),
            ] else ...[
              _buildShortcutCard(
                icon: Icons.account_balance_outlined,
                title: 'Akademik Birimler',
                subtitle:
                'Fakülteler, enstitüler ve akademik yapı bağlantılarına eriş',
                colors: const [
                  Color(0xFF0A5F7A),
                  Color(0xFF118AB2),
                  Color(0xFF5BC0DE),
                ],
                onTap: widget.onOpenModules,
              ),
              const SizedBox(height: 16),
            ],
            ...sections.asMap().entries.map(
                  (entry) => _buildDynamicMenuSection(
                entry.value,
                icon: Icons.menu_book_outlined,
                initiallyExpanded: entry.key == 0,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAdministrativeTab() {
    return FutureBuilder<List<MenuSectionModel>>(
      future: _administrativeMenuFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('İdari menü alınamadı: ${snapshot.error}'),
                ),
              ),
            ],
          );
        }

        final sections = snapshot.data ?? [];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ...sections.asMap().entries.map(
                  (entry) => _buildDynamicMenuSection(
                entry.value,
                icon: Icons.apartment_outlined,
                initiallyExpanded: entry.key == 0,
              ),
            ),
            const SizedBox(height: 12),
            _buildShortcutCard(
              icon: Icons.widgets_outlined,
              title: 'Hızlı Erişim',
              subtitle: 'Tüm hızlı bağlantılar için modüller sayfasına git',
              colors: const [
                Color(0xFF6C5CE7),
                Color(0xFF8E7DF2),
                Color(0xFFB39DDB),
              ],
              onTap: widget.onOpenModules,
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: _userFuture,
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final role = (data?['role'] ?? 'student').toString().toLowerCase();

        return Column(
          children: [
            Material(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: const [
                  Tab(text: 'Ana Sayfa'),
                  Tab(text: 'Üniversitemiz'),
                  Tab(text: 'Akademik'),
                  Tab(text: 'İdari'),
                  Tab(text: 'Duyurular'),
                  Tab(text: 'Haberler'),
                  Tab(text: 'Etkinlikler'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildHomeTabByRole(role),
                  _buildUniversityTab(),
                  _buildAcademicTab(role),
                  _buildAdministrativeTab(),
                  const AnnouncementsPage(),
                  const NewsPage(),
                  const EventsPage(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}