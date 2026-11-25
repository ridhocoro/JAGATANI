import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jaga_tani/core/theme/app_colors.dart';
import 'package:jaga_tani/data/services/aktuator_service.dart';
import 'package:jaga_tani/data/services/mqtt_service.dart';

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});
  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  String _mode = 'Auto';
  final List<String> _modes = ['Auto', 'Jadwal', 'Manual'];

  final List<Map<String, dynamic>> _zones = [
    {
      'id': 'zona_a',
      'name': 'Zona A',
      'crop': 'Padi',
      'area': '1.5 Ha',
      'humidity': 45,
      'isActive': false,
      'selectedDuration': '30m',
      'color': AppColors.zoneA,
      'status': 'Standby',
    },
    {
      'id': 'zona_b',
      'name': 'Zona B',
      'crop': 'Jagung',
      'area': '0.8 Ha',
      'humidity': 68,
      'isActive': true,
      'selectedDuration': '20m',
      'color': AppColors.zoneB,
      'status': 'Sedang Menyiram',
      'remaining': '12 menit tersisa',
    },
    {
      'id': 'zona_c',
      'name': 'Zona C',
      'crop': 'Cabai',
      'area': '0.5 Ha',
      'humidity': 82,
      'isActive': false,
      'selectedDuration': '15m',
      'color': AppColors.zoneC,
      'status': 'Standby',
    },
  ];

  double _startThreshold = 50;
  double _stopThreshold = 80;

  // Schedule: [zone][day] bool
  final List<List<bool>> _schedule = List.generate(
      3, (z) => List.generate(7, (d) => d < 3 && z == 0 || d % 2 == 0 && z == 1));

  final List<String> _days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  final List<Map<String, dynamic>> _fertilizers = [
    {
      'name': 'Pupuk Urea',
      'emoji': '🟡',
      'stock': 0.7,
      'lastApplied': '5 hari lalu',
      'dispensedWeek': '12 kg',
    },
    {
      'name': 'Pupuk NPK',
      'emoji': '🟢',
      'stock': 0.45,
      'lastApplied': '3 hari lalu',
      'dispensedWeek': '8 kg',
    },
  ];

  String _formatRemaining(String duration) {
    switch (duration) {
      case '15m':
        return '15 menit tersisa';
      case '30m':
        return '30 menit tersisa';
      case '1j':
        return '60 menit tersisa';
      case 'Custom':
        return '45 menit tersisa';
      default:
        return '$duration tersisa';
    }
  }

  void _showFertilizerDispenseDialog(Map<String, dynamic> f, int index) {
    String selectedZone = 'Zona A (Padi)';
    String selectedDosis = '5 Liter (~2.5 kg)';
    final messenger = ScaffoldMessenger.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: Colors.black, width: 2),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(f['emoji'] as String, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 8),
                      Text(
                        'Alirkan ${f['name']}',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Pilih zona target dan takaran larutan pupuk yang akan dialirkan melalui pipa fertigasi lahan:',
                style: GoogleFonts.spaceGrotesk(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              Text(
                'Zona Target:',
                style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['Zona A (Padi)', 'Zona B (Jagung)', 'Zona C (Cabai)'].map((z) {
                  final isSel = selectedZone == z;
                  return ChoiceChip(
                    label: Text(z),
                    selected: isSel,
                    selectedColor: AppColors.accent,
                    backgroundColor: Colors.grey.shade100,
                    labelStyle: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: isSel ? Colors.black : Colors.grey.shade300, width: 1.5),
                    ),
                    onSelected: (val) {
                      if (val) setModalState(() => selectedZone = z);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text(
                'Dosis / Takaran Larutan:',
                style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  '5 Liter (~2.5 kg)',
                  '10 Liter (~5.0 kg)',
                  '15 Liter (~7.5 kg)',
                ].map((d) {
                  final isSel = selectedDosis == d;
                  return ChoiceChip(
                    label: Text(d),
                    selected: isSel,
                    selectedColor: AppColors.accent,
                    backgroundColor: Colors.grey.shade100,
                    labelStyle: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: isSel ? Colors.black : Colors.grey.shade300, width: 1.5),
                    ),
                    onSelected: (val) {
                      if (val) setModalState(() => selectedDosis = d);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: Colors.black, width: 2),
                    ),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);

                    // Update persentase stok pupuk secara riil
                    setState(() {
                      final currentStock = f['stock'] as double;
                      final newStock = (currentStock - 0.05).clamp(0.0, 1.0);
                      _fertilizers[index]['stock'] = newStock;
                      _fertilizers[index]['lastApplied'] = 'Baru saja';
                    });

                    // Catat ke log AktuatorService & notifikasi ponsel
                    await AktuatorService.catatPemupukan(
                      zonaId: selectedZone.split(' ').first,
                      jenisPupuk: f['name'] as String,
                      dosis: selectedDosis,
                    );

                    messenger.showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.success,
                        content: Text(
                          '✅ ${f['name']} berhasil dialirkan ke $selectedZone ($selectedDosis)!',
                          style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.water_drop_rounded, size: 18),
                  label: Text(
                    'Konfirmasi Alirkan Pupuk',
                    style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNeuCard({required Widget child, Color? color}) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: color ?? Colors.white,
          border: Border.all(color: Colors.black, width: 2),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0)
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: child,
      );

  Widget _buildSectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(title,
            style: GoogleFonts.spaceGrotesk(
                fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
      );

  Widget _buildBottomNav(BuildContext context, int current) {
    final items = [
      {'icon': Icons.home_rounded, 'label': 'Beranda', 'route': '/dashboard'},
      {'icon': Icons.show_chart, 'label': 'Monitor', 'route': '/monitoring'},
      {'icon': Icons.tune, 'label': 'Kontrol', 'route': '/control'},
      {'icon': Icons.auto_awesome, 'label': 'AI', 'route': '/ai'},
      {'icon': Icons.person, 'label': 'Profil', 'route': '/profile'},
    ];
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.black, width: 2)),
        color: Colors.white,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final item = items[i];
              final isSelected = i == current;
              return GestureDetector(
                onTap: () => context.go(item['route'] as String),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: isSelected
                      ? BoxDecoration(
                          color: AppColors.accent,
                          border: Border.all(color: Colors.black, width: 2),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: const [
                            BoxShadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 0)
                          ],
                        )
                      : null,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item['icon'] as IconData,
                          color: isSelected ? Colors.black : AppColors.textSecondary, size: 22),
                      const SizedBox(height: 2),
                      Text(item['label'] as String,
                          style: GoogleFonts.spaceGrotesk(
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                              color: isSelected ? Colors.black : AppColors.textSecondary)),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/dashboard');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text('🎛️ Kontrol Lahan',
            style: GoogleFonts.spaceGrotesk(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI Actuator Banner
            GestureDetector(
              onTap: () => context.push('/ai/recommendation'),
              child: _buildNeuCard(
                color: const Color(0xFFE8F5E9),
                child: Row(
                  children: [
                    const Text('🌾 ', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Rekomendasi Cerdas & Failsafe AI',
                              style: GoogleFonts.spaceGrotesk(
                                  fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary)),
                          Text('Buka panel F-01, F-02, F-03, dan aktuator otomatis terproteksi.',
                              style: GoogleFonts.spaceGrotesk(fontSize: 11, color: Colors.black54)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  ],
                ),
              ),
            ),

            // Mode selector
            _buildNeuCard(
              color: const Color(0xFFFFF9E6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mode Kontrol',
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 14, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  Row(
                    children: _modes.map((m) {
                      final isSelected = _mode == m;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _mode = m),
                          child: Container(
                            margin: EdgeInsets.only(
                                right: m == _modes.last ? 0 : 8),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : Colors.white,
                              border: Border.all(color: Colors.black, width: 2),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: isSelected
                                  ? const [BoxShadow(
                                      color: Colors.black,
                                      offset: Offset(3, 3),
                                      blurRadius: 0)]
                                  : null,
                            ),
                            child: Center(
                              child: Text(m,
                                  style: GoogleFonts.spaceGrotesk(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.textSecondary)),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            // Zone cards
            _buildSectionTitle('🚿 Irigasi per Zona'),
            ..._zones.asMap().entries.map((entry) {
              final i = entry.key;
              final zone = entry.value;
              final isActive = zone['isActive'] as bool;
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0)
                  ],
                ),
                child: Column(
                  children: [
                    // Zone header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: zone['color'] as Color,
                        borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12)),
                      ),
                      child: Row(
                        children: [
                          Text(zone['name'] as String,
                              style: GoogleFonts.spaceGrotesk(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('${zone['crop']} · ${zone['area']}',
                                style: GoogleFonts.spaceGrotesk(
                                    color: Colors.white, fontSize: 11)),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isActive ? AppColors.accent : Colors.white.withValues(alpha: 0.2),
                              border: Border.all(
                                  color: isActive ? Colors.black : Colors.white30, width: 1.5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isActive ? '● Aktif' : '○ Standby',
                              style: GoogleFonts.spaceGrotesk(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isActive ? Colors.black : Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('💧 Kelembaban: ',
                                  style: GoogleFonts.spaceGrotesk(
                                      fontSize: 13, color: AppColors.textSecondary)),
                              Text('${zone['humidity']}%',
                                  style: GoogleFonts.spaceGrotesk(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: (zone['humidity'] as int) < 50
                                          ? AppColors.danger
                                          : AppColors.success)),
                            ],
                          ),
                          if (isActive) ...[
                            const SizedBox(height: 4),
                            Text(
                              '⏱ ${zone['remaining'] ?? _formatRemaining(zone['selectedDuration'] as String? ?? '30m')}',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 12,
                                color: AppColors.info,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          // ON / OFF toggle
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    final zoneId = _zones[i]['id'] as String? ?? 'zona_a';
                                    final zoneName = _zones[i]['name'] as String;
                                    final durStr = _zones[i]['selectedDuration'] as String? ?? '30m';
                                    int durMinutes = 30;
                                    if (durStr == '15m') durMinutes = 15;
                                    if (durStr == '20m') durMinutes = 20;
                                    if (durStr == '1j') durMinutes = 60;

                                    setState(() {
                                      _zones[i]['isActive'] = true;
                                      _zones[i]['status'] = 'Sedang Menyiram';
                                      _zones[i]['remaining'] = _formatRemaining(durStr);
                                    });

                                    MqttService().publishPumpCommand(true, zoneId: zoneId);
                                    AktuatorService.triggerPompa(zonaId: zoneId, durasiMenit: durMinutes);

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Perintah Zigbee ON dikirim ke $zoneName via Gateway aktif.', style: GoogleFonts.spaceGrotesk(fontSize: 12)),
                                        duration: const Duration(seconds: 2),
                                        backgroundColor: AppColors.primary,
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isActive ? AppColors.success : Colors.white,
                                      border: Border.all(color: Colors.black, width: 2),
                                      borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(8),
                                          bottomLeft: Radius.circular(8)),
                                      boxShadow: isActive
                                          ? const [BoxShadow(
                                              color: Colors.black,
                                              offset: Offset(2, 2),
                                              blurRadius: 0)]
                                          : null,
                                    ),
                                    child: Center(
                                      child: Text('▶ NYALAKAN',
                                          style: GoogleFonts.spaceGrotesk(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                              color: isActive ? Colors.white : AppColors.textSecondary)),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    final zoneId = _zones[i]['id'] as String? ?? 'zona_a';
                                    final zoneName = _zones[i]['name'] as String;

                                    setState(() {
                                      _zones[i]['isActive'] = false;
                                      _zones[i]['status'] = 'Standby';
                                      _zones[i]['remaining'] = null;
                                    });

                                    MqttService().publishPumpCommand(false, zoneId: zoneId);
                                    AktuatorService.matikanPompa(zoneId);

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Pompa $zoneName berhasil dimatikan via Zigbee Gateway.', style: GoogleFonts.spaceGrotesk(fontSize: 12)),
                                        duration: const Duration(seconds: 2),
                                        backgroundColor: Colors.black87,
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: !isActive ? AppColors.danger : Colors.white,
                                      border: Border.all(color: Colors.black, width: 2),
                                      borderRadius: const BorderRadius.only(
                                          topRight: Radius.circular(8),
                                          bottomRight: Radius.circular(8)),
                                      boxShadow: !isActive
                                          ? const [BoxShadow(
                                              color: Colors.black,
                                              offset: Offset(2, 2),
                                              blurRadius: 0)]
                                          : null,
                                    ),
                                    child: Center(
                                      child: Text('■ MATIKAN',
                                          style: GoogleFonts.spaceGrotesk(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                              color: !isActive ? Colors.white : AppColors.textSecondary)),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Duration selector
                          Row(
                            children: [
                              Text('Durasi: ',
                                  style: GoogleFonts.spaceGrotesk(
                                      fontSize: 12, color: AppColors.textSecondary)),
                              ...['15m', '30m', '1j', 'Custom'].map((d) {
                                final isSel = zone['selectedDuration'] == d;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _zones[i]['selectedDuration'] = d;
                                      if (_zones[i]['isActive'] == true) {
                                        _zones[i]['remaining'] = _formatRemaining(d);
                                      }
                                    });
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(left: 6),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: isSel ? AppColors.accent : Colors.white,
                                      border: Border.all(color: Colors.black, width: 1.5),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(d,
                                        style: GoogleFonts.spaceGrotesk(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black)),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),

            // Threshold (Auto mode)
            if (_mode == 'Auto') ...[
              _buildNeuCard(
                color: const Color(0xFFE8F5E9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('⚙️ Threshold Otomatis',
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 14, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Mulai Siram (Kelembaban Minimum)',
                            style: GoogleFonts.spaceGrotesk(
                                fontSize: 12, color: AppColors.textSecondary)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('<${_startThreshold.toInt()}%',
                              style: GoogleFonts.spaceGrotesk(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13)),
                        ),
                      ],
                    ),
                    Slider(
                      value: _startThreshold,
                      min: 30,
                      max: 70,
                      divisions: 40,
                      activeColor: AppColors.danger,
                      inactiveColor: Colors.black12,
                      onChanged: (v) => setState(() => _startThreshold = v),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Berhenti Siram (Kelembaban Maksimum)',
                            style: GoogleFonts.spaceGrotesk(
                                fontSize: 12, color: AppColors.textSecondary)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('>${_stopThreshold.toInt()}%',
                              style: GoogleFonts.spaceGrotesk(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13)),
                        ),
                      ],
                    ),
                    Slider(
                      value: _stopThreshold,
                      min: 60,
                      max: 95,
                      divisions: 35,
                      activeColor: AppColors.success,
                      inactiveColor: Colors.black12,
                      onChanged: (v) => setState(() => _stopThreshold = v),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.primary,
                            content: Text('✅ Pengaturan threshold disimpan!',
                                style: GoogleFonts.spaceGrotesk(color: Colors.white)),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          border: Border.all(color: Colors.black, width: 2),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: const [
                            BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0)
                          ],
                        ),
                        child: Center(
                          child: Text('Simpan Pengaturan',
                              style: GoogleFonts.spaceGrotesk(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Schedule (Jadwal mode)
            if (_mode == 'Jadwal') ...[
              _buildNeuCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📅 Jadwal Irigasi Mingguan',
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 14, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    ...List.generate(_zones.length, (z) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_zones[z]['name'] as String,
                              style: GoogleFonts.spaceGrotesk(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary)),
                          const SizedBox(height: 6),
                          Row(
                            children: List.generate(_days.length, (d) {
                              final isOn = _schedule[z][d];
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _schedule[z][d] = !_schedule[z][d]),
                                  child: Container(
                                    margin: EdgeInsets.only(right: d < 6 ? 4 : 0),
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isOn
                                          ? (_zones[z]['color'] as Color)
                                          : Colors.white,
                                      border: Border.all(color: Colors.black, width: 1.5),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Center(
                                      child: Text(_days[d],
                                          style: GoogleFonts.spaceGrotesk(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: isOn
                                                  ? Colors.white
                                                  : AppColors.textSecondary)),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 10),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ],

            // Fertilizer section
            _buildSectionTitle('💊 Pemupukan'),
            ..._fertilizers.map((f) => _buildNeuCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(f['emoji'] as String, style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(f['name'] as String,
                                style: GoogleFonts.spaceGrotesk(
                                    fontSize: 15, fontWeight: FontWeight.w800)),
                          ),
                          Text('Terakhir: ${f['lastApplied']}',
                              style: GoogleFonts.spaceGrotesk(
                                  fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text('Stok: ',
                              style: GoogleFonts.spaceGrotesk(
                                  fontSize: 12, color: AppColors.textSecondary)),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: f['stock'] as double,
                                minHeight: 10,
                                backgroundColor: Colors.black12,
                                color: (f['stock'] as double) > 0.5
                                    ? AppColors.success
                                    : AppColors.warning,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${((f['stock'] as double) * 100).toInt()}%',
                              style: GoogleFonts.spaceGrotesk(
                                  fontSize: 12, fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Minggu ini: ${f['dispensedWeek']}',
                          style: GoogleFonts.spaceGrotesk(
                              fontSize: 11, color: AppColors.textSecondary)),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => _showFertilizerDispenseDialog(f, _fertilizers.indexOf(f)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            border: Border.all(color: Colors.black, width: 2),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [
                              BoxShadow(
                                  color: Colors.black, offset: Offset(3, 3), blurRadius: 0)
                            ],
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.water_drop_rounded, size: 16, color: Colors.black),
                                const SizedBox(width: 6),
                                Text(
                                  'Alirkan Pupuk ke Lahan',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context, 2),
    ),
  );
}
}
