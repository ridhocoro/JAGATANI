import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:jaga_tani/core/theme/app_colors.dart';

class MonitoringScreen extends StatefulWidget {
  const MonitoringScreen({super.key});
  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen> {
  int _selectedTab = 0;
  int _selectedZone = 0;
  final List<String> _tabs = ['24 Jam', '7 Hari', '30 Hari'];
  final List<String> _zones = ['Semua', 'Zona A', 'Zona B', 'Zona C'];

  List<FlSpot> _getHumidityData() {
    final base = [45, 48, 52, 55, 58, 60, 62, 65, 68, 65, 62, 58,
        55, 52, 48, 46, 45, 47, 50, 53, 57, 60, 62, 64];
    return List.generate(base.length, (i) => FlSpot(i.toDouble(), base[i].toDouble()));
  }

  List<FlSpot> _getTempData() {
    final base = [27, 26, 25, 24, 23, 23, 24, 26, 28, 30, 31, 32,
        33, 33, 32, 31, 30, 29, 28, 28, 29, 30, 31, 31];
    return List.generate(base.length, (i) => FlSpot(i.toDouble(), base[i].toDouble()));
  }

  Widget _buildNeuTab(String label, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : Colors.white,
          border: Border.all(color: Colors.black, width: 2),
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? const [BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0)]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: isSelected ? Colors.black : AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _buildZoneChip(String label, int index) {
    final isSelected = _selectedZone == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedZone = index),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          border: Border.all(color: Colors.black, width: 1.5),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? const [BoxShadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 0)]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: isSelected ? Colors.white : AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _buildStatCard(String emoji, String value, String label) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 1.5),
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 0)
          ],
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text(value,
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            Text(label,
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 9, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildNeuCard({required Widget child, Color? color}) {
    return Container(
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
  }

  Widget _buildLineChart(List<FlSpot> spots, Color lineColor, String label) {
    return _buildNeuCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) =>
                      FlLine(color: Colors.black12, strokeWidth: 1),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.black26, width: 1),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (v, m) => Text(
                        v.toInt().toString(),
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 9, color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 4,
                      getTitlesWidget: (v, m) => Text(
                        '${v.toInt()}j',
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 9, color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: lineColor,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (s, x, b, i) => FlDotCirclePainter(
                          radius: 3,
                          color: Colors.white,
                          strokeColor: lineColor,
                          strokeWidth: 2),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: lineColor.withOpacity(0.1),
                    ),
                  ),
                ],
                minY: spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) - 5,
                maxY: spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text('📊 Monitoring Sensor',
            style: GoogleFonts.spaceGrotesk(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () => setState(() {})),
        ],
      ),
      body: Column(
        children: [
          // Time tab selector
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Row(
                    children: List.generate(_tabs.length,
                        (i) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _buildNeuTab(_tabs[i], i),
                            ))),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary stats
                  Row(
                    children: [
                      _buildStatCard('🌡️', '30.1°C', 'Suhu Rata²'),
                      _buildStatCard('💧', '62.4%', 'Kelembaban'),
                      _buildStatCard('🌧️', '0.0 mm', 'Curah Hujan'),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.black, width: 1.5),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: const [
                            BoxShadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 0)
                          ],
                        ),
                        child: Column(
                          children: [
                            const Text('💦', style: TextStyle(fontSize: 18)),
                            const SizedBox(height: 4),
                            Text('128 L',
                                style: GoogleFonts.spaceGrotesk(
                                    fontSize: 13, fontWeight: FontWeight.w800)),
                            Text('Total Air',
                                style: GoogleFonts.spaceGrotesk(
                                    fontSize: 9, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Zone filter
                  Text('Filter Zona',
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(
                          _zones.length, (i) => _buildZoneChip(_zones[i], i)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Charts
                  _buildLineChart(
                      _getHumidityData(), AppColors.sensorHumid, '💧 Kelembaban Tanah (%)'),
                  _buildLineChart(
                      _getTempData(), AppColors.sensorTemp, '🌡️ Suhu Udara (°C)'),

                  // Data table
                  _buildNeuCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('🗂 Data Historis',
                            style: GoogleFonts.spaceGrotesk(
                                fontSize: 14, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 12),
                        Table(
                          columnWidths: const {
                            0: FlexColumnWidth(2),
                            1: FlexColumnWidth(1.5),
                            2: FlexColumnWidth(1.5),
                            3: FlexColumnWidth(1),
                          },
                          border: TableBorder(
                            horizontalInside: BorderSide(
                                color: Colors.black.withOpacity(0.1), width: 1),
                          ),
                          children: [
                            TableRow(
                              decoration:
                                  const BoxDecoration(color: Color(0xFFF5F5F0)),
                              children: ['Waktu', 'Suhu', 'Kelembab.', 'Hujan']
                                  .map((h) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8, horizontal: 4),
                                        child: Text(h,
                                            style: GoogleFonts.spaceGrotesk(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.textSecondary)),
                                      ))
                                  .toList(),
                            ),
                            ...List.generate(8, (i) {
                              final hour = (13 - i);
                              final humid = 64 - i * 2;
                              final temp = 31.2 + (i % 3) * 0.5;
                              return TableRow(
                                decoration: BoxDecoration(
                                    color: i.isEven
                                        ? Colors.white
                                        : const Color(0xFFFAFAF8)),
                                children: [
                                  '$hour:00',
                                  '${temp.toStringAsFixed(1)}°C',
                                  '$humid%',
                                  '0.0mm'
                                ]
                                    .map((v) => Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8, horizontal: 4),
                                          child: Text(v,
                                              style: GoogleFonts.spaceGrotesk(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500)),
                                        ))
                                    .toList(),
                              );
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context, 1),
    );
  }

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
                            BoxShadow(
                                color: Colors.black,
                                offset: Offset(2, 2),
                                blurRadius: 0)
                          ],
                        )
                      : null,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item['icon'] as IconData,
                          color: isSelected ? Colors.black : AppColors.textSecondary,
                          size: 22),
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
}
