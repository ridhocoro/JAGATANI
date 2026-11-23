import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jaga_tani/core/theme/app_colors.dart';

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
    return Scaffold(
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
                              color: Colors.white.withOpacity(0.2),
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
                              color: isActive ? AppColors.accent : Colors.white.withOpacity(0.2),
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
                            Text('⏱ ${zone['remaining']}',
                                style: GoogleFonts.spaceGrotesk(
                                    fontSize: 12,
                                    color: AppColors.info,
                                    fontWeight: FontWeight.w600)),
                          ],
                          const SizedBox(height: 12),
                          // ON / OFF toggle
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _zones[i]['isActive'] = true),
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
                                  onTap: () => setState(() => _zones[i]['isActive'] = false),
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
                                  onTap: () =>
                                      setState(() => _zones[i]['selectedDuration'] = d),
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
                              }).toList(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),

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
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.success,
                              content: Text('✅ ${f['name']} dikeluarkan!',
                                  style: GoogleFonts.spaceGrotesk(color: Colors.white)),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
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
                            child: Text('💊 Keluarkan Sekarang',
                                style: GoogleFonts.spaceGrotesk(
                                    fontSize: 13, fontWeight: FontWeight.w800, color: Colors.black)),
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
    );
  }
}
