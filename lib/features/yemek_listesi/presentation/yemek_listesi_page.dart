import 'package:flutter/material.dart';

import '../data/meal_day.dart';
import '../data/meal_service.dart';

class YemekListesiPage extends StatefulWidget {
  const YemekListesiPage({super.key});

  @override
  State<YemekListesiPage> createState() => _YemekListesiPageState();
}

class _YemekListesiPageState extends State<YemekListesiPage> {
  late Future<List<MealDay>> _future;

  @override
  void initState() {
    super.initState();
    _future = MealService().fetchMeals();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = MealService().fetchMeals();
    });
    await _future;
  }

  String _monthTitle(List<MealDay> meals) {
    if (meals.isEmpty) return 'Yemek Listesi';
    final first = meals.first.date.split('.');
    if (first.length == 3) {
      final month = int.tryParse(first[1]) ?? 0;
      final year = first[2];

      const months = {
        1: 'Ocak',
        2: 'Şubat',
        3: 'Mart',
        4: 'Nisan',
        5: 'Mayıs',
        6: 'Haziran',
        7: 'Temmuz',
        8: 'Ağustos',
        9: 'Eylül',
        10: 'Ekim',
        11: 'Kasım',
        12: 'Aralık',
      };

      return '${months[month] ?? ''} $year Yemek Listesi';
    }
    return 'Yemek Listesi';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yemek Listesi'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<MealDay>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                children: [
                  const SizedBox(height: 120),
                  Icon(Icons.restaurant_menu,
                      size: 56, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text(
                      'Yemek listesi alınamadı',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                ],
              );
            }

            final meals = snapshot.data ?? [];

            if (meals.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Icon(Icons.no_meals, size: 56, color: Colors.grey),
                  SizedBox(height: 12),
                  Center(
                    child: Text(
                      'Yemek listesi bulunamadı',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: meals.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _monthTitle(meals),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }

                final item = meals[index - 1];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 1.5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.date,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.teal,
                          ),
                        ),
                        const SizedBox(height: 10),
                        for (int i = 0; i < item.meals.length; i++) ...[
                          Text(
                            '${i + 1}. Yemek: ${item.meals[i]}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          if (i != item.meals.length - 1)
                            const SizedBox(height: 6),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}