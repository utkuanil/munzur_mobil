import 'package:flutter/material.dart';

import '../../external/data/models/site_post.dart';
import '../../external/data/munzur_site_service.dart';
import 'event_detail_page.dart';

class EventsPage extends StatelessWidget {
  const EventsPage({super.key});

  Widget _buildEventCard({
    required BuildContext context,
    required String title,
    required String date,
    required String link,
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
          child: const Icon(
            Icons.event_outlined,
            color: Color(0xFF1D8FA3),
          ),
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
            date,
            style: const TextStyle(fontSize: 13),
          ),
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => EventDetailPage(
                link: link,
                title: title,
                date: date,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final siteService = MunzurSiteService();

    return FutureBuilder<List<SitePost>>(
      future: siteService.fetchEvents(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Etkinlikler alınamadı: ${snapshot.error}'),
            ),
          );
        }

        final items = snapshot.data ?? [];

        if (items.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Etkinlik bulunamadı.'),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];

            return _buildEventCard(
              context: context,
              title: item.title,
              date: item.date,
              link: item.link,
            );
          },
        );
      },
    );
  }
}