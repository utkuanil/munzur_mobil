import 'package:flutter/material.dart';

import '../../external/data/models/site_post.dart';
import '../../external/data/munzur_site_service.dart';

class NewsDetailPage extends StatefulWidget {
  const NewsDetailPage({
    super.key,
    required this.link,
    required this.title,
    required this.date,
    required this.imageUrl,
  });

  final String link;
  final String title;
  final String date;
  final String imageUrl;

  @override
  State<NewsDetailPage> createState() => _NewsDetailPageState();
}

class _NewsDetailPageState extends State<NewsDetailPage> {
  final _service = MunzurSiteService();
  late Future<SitePost> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchDetail(widget.link);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Haber Detayı')),
      body: FutureBuilder<SitePost>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Detay alınamadı: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final item = snapshot.data!;

          final title = item.title.trim().isNotEmpty ? item.title : widget.title;
          final date = item.date.trim().isNotEmpty ? item.date : widget.date;
          final summary = item.summary.trim();

          // Görseli DETAYDAN değil, LİSTEDEN gelen doğru görselden kullan
          final imageToShow = widget.imageUrl.trim();

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (imageToShow.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.network(
                    imageToShow,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              if (imageToShow.isNotEmpty) const SizedBox(height: 18),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (date.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  date,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
              if (summary.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  summary,
                  style: const TextStyle(fontSize: 16, height: 1.6),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}