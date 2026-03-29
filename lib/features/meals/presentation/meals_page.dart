import 'package:flutter/material.dart';

import '../../external/data/munzur_site_service.dart';

class MealsPage extends StatefulWidget {
  const MealsPage({super.key});

  @override
  State<MealsPage> createState() => _MealsPageState();
}

class _MealsPageState extends State<MealsPage> {
  final _service = MunzurSiteService();
  late Future<List<Map<String, String>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchMeals();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _service.fetchMeals();
    });
    await _future;
  }

  String _buildMonthTitle(List<Map<String, String>> meals) {
    if (meals.isEmpty) return 'Yemek Listesi';

    final firstDate = meals.first['date'] ?? '';
    final parts = firstDate.split('.');

    if (parts.length == 3) {
      final month = int.tryParse(parts[1]) ?? 0;
      final year = parts[2];

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

      final monthName = months[month];
      if (monthName != null) {
        return '$monthName $year Yemek Listesi';
      }
    }

    return 'Yemek Listesi';
  }

  Widget _buildMealRow(String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontSize: 14,
          height: 1.4,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String text, {IconData icon = Icons.no_meals}) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Icon(icon, size: 58, color: Colors.grey),
        const SizedBox(height: 12),
        Center(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(Object error) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 80),
        const Icon(
          Icons.error_outline,
          size: 58,
          color: Colors.redAccent,
        ),
        const SizedBox(height: 14),
        const Text(
          'Yemek listesi alınamadı',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '$error',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black54),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        title: const Text('Yemek Listesi'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, String>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: _buildErrorState(snapshot.error!),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final meals = snapshot.data ?? [];

          if (meals.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: _buildEmptyState('Yemek listesi bulunamadı.'),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: meals.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Text(
                      _buildMonthTitle(meals),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D1D1D),
                      ),
                    ),
                  );
                }

                final meal = meals[index - 1];
                final date = meal['date'] ?? '';
                final calorie = meal['calorie'] ?? '';
                final meal1 = meal['meal1'] ?? '';
                final meal2 = meal['meal2'] ?? '';
                final meal3 = meal['meal3'] ?? '';
                final meal4 = meal['meal4'] ?? '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F6),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE1E7E9)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x11000000),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          date,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1D8FA3),
                            fontSize: 15,
                          ),
                        ),
                        if (calorie.trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Kalori: $calorie',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        _buildMealRow('1. Yemek', meal1),
                        _buildMealRow('2. Yemek', meal2),
                        _buildMealRow('3. Yemek', meal3),
                        _buildMealRow('4. Yemek', meal4),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}