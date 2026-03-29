import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../profile/data/academic_calendar_service.dart';
import '../../profile/data/models/academic_calendar_data.dart';
import '../../profile/data/models/academic_calendar_event.dart';

class AcademicCalendarPage extends StatelessWidget {
  const AcademicCalendarPage({super.key});

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isOngoing(AcademicCalendarEvent item) {
    if (item.startDate == null || item.endDate == null) return false;

    final now = _dateOnly(DateTime.now());
    final start = _dateOnly(item.startDate!);
    final end = _dateOnly(item.endDate!);

    return (now.isAtSameMomentAs(start) || now.isAfter(start)) &&
        (now.isAtSameMomentAs(end) || now.isBefore(end));
  }

  bool _isUpcoming(AcademicCalendarEvent item, {int withinDays = 7}) {
    if (item.startDate == null) return false;

    final now = _dateOnly(DateTime.now());
    final start = _dateOnly(item.startDate!);

    if (!start.isAfter(now)) return false;

    final diff = start.difference(now).inDays;
    return diff >= 0 && diff <= withinDays;
  }

  int? _daysLeft(AcademicCalendarEvent item) {
    if (item.startDate == null) return null;

    final now = _dateOnly(DateTime.now());
    final start = _dateOnly(item.startDate!);
    return start.difference(now).inDays;
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF bağlantısı geçersiz.')),
      );
      return;
    }

    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF açılamadı.')),
      );
    }
  }

  Widget _buildHeaderCard(AcademicCalendarData data, BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
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
              Icon(Icons.event_note_outlined, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Akademik Takvim',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            data.year,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            data.scope,
            style: const TextStyle(
              color: Colors.white70,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: data.academicCalendarUrl.trim().isEmpty
                  ? null
                  : () => _openUrl(context, data.academicCalendarUrl),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('PDF\'yi Aç'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAFB),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2EAED)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF1D8FA3)),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats(AcademicCalendarData data) {
    return Row(
      children: [
        _buildStatCard(
          icon: Icons.school_outlined,
          title: 'Akademik Süreç',
          value: data.events.length.toString(),
        ),
        const SizedBox(width: 10),
        _buildStatCard(
          icon: Icons.flag_outlined,
          title: 'Tatil',
          value: data.holidays.length.toString(),
        ),
        const SizedBox(width: 10),
        _buildStatCard(
          icon: Icons.sticky_note_2_outlined,
          title: 'Not',
          value: data.notes.length.toString(),
        ),
      ],
    );
  }

  Widget _buildTag({
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildEventCard(AcademicCalendarEvent item, Color accentColor) {
    final ongoing = _isOngoing(item);
    final upcoming = _isUpcoming(item);
    final daysLeft = _daysLeft(item);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3EAED)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: accentColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                if (item.startDate != null || item.endDate != null)
                  Text(
                    '${_formatDate(item.startDate)} - ${_formatDate(item.endDate)}',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                if ((item.term ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _buildTag(
                    text: item.term!,
                    color: accentColor,
                  ),
                ],
                if (ongoing || upcoming) ...[
                  const SizedBox(height: 8),
                  if (ongoing)
                    _buildTag(
                      text: 'Devam ediyor',
                      color: Colors.green,
                    )
                  else if (upcoming && daysLeft != null)
                    _buildTag(
                      text: '$daysLeft gün kaldı',
                      color: Colors.orange,
                    ),
                ],
                if ((item.note ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    item.note!,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<AcademicCalendarEvent> items,
    required IconData icon,
    required Color color,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Color(0xFFE3EAED)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: color.withOpacity(0.12),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${items.length}',
                  style: const TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...items.map((item) => _buildEventCard(item, color)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Akademik Takvim'),
      ),
      body: FutureBuilder<AcademicCalendarData>(
        future: AcademicCalendarService().fetchCalendar(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Akademik takvim alınamadı: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data;
          if (data == null) {
            return const Center(
              child: Text('Akademik takvim verisi bulunamadı.'),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeaderCard(data, context),
              const SizedBox(height: 14),
              _buildStats(data),
              const SizedBox(height: 14),
              _buildSection(
                title: 'Akademik Süreçler',
                items: data.events,
                icon: Icons.school_outlined,
                color: Colors.indigo,
              ),
              _buildSection(
                title: 'Resmî Tatiller',
                items: data.holidays,
                icon: Icons.flag_outlined,
                color: Colors.orange,
              ),
              _buildSection(
                title: 'Notlar',
                items: data.notes,
                icon: Icons.sticky_note_2_outlined,
                color: Colors.teal,
              ),
            ],
          );
        },
      ),
    );
  }
}