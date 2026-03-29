class AiInsightItem {
  final String title;
  final String message;
  final String category;
  final String actionLabel;
  final String actionType;
  final String? actionUrl;
  final int priority;

  const AiInsightItem({
    required this.title,
    required this.message,
    required this.category,
    required this.actionLabel,
    required this.actionType,
    this.actionUrl,
    required this.priority,
  });
}