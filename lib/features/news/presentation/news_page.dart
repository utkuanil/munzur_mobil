import 'package:flutter/material.dart';

import '../../external/data/models/site_post.dart';
import '../../external/data/munzur_site_service.dart';
import 'news_detail_page.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({super.key});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  final _service = MunzurSiteService();
  late Future<List<SitePost>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchNews();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _service.fetchNews();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SitePost>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Haberler alınamadı:\n${snapshot.error}'),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = snapshot.data!;

        if (items.isEmpty) {
          return const Center(child: Text('Haber bulunamadı.'));
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => NewsDetailPage(
                          link: item.link,
                          title: item.title,
                          date: item.date,
                          imageUrl: item.imageUrl,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.imageUrl.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              item.imageUrl,
                              height: 170,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                            ),
                          ),
                        if (item.imageUrl.isNotEmpty) const SizedBox(height: 12),
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (item.date.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            item.date,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        if (item.summary.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(item.summary),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}