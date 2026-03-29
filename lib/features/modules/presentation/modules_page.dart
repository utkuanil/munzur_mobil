import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ModulesPage extends StatelessWidget {
  const ModulesPage({super.key});

  IconData _mapIcon(String? iconName) {
    switch (iconName) {
      case 'school':
        return Icons.school_outlined;
      case 'library':
        return Icons.local_library_outlined;
      case 'public':
        return Icons.public_outlined;
      case 'phone':
        return Icons.phone_outlined;
      case 'calendar':
        return Icons.calendar_month_outlined;
      case 'meal':
        return Icons.restaurant_menu_outlined;
      case 'news':
        return Icons.newspaper_outlined;
      case 'support_agent':
        return Icons.support_agent_outlined;
      default:
        return Icons.widgets_outlined;
    }
  }

  Uri? _normalizeUrl(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return null;

    final withScheme = trimmed.startsWith('http://') ||
        trimmed.startsWith('https://')
        ? trimmed
        : 'https://$trimmed';

    return Uri.tryParse(withScheme);
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = _normalizeUrl(url);

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
        SnackBar(content: Text('Bağlantı açılamadı: ${uri.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('quick_modules').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Bir hata oluştu: ${snapshot.error}'),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        final modules = docs
            .map((e) => e.data())
            .where((e) => e['isActive'] == true)
            .toList()
          ..sort((a, b) {
            final aOrder = (a['sortOrder'] ?? 999) as num;
            final bOrder = (b['sortOrder'] ?? 999) as num;
            return aOrder.compareTo(bOrder);
          });

        if (modules.isEmpty) {
          return const Center(
            child: Text('Henüz modül bulunmuyor.'),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: modules.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.92,
          ),
          itemBuilder: (context, index) {
            final item = modules[index];
            final title = (item['title'] ?? '').toString();
            final subtitle = (item['subtitle'] ?? '').toString();
            final icon = (item['icon'] ?? '').toString();
            final url = (item['url'] ?? '').toString();

            final isClickable = url.trim().isNotEmpty;

            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: isClickable ? () => _openUrl(context, url) : null,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _mapIcon(icon),
                        size: 36,
                        color: const Color(0xFF1D8FA3),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: Center(
                          child: Text(
                            subtitle,
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      if (isClickable)
                        const Icon(
                          Icons.open_in_new_rounded,
                          size: 18,
                          color: Color(0xFF1D8FA3),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}