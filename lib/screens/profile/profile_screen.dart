import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:jaga_tani/core/theme/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final List<Map<String, dynamic>> _farms = [
    {
      'name': 'Kebun Pak Budi (Zona A+B)',
      'plant': 'Padi',
      'area': '2.3 Ha',
      'score': 74,
      'zone': 'Zona A & B',
      'emoji': '🌾',
      'color': Color(0xFFE8F5E9),
    },
    {
      'name': 'Lahan Cabai Magelang',
      'plant': 'Cabai',
      'area': '0.5 Ha',
      'score': 82,
      'zone': 'Zona C',
      'emoji': '🌶️',
      'color': Color(0xFFFFEBEE),
    },
  ];

  final List<Map<String, dynamic>> _menuGroups = [
    {
      'title': 'Pengaturan Akun',
      'items': [
        {'icon': Iconsax.user, 'label': 'Edit Profil', 'badge': null, 'isRed': false},
        {'icon': Iconsax.notification, 'label': 'Notifikasi', 'badge': null, 'isRed': false},
        {
          'icon': Iconsax.cpu,
          'label': 'Perangkat IoT Terdaftar',
          'badge': '1 aktif',
          'badgeColor': Color(0xFF4CAF50),
          'isRed': false,
        },
      ],
    },
    {
      'title': 'Langganan',
      'items': [
        {
          'icon': Iconsax.crown,
          'label': 'Status: Paket Pro',
          'badge': 'Aktif',
          'badgeColor': Color(0xFF4CAF50),
          'isRed': false,
        },
        {
          'icon': Iconsax.card,
          'label': 'Kelola Langganan',
          'badge': null,
          'isRed': false,
        },
      ],
    },
    {
      'title': 'Informasi',
      'items': [
        {'icon': Iconsax.book, 'label': 'Panduan Penggunaan', 'badge': null, 'isRed': false},
        {'icon': Iconsax.message_question, 'label': 'Pusat Bantuan', 'badge': null, 'isRed': false},
        {'icon': Iconsax.star, 'label': 'Nilai Aplikasi', 'badge': null, 'isRed': false},
        {'icon': Iconsax.document, 'label': 'Syarat & Ketentuan', 'badge': null, 'isRed': false},
      ],
    },
    {
      'title': '',
      'items': [
        {'icon': Iconsax.logout, 'label': 'Keluar', 'badge': null, 'isRed': true},
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context),
            _buildStatsRow(),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Lahan Saya'),
                  const SizedBox(height: 10),
                  ..._farms.map((farm) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildFarmCard(farm),
                      )),
                  _buildAddFarmButton(),
                  const SizedBox(height: 24),
                  ..._menuGroups.map((group) {
                    final title = group['title'] as String;
                    final items = group['items'] as List<Map<String, dynamic>>;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (title.isNotEmpty) ...[
                          _buildSectionTitle(title),
                          const SizedBox(height: 8),
                        ],
                        _buildMenuGroup(items),
                        const SizedBox(height: 16),
                      ],
                    );
                  }),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Jaga Tani v1.0.0 • Dibuat dengan ❤️ untuk petani Indonesia',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Custom Header ────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.primary,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            children: [
              // Top row: back / settings
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '👤 Profil Saya',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white54, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Iconsax.setting_2, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Avatar
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  border: Border.all(color: Colors.black, width: 3),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0)],
                ),
                child: Center(
                  child: Text(
                    'B',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Pak Budi Santoso',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Petani Padi & Jagung  |  Jawa Tengah',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Iconsax.edit, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Edit Profil',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Stats Row ────────────────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, -1, 16, 0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0)],
      ),
      child: Row(
        children: [
          _buildStatItem('3', 'Lahan', true),
          _buildStatItem('2.8 Ha', 'Total Luas', true),
          _buildStatItem('2024', 'Bergabung', false),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, bool hasDivider) {
    return Expanded(
      child: Container(
        decoration: hasDivider
            ? const BoxDecoration(
                border: Border(right: BorderSide(color: Colors.black, width: 2)),
              )
            : null,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Farm Cards ───────────────────────────────────────────────────────────────
  Widget _buildFarmCard(Map<String, dynamic> farm) {
    final score = farm['score'] as int;
    Color scoreColor;
    if (score >= 85) {
      scoreColor = AppColors.success;
    } else if (score >= 70) {
      scoreColor = AppColors.accent;
    } else {
      scoreColor = AppColors.warning;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0)],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            decoration: BoxDecoration(
              color: farm['color'] as Color,
              border: const Border(right: BorderSide(color: Colors.black, width: 2)),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                bottomLeft: Radius.circular(10),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(farm['emoji'], style: const TextStyle(fontSize: 28)),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    farm['name'],
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildFarmTag(farm['zone']),
                      const SizedBox(width: 6),
                      _buildFarmTag(farm['plant']),
                      const SizedBox(width: 6),
                      _buildFarmTag(farm['area']),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: scoreColor,
                    border: Border.all(color: Colors.black, width: 1.5),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 0)],
                  ),
                  child: Text(
                    '$score',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Skor',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: Colors.black38, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildAddFarmButton() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border.all(color: Colors.black, width: 2),
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, color: AppColors.primary, size: 20),
            const SizedBox(width: 6),
            Text(
              'Tambah Lahan',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Menu Group ───────────────────────────────────────────────────────────────
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.spaceGrotesk(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildMenuGroup(List<Map<String, dynamic>> items) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0)],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          final isLast = idx == items.length - 1;
          return _buildMenuItem(item, isLast);
        }).toList(),
      ),
    );
  }

  Widget _buildMenuItem(Map<String, dynamic> item, bool isLast) {
    final isRed = item['isRed'] as bool;
    final badge = item['badge'] as String?;
    final badgeColor = item['badgeColor'] as Color?;

    return GestureDetector(
      onTap: () {
        if (isRed) {
          _showLogoutDialog();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(bottom: BorderSide(color: Colors.black12)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isRed ? AppColors.danger.withOpacity(0.1) : AppColors.background,
                border: Border.all(
                  color: isRed ? AppColors.danger.withOpacity(0.4) : Colors.black26,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(
                  item['icon'] as IconData,
                  size: 18,
                  color: isRed ? AppColors.danger : AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item['label'] as String,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isRed ? AppColors.danger : AppColors.textPrimary,
                ),
              ),
            ),
            if (badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (badgeColor ?? AppColors.primary).withOpacity(0.12),
                  border: Border.all(
                    color: badgeColor ?? AppColors.primary,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: badgeColor ?? AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (!isRed)
              const Icon(Iconsax.arrow_right_3, size: 16, color: Colors.black38),
          ],
        ),
      ),
    );
  }

  // ─── Logout Dialog ────────────────────────────────────────────────────────────
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: Colors.black, width: 2),
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(6, 6), blurRadius: 0)],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🚪', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 12),
              Text(
                'Keluar dari Akun?',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Anda akan keluar dari Jaga Tani. Data lahan Anda tetap tersimpan.',
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          border: Border.all(color: Colors.black, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            'Batal',
                            style: GoogleFonts.spaceGrotesk(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Berhasil keluar. Sampai jumpa! 👋',
                              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
                            ),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          border: Border.all(color: Colors.black, width: 2),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [
                            BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'Keluar',
                            style: GoogleFonts.spaceGrotesk(
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
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
    );
  }
}
