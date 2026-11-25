import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:jaga_tani/core/constants/app_constants.dart';
import 'package:jaga_tani/core/theme/app_colors.dart';
import 'package:jaga_tani/data/services/mqtt_service.dart';
import 'package:jaga_tani/data/services/notification_service.dart';
import 'package:jaga_tani/data/services/weather_service.dart';
import 'package:jaga_tani/widgets/exit_confirmation_dialog.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedNavIndex = 0;
  WeatherData? _weather;
  bool _isLoadingWeather = true;
  late final MqttService _mqtt;
  late final NotificationService _notifService;

  @override
  void initState() {
    super.initState();
    _mqtt = MqttService();
    _mqtt.addListener(_onMqttUpdate);
    if (!_mqtt.isConnected) {
      _mqtt.connect();
    }
    _notifService = NotificationService();
    _notifService.addListener(_onServiceUpdate);
    _loadWeather();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  void _onMqttUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _loadWeather() async {
    final w = await WeatherService.fetchCurrentWeather();
    if (mounted) {
      setState(() {
        _weather = w;
        _isLoadingWeather = false;
      });
    }
  }

  @override
  void dispose() {
    _mqtt.removeListener(_onMqttUpdate);
    _notifService.removeListener(_onServiceUpdate);
    super.dispose();
  }

  // ── Nav items ──────────────────────────────────────────────────────────────
  final List<_NavItem> _navItems = const [
    _NavItem(icon: Iconsax.home_2,     activeIcon: Iconsax.home_25,  label: 'Beranda',  route: '/dashboard'),
    _NavItem(icon: Iconsax.activity,   activeIcon: Iconsax.activity,  label: 'Monitor',  route: '/monitoring'),
    _NavItem(icon: Iconsax.cpu,        activeIcon: Iconsax.cpu,       label: 'Kontrol',  route: '/control'),
    _NavItem(icon: Iconsax.cpu_charge, activeIcon: Iconsax.cpu_charge,label: 'AI',       route: '/ai'),
    _NavItem(icon: Iconsax.user,       activeIcon: Iconsax.user,      label: 'Profil',   route: '/profile'),
  ];

  String _getFormattedCurrentDate() {
    final now = DateTime.now();
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    final dayName = days[now.weekday - 1];
    final monthName = months[now.month - 1];
    return '$dayName, ${now.day} $monthName ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await showExitConfirmationDialog(context);
        if (shouldExit) {
          await SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
        children: [
          // ── Header + Weather Strip ─────────────────────────────────────────
          _buildHeader(context),

          // ── Scrollable Body ────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHealthScoreCard(),
                  const SizedBox(height: 16),
                  _buildAIRecommendationBanner(context),
                  const SizedBox(height: 20),
                  _buildGatewayStatusBar(),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Sensor Real-Time (Zigbee IoT)'),
                  const SizedBox(height: 12),
                  _buildSensorGrid(),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Status Zona Lahan'),
                  const SizedBox(height: 12),
                  _buildZoneScroll(context),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Aksi Cepat'),
                  const SizedBox(height: 12),
                  _buildQuickActions(context),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Aktivitas Terakhir'),
                  const SizedBox(height: 12),
                  _buildRecentActivity(),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Bottom Navigation ──────────────────────────────────────────────────
      bottomNavigationBar: _buildBottomNav(context),
    ),
  );
}

  // ══════════════════════════════════════════════════════════════════════════
  // HEADER
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildHeader(BuildContext context) {
    return Container(
      color: AppColors.primary,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Greeting row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  // Left: greeting
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Halo, Pak Budi! 👋',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getFormattedCurrentDate(),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.70),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Notification bell
                  GestureDetector(
                    onTap: () => context.push(AppConstants.routeNotifications),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.25), width: 1.5),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Center(
                            child: Icon(Iconsax.notification,
                                color: Colors.white, size: 20),
                          ),
                          if (_notifService.unreadCount > 0)
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(
                                  color: AppColors.danger,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 1.5),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Avatar
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: Colors.black, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black,
                          offset: Offset(2, 2),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'B',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Weather strip (Live Open-Meteo API)
            Container(
              width: double.infinity,
              color: AppColors.primary.withOpacity(0.85),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(_weather?.emoji ?? '🌤️', style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _isLoadingWeather
                            ? 'Memuat prakiraan cuaca...'
                            : '${_weather?.description ?? 'Cerah'}, ${_weather?.temperature.toStringAsFixed(1)}°C  •  RH ${_weather?.humidity}%  •  💨 ${_weather?.windSpeed.toStringAsFixed(0)} km/h',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.95),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.black, width: 1),
                    ),
                    child: Text(
                      'Open-Meteo',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HEALTH SCORE CARD
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildHealthScoreCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border, width: 2),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: AppColors.border,
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Text(
                  '🌱 Kesehatan Lahan',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              // Status badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  border: Border.all(color: AppColors.border, width: 1.5),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                        color: AppColors.border,
                        offset: Offset(2, 2),
                        blurRadius: 0),
                  ],
                ),
                child: Text(
                  '⚠️ Perlu Perhatian',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '74',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  height: 1,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '/100',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Skor Kesehatan Lahan',
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  Text('Diperbarui baru saja',
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary)),
                ],
              )
            ],
          ),
          const SizedBox(height: 14),
          // Custom Neubrutalism progress bar
          Container(
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              border: Border.all(color: AppColors.border, width: 2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                children: [
                  FractionallySizedBox(
                    widthFactor: 0.74,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(4)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0',
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
              Text('Optimal: ≥ 80',
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
              Text('100',
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // AI RECOMMENDATION BANNER
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildAIRecommendationBanner(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.accent,
        border: Border.all(color: AppColors.border, width: 2),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: AppColors.border,
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🧠', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(
                'Rekomendasi AI Hari Ini',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'BARU',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Zona A perlu irigasi! Kelembaban tanah 45% di bawah batas optimal. Segera aktifkan sistem irigasi untuk mencegah stres pada tanaman padi.',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => context.push('/ai/recommendation'),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border, width: 2),
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                      color: AppColors.border,
                      offset: Offset(3, 3),
                      blurRadius: 0),
                ],
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Lihat Semua',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Iconsax.arrow_right_3,
                      size: 16, color: AppColors.textPrimary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ZIGBEE GATEWAY & MQTT STATUS BAR (NEUBRUTALISM)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildGatewayStatusBar() {
    return GestureDetector(
      onTap: () => context.push('/config'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.accent,
          border: Border.all(color: Colors.black, width: 2.5),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              offset: Offset(4, 4),
              blurRadius: 0,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('📡', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ZIGBEE GATEWAY (MQTT)',
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _mqtt.statusMessage,
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black, width: 1.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.settings, size: 12, color: Colors.black),
                  const SizedBox(width: 3),
                  Text(
                    'ATUR',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _mqtt.isConnected ? const Color(0xFF2E7D32) : AppColors.danger,
                border: Border.all(color: Colors.black, width: 1.5),
                borderRadius: BorderRadius.circular(6),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black,
                    offset: Offset(1.5, 1.5),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Text(
                _mqtt.isConnected ? 'ONLINE' : 'OFFLINE',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SENSOR GRID (REAL-TIME ZIGBEE SENSORS - KELEMBAPAN & HUJAN)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildSensorGrid() {
    final bool isMoistWarning = _mqtt.soilHumidity < 50.0;

    final sensors = [
      _SensorData(
        emoji: '💧',
        label: 'Kelembaban Tanah',
        value: '${_mqtt.soilHumidity.toStringAsFixed(1)}%',
        color: AppColors.sensorHumid,
        status: isMoistWarning ? 'Kering' : 'Optimal',
        statusColor: isMoistWarning ? AppColors.warning : AppColors.success,
        isWarning: isMoistWarning,
      ),
      _SensorData(
        emoji: _mqtt.isRaining ? '🌧️' : '☀️',
        label: 'Sensor Hujan',
        value: _mqtt.isRaining
            ? '${_mqtt.rainfallAmount.toStringAsFixed(1)} mm'
            : '0.0 mm (Kering)',
        color: _mqtt.isRaining ? const Color(0xFF1976D2) : const Color(0xFFFFB300),
        status: _mqtt.isRaining ? 'Hujan Turun' : 'Tidak Hujan',
        statusColor: _mqtt.isRaining ? const Color(0xFF1976D2) : AppColors.success,
      ),
      _SensorData(
        emoji: '🌬️',
        label: 'Kelembaban Udara',
        value: '${_mqtt.airHumidity.toStringAsFixed(0)}%',
        color: const Color(0xFF009688),
        status: 'Optimal',
        statusColor: AppColors.success,
      ),
      _SensorData(
        emoji: '🌡️',
        label: 'Suhu Lingkungan',
        value: '${_mqtt.airTemperature.toStringAsFixed(1)}°C',
        color: AppColors.sensorTemp,
        status: 'Normal',
        statusColor: AppColors.success,
      ),
      _SensorData(
        emoji: '⚡',
        label: 'Pompa Irigasi',
        value: _mqtt.soilHumidity < 50.0 ? 'AKTIF (ON)' : 'STANDBY (OFF)',
        color: _mqtt.soilHumidity < 50.0 ? AppColors.warning : const Color(0xFF4CAF50),
        status: _mqtt.soilHumidity < 50.0 ? 'Menyiram' : 'Otomatis',
        statusColor: _mqtt.soilHumidity < 50.0 ? AppColors.warning : AppColors.success,
      ),
      _SensorData(
        emoji: '🛡️',
        label: 'Proteksi Hujan',
        value: _mqtt.isRaining ? 'INTERLOCK ON' : 'MONITORING',
        color: const Color(0xFF673AB7),
        status: _mqtt.isRaining ? 'Pompa Ditahan' : 'Normal',
        statusColor: AppColors.success,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.84,
      children: sensors.map(_buildSensorCard).toList(),
    );
  }

  Widget _buildSensorCard(_SensorData s) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: Colors.black, width: 2.2),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
              color: Colors.black, offset: Offset(3.5, 3.5), blurRadius: 0),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: s.color.withValues(alpha: 0.15),
                  border: Border.all(color: s.color, width: 1.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(s.emoji, style: const TextStyle(fontSize: 16)),
              ),
              const Spacer(),
              // Status dot
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: s.statusColor,
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: AppColors.border, width: 1),
                ),
              ),
            ],
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              s.value,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: s.isWarning ? s.statusColor : AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            s.label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: s.statusColor.withValues(alpha: 0.15),
                border: Border.all(color: s.statusColor, width: 1),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                s.status,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: s.statusColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ZONE STATUS – HORIZONTAL SCROLL
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildZoneScroll(BuildContext context) {
    final zones = [
      _ZoneData(
        name: 'Zona A',
        crop: 'Padi',
        area: '1.5 Ha',
        humidity: 45,
        status: 'Rendah',
        statusColor: AppColors.warning,
        accentColor: AppColors.warning,
        pumpOn: false,
      ),
      _ZoneData(
        name: 'Zona B',
        crop: 'Jagung',
        area: '0.8 Ha',
        humidity: 68,
        status: 'Optimal',
        statusColor: AppColors.success,
        accentColor: AppColors.success,
        pumpOn: true,
      ),
      _ZoneData(
        name: 'Zona C',
        crop: 'Cabai',
        area: '0.5 Ha',
        humidity: 82,
        status: 'Perhatian',
        statusColor: AppColors.warning,
        accentColor: AppColors.sensorPh,
        pumpOn: false,
      ),
    ];

    return SizedBox(
      height: 204,
      child: ListView.separated(
        clipBehavior: Clip.none,
        padding: const EdgeInsets.only(top: 2, bottom: 10, right: 8),
        scrollDirection: Axis.horizontal,
        itemCount: zones.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) => _buildZoneCard(context, zones[i]),
      ),
    );
  }

  Widget _buildZoneCard(BuildContext context, _ZoneData z) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border, width: 2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: AppColors.border, offset: Offset(4, 4), blurRadius: 0),
        ],
      ),
      child: Column(
        children: [
          // Accent top strip
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: z.accentColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(10)),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        z.name,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      // Pump indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: z.pumpOn
                              ? AppColors.success.withOpacity(0.15)
                              : Colors.grey.shade100,
                          border: Border.all(
                              color: z.pumpOn
                                  ? AppColors.success
                                  : Colors.grey.shade400,
                              width: 1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          z.pumpOn ? 'ON' : 'OFF',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            color: z.pumpOn
                                ? AppColors.success
                                : Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${z.crop} • ${z.area}',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${z.humidity}%',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: z.statusColor,
                      height: 1,
                    ),
                  ),
                  Text(
                    'Kelembaban',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 3),
                          decoration: BoxDecoration(
                            color: z.statusColor.withOpacity(0.12),
                            border: Border.all(
                                color: z.statusColor, width: 1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            z.status,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: z.statusColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => context.push('/control'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            border: Border.all(
                                color: AppColors.border, width: 1.5),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: const [
                              BoxShadow(
                                  color: AppColors.border,
                                  offset: Offset(2, 2),
                                  blurRadius: 0),
                            ],
                          ),
                          child: Text(
                            'Siram',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // QUICK ACTIONS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildQuickActions(BuildContext context) {
    final actions = const [
      _QuickAction(emoji: '🚿', label: 'Siram\nSekarang', route: '/control'),
      _QuickAction(emoji: '💊', label: 'Tambah\nPupuk', route: '/control'),
      _QuickAction(emoji: '📊', label: 'Laporan', route: '/report'),
      _QuickAction(emoji: '👥', label: 'Komunitas', route: '/community'),
    ];

    return Row(
      children: actions
          .map(
            (a) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                    right: a == actions.last ? 0 : 10),
                child: GestureDetector(
                  onTap: () => context.push(a.route),
                  child: Container(
                    height: 84,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border:
                          Border.all(color: AppColors.border, width: 2),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                            color: AppColors.border,
                            offset: Offset(3, 3),
                            blurRadius: 0),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(a.emoji,
                            style: const TextStyle(fontSize: 20)),
                        const SizedBox(height: 4),
                        SizedBox(
                          height: 28,
                          child: Center(
                            child: Text(
                              a.label,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                height: 1.15,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // RECENT ACTIVITY
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildRecentActivity() {
    final activities = [
      _Activity(
        emoji: '✅',
        desc: 'Irigasi Zona B selesai - 35 menit',
        time: '2 jam lalu',
        color: AppColors.success,
      ),
      _Activity(
        emoji: '🧠',
        desc: 'AI Rekomendasi: Waspada potensi hujan Zona A',
        time: '5 jam lalu',
        color: const Color(0xFF1976D2),
      ),
      _Activity(
        emoji: '⚠️',
        desc: 'Kelembaban Zona A turun ke 45%',
        time: '6 jam lalu',
        color: AppColors.warning,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border, width: 2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: AppColors.border, offset: Offset(4, 4), blurRadius: 0),
        ],
      ),
      child: Column(
        children: activities.asMap().entries.map((e) {
          final a = e.value;
          final isLast = e.key == activities.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: a.color.withOpacity(0.12),
                        border: Border.all(color: a.color, width: 1.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(a.emoji,
                          style: const TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.desc,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            a.time,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Iconsax.arrow_right_3,
                        size: 14, color: AppColors.textSecondary),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.border.withOpacity(0.15)),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BOTTOM NAVIGATION
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 2)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: _navItems.asMap().entries.map((e) {
              final idx = e.key;
              final item = e.value;
              final isActive = idx == _selectedNavIndex;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedNavIndex = idx);
                    if (idx != 0) context.go(item.route);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.accent : Colors.transparent,
                      border: isActive
                          ? Border.all(color: AppColors.border, width: 2)
                          : Border.all(color: Colors.transparent, width: 2),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: isActive
                          ? const [
                              BoxShadow(
                                color: AppColors.border,
                                offset: Offset(2, 2),
                                blurRadius: 0,
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isActive ? item.activeIcon : item.icon,
                          size: 20,
                          color: isActive
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.label,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 10,
                            fontWeight: isActive
                                ? FontWeight.w800
                                : FontWeight.w500,
                            color: isActive
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// DATA MODELS (private, file-scope)
// ════════════════════════════════════════════════════════════════════════════

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
  const _NavItem(
      {required this.icon,
      required this.activeIcon,
      required this.label,
      required this.route});
}

class _SensorData {
  final String emoji;
  final String label;
  final String value;
  final Color color;
  final String status;
  final Color statusColor;
  final bool isWarning;
  const _SensorData({
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
    required this.status,
    required this.statusColor,
    this.isWarning = false,
  });
}

class _ZoneData {
  final String name;
  final String crop;
  final String area;
  final int humidity;
  final String status;
  final Color statusColor;
  final Color accentColor;
  final bool pumpOn;
  const _ZoneData({
    required this.name,
    required this.crop,
    required this.area,
    required this.humidity,
    required this.status,
    required this.statusColor,
    required this.accentColor,
    required this.pumpOn,
  });
}

class _QuickAction {
  final String emoji;
  final String label;
  final String route;
  const _QuickAction(
      {required this.emoji, required this.label, required this.route});
}

class _Activity {
  final String emoji;
  final String desc;
  final String time;
  final Color color;
  const _Activity(
      {required this.emoji,
      required this.desc,
      required this.time,
      required this.color});
}
