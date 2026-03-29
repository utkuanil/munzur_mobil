import 'package:flutter/material.dart';
import '../../data/models/ai_insight_item.dart';

class AiInsightsCard extends StatelessWidget {
  final List<AiInsightItem> insights;
  final bool isLoading;
  final String? error;
  final void Function(AiInsightItem item)? onActionTap;

  const AiInsightsCard({
    super.key,
    required this.insights,
    this.isLoading = false,
    this.error,
    this.onActionTap,
  });

  Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'akademik':
        return const Color(0xFF1565C0);
      case 'kurumsal':
        return const Color(0xFF5E35B1);
      case 'takvim':
        return const Color(0xFF6A1B9A);
      case 'ders':
        return const Color(0xFF00897B);
      case 'sınav':
        return const Color(0xFFEF6C00);
      case 'profil':
        return const Color(0xFFC62828);
      case 'duyuru':
        return const Color(0xFFAD1457);
      case 'etkinlik':
        return const Color(0xFF6D4C41);
      case 'yemek':
        return const Color(0xFF2E7D32);
      case 'öğrenci':
        return const Color(0xFF3949AB);
      default:
        return const Color(0xFF455A64);
    }
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'akademik':
        return Icons.school_outlined;
      case 'kurumsal':
        return Icons.account_balance_outlined;
      case 'takvim':
        return Icons.event_note_outlined;
      case 'ders':
        return Icons.calendar_month_outlined;
      case 'sınav':
        return Icons.fact_check_outlined;
      case 'profil':
        return Icons.person_outline;
      case 'duyuru':
        return Icons.campaign_outlined;
      case 'etkinlik':
        return Icons.celebration_outlined;
      case 'yemek':
        return Icons.restaurant_menu_outlined;
      case 'öğrenci':
        return Icons.badge_outlined;
      default:
        return Icons.auto_awesome;
    }
  }

  String _headerSubtitle() {
    if (isLoading) {
      return 'Sana özel öneriler hazırlanıyor';
    }

    if (error != null) {
      return 'Şu anda öneriler alınamıyor';
    }

    if (insights.isEmpty) {
      return 'Şimdilik gösterilecek öneri bulunamadı';
    }

    return 'Sana özel akıllı yönlendirmeler';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F6070),
            Color(0xFF1D8FA3),
            Color(0xFF57C4D8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'AI Önerileri',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _headerSubtitle(),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),

          if (isLoading)
            const SizedBox(
              height: 100,
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          else if (error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                ),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.white,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Öneriler şu anda alınamıyor. Biraz sonra yeniden deneyebilirsin.',
                      style: TextStyle(
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (insights.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Colors.white,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Şimdilik sana özel ek öneri bulunamadı. Profil bilgilerini tamamladıkça öneriler daha akıllı hale gelecektir.',
                        style: TextStyle(
                          color: Colors.white,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...insights.map((item) {
                final categoryColor = _categoryColor(item.category);
                final icon = _categoryIcon(item.category);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              icon,
                              color: categoryColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: categoryColor.withValues(alpha: 0.22),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    item.category,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  item.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    height: 1.25,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item.message,
                        style: const TextStyle(
                          color: Colors.white,
                          height: 1.45,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          onPressed: onActionTap == null
                              ? null
                              : () => onActionTap!(item),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: categoryColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                          label: Text(
                            item.actionLabel,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
        ],
      ),
    );
  }
}