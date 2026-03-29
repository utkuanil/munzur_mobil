import 'package:flutter/material.dart';

import '../../external/data/models/site_post.dart';
import '../../external/data/munzur_site_service.dart';

class EventDetailPage extends StatefulWidget {
  const EventDetailPage({
    super.key,
    required this.link,
    required this.title,
    required this.date,
  });

  final String link;
  final String title;
  final String date;

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  final _service = MunzurSiteService();
  late Future<SitePost> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchEventDetail(
      widget.link,
      fallbackTitle: widget.title,
      fallbackDate: widget.date,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Etkinlik Detayı'),
      ),
      body: FutureBuilder<SitePost>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Etkinlik detayı alınamadı: ${snapshot.error}'),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final item = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (item.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.network(
                    item.imageUrl,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              if (item.imageUrl.isNotEmpty) const SizedBox(height: 18),
              Text(
                item.title.isNotEmpty ? item.title : widget.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                item.date.isNotEmpty ? item.date : widget.date,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              if (item.summary.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  item.summary,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.6,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}