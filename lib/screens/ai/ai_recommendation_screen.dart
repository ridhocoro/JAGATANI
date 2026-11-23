import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jaga_tani/core/theme/app_colors.dart';

class AiRecommendationScreen extends StatefulWidget {
  const AiRecommendationScreen({super.key});
  @override
  State<AiRecommendationScreen> createState() => _AiRecommendationScreenState();
}

class _AiRecommendationScreenState extends State<AiRecommendationScreen> {
  bool _isRefreshing = false;
  bool _expandedIndex = false;
  final Set<int> _expanded = {};

  Future<void> _refresh() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(milliseconds: 1800));
    if (mounted) setState(() => _isRefreshing = false);
  }

  final List<Map<String, dynamic>> _sensorContext = [
    {'emoji': '🌡️', 'label': 'Suhu', 'value': '31.2°C', 'status': 'Normal', 'ok': true},
    {'emoji': '💧', 'label': 'Kelembaban', 'value': '45.2%', 'status': 'Rendah', 'ok': false},
    {'emoji': '🧪', 'label': 'pH Tanah', 'value': '6.3', 'status': 'Rendah', 'ok': false},
    {'emoji': '🌬️', 'label': 'Kelembaban Udara', 'value': '72%', 'status': 'Normal', 'ok': true},
  ];

  final List<Map<String, dynamic>> _recommendations = [
    {
      'priority': 'urgent',
      'priorityLabel': '⚡ SEGERA',
      'priorityColor': AppColors.danger,
      'category': '💧',
      'categoryLabel': 'Irigasi',
      'title': 'Irigasi Zona A Diperlukan Segera',
      'trigger': '📊 Kelembaban tanah: 45.2% (batas minimum: 50%)',
      'analysis':
          'Kelembaban tanah Zona A berada 4.8% di bawah batas minimum optimal untuk padi. Jika tidak disiram dalam 4–6 jam, tanaman berisiko mengalami stres air yang dapat mengurangi hasil panen hingga 15–20%. Data historis menunjukkan tren penurunan kelembaban konsisten sejak 3 jam terakhir.',
      'recommendation': '✅ Aktifkan irigasi Zona A selama 30 menit',
      'actionLabel': 'Siram Sekarang',
      'actionColor': AppColors.danger,
      'subAction': 'Atur ke Mode Auto',
    },
    {
      'priority': 'attention',
      'priorityLabel': '⚠️ PERHATIAN',
      'priorityColor': AppColors.warning,
      'category': '🧪',
      'categoryLabel': 'pH Tanah',
      'title': 'pH Tanah Zona A Perlu Koreksi',
      'trigger': '📊 pH saat ini: 6.3 (optimal: 6.5–7.0)',
      'analysis':
          'pH 6.3 menunjukkan kondisi tanah sedikit asam. Pada kondisi ini, ketersediaan fosfor dan kalium untuk akar tanaman berkurang. Defisiensi fosfor dapat menghambat pembentukan akar dan bunga. Disarankan untuk melakukan koreksi pH sebelum fase pembungaan.',
      'recommendation': 'Tambahkan kapur dolomit 200 kg/Ha dalam 3 hari ke depan',
      'actionLabel': 'Tambah ke Jadwal',
      'actionColor': AppColors.warning,
      'subAction': 'Lihat Panduan Koreksi pH',
    },
    {
      'priority': 'attention',
      'priorityLabel': '⚠️ PERHATIAN',
      'priorityColor': AppColors.warning,
      'category': '🌿',
      'categoryLabel': 'Nitrogen (N)',
      'title': 'Kadar Nitrogen Mulai Menurun',
      'trigger': '📊 N: 180 mg/kg (disarankan: >200 mg/kg)',
      'analysis':
          'Kadar nitrogen 10% di bawah nilai optimal untuk fase vegetatif padi. Tanaman membutuhkan nitrogen tinggi untuk pertumbuhan daun dan batang. Indikasi awal: warna daun mulai kurang hijau dibanding 7 hari lalu berdasarkan foto diagnosa terakhir.',
      'recommendation': 'Aplikasikan pupuk Urea 50 kg/Ha minggu ini',
      'actionLabel': 'Jadwalkan Pemupukan',
      'actionColor': AppColors.warning,
      'subAction': 'Lihat Riwayat Pemupukan',
    },
    {
      'priority': 'safe',
      'priorityLabel': '✅ AMAN',
      'priorityColor': AppColors.success,
      'category': '🌡️',
      'categoryLabel': 'Suhu',
      'title': 'Suhu Lahan dalam Kondisi Ideal',
      'trigger': '📊 Suhu: 31.2°C (rentang optimal: 25–35°C)',
      'analysis':
          'Suhu udara dan tanah saat ini berada dalam rentang ideal untuk pertumbuhan padi di fase vegetatif. Tidak ada risiko stres panas yang signifikan. Prakiraan cuaca 3 hari ke depan menunjukkan suhu akan tetap stabil.',
      'recommendation': 'Tidak ada tindakan diperlukan untuk suhu',
      'actionLabel': 'Lihat Detail',
      'actionColor': AppColors.success,
      'subAction': null,
    },
    {
      'priority': 'safe',
      'priorityLabel': '✅ AMAN',
      'priorityColor': AppColors.success,
      'category': '🌬️',
      'categoryLabel': 'Kelembaban Udara',
      'title': 'Kelembaban Udara Baik',
      'trigger': '📊 RH Udara: 72% (optimal: 60–90%)',
      'analysis':
          'Kelembaban udara 72% berada dalam rentang optimal. Risiko serangan penyakit jamur (blast, bercak daun) rendah. Kondisi ini mendukung fotosintesis yang efisien.',
      'recommendation': 'Kondisi baik. Pantau terus setiap 6 jam',
      'actionLabel': 'Lihat Detail',
      'actionColor': AppColors.success,
      'subAction': null,
    },
  ];

  Widget _buildNeuCard({required Widget child, Color? color, Color? borderColor}) =>
      Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: color ?? Colors.white,
          border: Border.all(color: borderColor ?? Colors.black, width: 2),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0)
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: child,
      );

  Widget _buildRecommendationCard(Map<String, dynamic> rec, int index) {
    final Color pColor = rec['priorityColor'] as Color;
    final bool isExpanded = _expanded.contains(index);

    return GestureDetector(
      onTap: () => setState(() {
        if (isExpanded) {
          _expanded.remove(index);
        } else {
          _expanded.add(index);
        }
      }),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 2),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0)
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left priority stripe
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: pColor,
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: pColor.withOpacity(0.12),
                            border: Border.all(color: pColor, width: 1.5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(rec['priorityLabel'] as String,
                              style: GoogleFonts.spaceGrotesk(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: pColor)),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.05),
                            border:
                                Border.all(color: Colors.black26, width: 1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                              '${rec['category']} ${rec['categoryLabel']}',
                              style: GoogleFonts.spaceGrotesk(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary)),
                        ),
                        const Spacer(),
                        Icon(
                            isExpanded
                                ? Icons.expand_less
                                : Icons.expand_more,
                            size: 20,
                            color: AppColors.textSecondary),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(rec['title'] as String,
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 6),
                    // Trigger info
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F0),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.black12, width: 1),
                      ),
                      child: Text(rec['trigger'] as String,
                          style: GoogleFonts.spaceGrotesk(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600)),
                    ),

                    // Expanded content
                    if (isExpanded) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: pColor.withOpacity(0.05),
                          border: Border.all(
                              color: pColor.withOpacity(0.3), width: 1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('🤖 Analisis AI:',
                                style: GoogleFonts.spaceGrotesk(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: pColor)),
                            const SizedBox(height: 6),
                            Text(rec['analysis'] as String,
                                style: GoogleFonts.spaceGrotesk(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    height: 1.5)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.2),
                          border: Border.all(
                              color: Colors.black.withOpacity(0.2), width: 1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Text('💡', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(rec['recommendation'] as String,
                                  style: GoogleFonts.spaceGrotesk(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary)),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {},
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: pColor,
                                border:
                                    Border.all(color: Colors.black, width: 2),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: const [
                                  BoxShadow(
                                      color: Colors.black,
                                      offset: Offset(2, 2),
                                      blurRadius: 0)
                                ],
                              ),
                              child: Center(
                                child: Text(rec['actionLabel'] as String,
                                    style: GoogleFonts.spaceGrotesk(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white)),
                              ),
                            ),
                          ),
                        ),
                        if (rec['subAction'] != null) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {},
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                      color: Colors.black, width: 1.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(rec['subAction'] as String,
                                      style: GoogleFonts.spaceGrotesk(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textSecondary)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text('📡 Rekomendasi AI',
            style: GoogleFonts.spaceGrotesk(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refresh,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sensor context card
            _buildNeuCard(
              color: const Color(0xFFF5F5F0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('📡 Data Sensor Saat Ini',
                          style: GoogleFonts.spaceGrotesk(
                              fontSize: 14, fontWeight: FontWeight.w800)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.15),
                          border: Border.all(color: AppColors.success, width: 1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('● Live',
                            style: GoogleFonts.spaceGrotesk(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.success)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2.8,
                    children: _sensorContext.map((s) {
                      final bool ok = s['ok'] as bool;
                      return Container(
                        decoration: BoxDecoration(
                          color: ok
                              ? AppColors.success.withOpacity(0.08)
                              : AppColors.danger.withOpacity(0.08),
                          border: Border.all(
                              color: ok ? AppColors.success : AppColors.danger,
                              width: 1.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        child: Row(
                          children: [
                            Text(s['emoji'] as String,
                                style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(s['value'] as String,
                                      style: GoogleFonts.spaceGrotesk(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textPrimary)),
                                  Text(s['label'] as String,
                                      style: GoogleFonts.spaceGrotesk(
                                          fontSize: 9,
                                          color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            Text(ok ? '✅' : '⚠️',
                                style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text('Diperbarui: 5 menit lalu · Zona: Semua Zona',
                          style: GoogleFonts.spaceGrotesk(
                              fontSize: 10, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),

            // Analysis status banner
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: AppColors.accent,
                border: Border.all(color: Colors.black, width: 2),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0)
                ],
              ),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Text('🤖', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'AI telah menganalisis 8 parameter sensor. Ditemukan 2 kondisi yang memerlukan tindakan segera.',
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),

            // Recommendations
            Text('Rekomendasi AI',
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Ketuk kartu untuk melihat analisis lengkap',
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 12),

            ...List.generate(_recommendations.length,
                (i) => _buildRecommendationCard(_recommendations[i], i)),

            // Footer
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                border: Border.all(color: const Color(0xFF1565C0), width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🤖', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Rekomendasi dihasilkan berdasarkan model ML yang dilatih dengan data pertanian Indonesia. Selalu konsultasikan dengan penyuluh untuk keputusan besar.',
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          color: const Color(0xFF1565C0),
                          height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: GestureDetector(
        onTap: _refresh,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.primary,
            border: Border.all(color: Colors.black, width: 2),
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0)
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.refresh, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('Refresh Analisis',
                  style: GoogleFonts.spaceGrotesk(
                      color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
