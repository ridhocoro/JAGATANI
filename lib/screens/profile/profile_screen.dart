import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:jaga_tani/core/theme/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = 'Pak Budi Santoso';
  String _userTitle = 'Petani Padi & Jagung  |  Jawa Tengah';
  String _userLocation = 'Jawa Tengah';
  String _userCrops = 'Padi & Jagung';

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
      bottomNavigationBar: _buildBottomNav(context, 4),
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
                    onTap: _showEditProfileModal,
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
                    _userName.trim().isNotEmpty ? _userName.trim()[0].toUpperCase() : 'P',
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
                _userName,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _userTitle,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _showEditProfileModal,
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
      onTap: _showAddFarmModal,
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
    final label = item['label'] as String;

    return GestureDetector(
      onTap: () {
        if (isRed) {
          _showLogoutDialog();
        } else {
          _handleMenuClick(label);
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
                label,
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

  void _handleMenuClick(String label) {
    switch (label) {
      case 'Edit Profil':
        _showEditProfileModal();
        break;
      case 'Notifikasi':
        context.push('/notifications');
        break;
      case 'Perangkat IoT Terdaftar':
        context.push('/config');
        break;
      case 'Status: Paket Pro':
      case 'Kelola Langganan':
        _showSubscriptionModal();
        break;
      case 'Panduan Penggunaan':
        _showGuideModal();
        break;
      case 'Pusat Bantuan':
        _showHelpCenterModal();
        break;
      case 'Nilai Aplikasi':
        _showRatingModal();
        break;
      case 'Syarat & Ketentuan':
        _showTermsModal();
        break;
    }
  }

  // ─── Edit Profile Modal ───────────────────────────────────────────────────────
  void _showEditProfileModal() {
    final nameController = TextEditingController(text: _userName);
    final cropsController = TextEditingController(text: _userCrops);
    final locationController = TextEditingController(text: _userLocation);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.black, width: 2.5)),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '✏️ Edit Profil Petani',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInputLabel('Nama Lengkap'),
              _buildNeubrutalTextField(nameController, 'Contoh: Pak Budi Santoso'),
              const SizedBox(height: 12),
              _buildInputLabel('Komoditas / Tanaman Utama'),
              _buildNeubrutalTextField(cropsController, 'Contoh: Padi & Jagung'),
              const SizedBox(height: 12),
              _buildInputLabel('Lokasi Pertanian'),
              _buildNeubrutalTextField(locationController, 'Contoh: Jawa Tengah'),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  final newName = nameController.text.trim();
                  final newCrops = cropsController.text.trim();
                  final newLoc = locationController.text.trim();
                  if (newName.isEmpty) return;

                  setState(() {
                    _userName = newName;
                    _userCrops = newCrops.isEmpty ? 'Padi' : newCrops;
                    _userLocation = newLoc.isEmpty ? 'Indonesia' : newLoc;
                    _userTitle = 'Petani $_userCrops  |  $_userLocation';
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Profil berhasil diperbarui! ✅',
                        style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
                      ),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    border: Border.all(color: Colors.black, width: 2),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'Simpan Perubahan',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Add Farm Modal ───────────────────────────────────────────────────────────
  void _showAddFarmModal() {
    final nameController = TextEditingController();
    final cropController = TextEditingController();
    final areaController = TextEditingController();
    String selectedZone = 'Zona D';
    String selectedEmoji = '🌾';

    final emojis = ['🌾', '🌽', '🌶️', '🍅', '🥬', '🧅', '🥔'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.black, width: 2.5)),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '🌱 Tambah Lahan Baru',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildInputLabel('Nama Lahan'),
                _buildNeubrutalTextField(nameController, 'Contoh: Sawah Barat Blok C'),
                const SizedBox(height: 12),
                _buildInputLabel('Tanaman / Komoditas'),
                _buildNeubrutalTextField(cropController, 'Contoh: Padi Ciherang'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInputLabel('Luas (Ha)'),
                          _buildNeubrutalTextField(areaController, '1.2'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInputLabel('Zona IoT'),
                          Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              border: Border.all(color: Colors.black, width: 2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedZone,
                                isExpanded: true,
                                items: ['Zona A', 'Zona B', 'Zona C', 'Zona D', 'Zona E']
                                    .map((z) => DropdownMenuItem(value: z, child: Text(z, style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w700))))
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) setModalState(() => selectedZone = v);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildInputLabel('Pilih Ikon Lahan'),
                Wrap(
                  spacing: 8,
                  children: emojis.map((e) {
                    final isSel = selectedEmoji == e;
                    return GestureDetector(
                      onTap: () => setModalState(() => selectedEmoji = e),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.accent : AppColors.surface,
                          border: Border.all(color: Colors.black, width: isSel ? 2 : 1),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: isSel
                              ? const [BoxShadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 0)]
                              : null,
                        ),
                        child: Text(e, style: const TextStyle(fontSize: 22)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () {
                    final name = nameController.text.trim();
                    final crop = cropController.text.trim();
                    final area = areaController.text.trim();
                    if (name.isEmpty) return;

                    setState(() {
                      _farms.add({
                        'name': name,
                        'plant': crop.isEmpty ? 'Padi' : crop,
                        'area': '${area.isEmpty ? '1.0' : area} Ha',
                        'score': 80,
                        'zone': selectedZone,
                        'emoji': selectedEmoji,
                        'color': const Color(0xFFE8F5E9),
                      });
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Lahan "$name" berhasil ditambahkan! 🌾',
                          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
                        ),
                        backgroundColor: AppColors.primary,
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
                        BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'Tambah Lahan Sekarang',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Informational Bottom Sheets ──────────────────────────────────────────────
  void _showSubscriptionModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.black, width: 2.5)),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('👑', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 8),
                Text(
                  'Langganan JagaTani Pro',
                  style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.15),
                border: Border.all(color: AppColors.success, width: 1.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'STATUS: AKTIF (Berlaku hingga 31 Des 2027)',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.success,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Keuntungan Paket Pro:\n• Koneksi Zigbee Multi-Sensor Tanpa Batas\n• Rekomendasi ML & Deteksi Penyakit Real-time\n• Otomasi Pompa & Fertigasi Cerdas Failsafe\n• Export Laporan PDF Lengkap Setiap Bulan',
              style: GoogleFonts.spaceGrotesk(fontSize: 13, height: 1.6, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.black, width: 2),
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Tutup', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

  void _showGuideModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.black, width: 2.5)),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('📖', style: TextStyle(fontSize: 26)),
                const SizedBox(width: 8),
                Text('Panduan Penggunaan', style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _buildGuideItem('1. Sambungkan Gateway Zigbee', 'Masuk ke menu Perangkat IoT Terdaftar lalu masukkan broker MQTT dan topik gateway Anda.'),
                  _buildGuideItem('2. Pantau Sensor Lahan', 'Buka tab Monitor untuk melihat grafik telemetri kelembaban tanah, suhu, dan intensitas cahaya secara real-time.'),
                  _buildGuideItem('3. Kontrol Irigasi Otomatis', 'Pada tab Kontrol, Anda dapat menyalakan pompa secara manual atau mengaktifkan mode Auto dengan pengaman cerdas.'),
                  _buildGuideItem('4. Analisis AI & Diagnosa', 'Gunakan tab AI untuk deteksi hama penyakit daun menggunakan kamera dan prediksi kelembaban 24 jam ke depan.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideItem(String title, String desc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: Colors.black, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary)),
          const SizedBox(height: 4),
          Text(desc, style: GoogleFonts.spaceGrotesk(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
        ],
      ),
    );
  }

  void _showHelpCenterModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.black, width: 2.5)),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('💬', style: TextStyle(fontSize: 26)),
                const SizedBox(width: 8),
                Text('Pusat Bantuan JagaTani', style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 14),
            Text('Tim support JagaTani siap membantu kelancaran operasional IoT lahan Anda.', style: GoogleFonts.spaceGrotesk(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.phone_in_talk, color: AppColors.primary),
              title: Text('WhatsApp Support', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, fontSize: 13)),
              subtitle: Text('+62 812-3456-7890 (07.00 - 18.00 WIB)', style: GoogleFonts.spaceGrotesk(fontSize: 12)),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.email_outlined, color: AppColors.primary),
              title: Text('Email Resmi', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, fontSize: 13)),
              subtitle: Text('bantuan@jagatani.id', style: GoogleFonts.spaceGrotesk(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  void _showRatingModal() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Terima kasih atas apresiasi dan bintang 5 Anda untuk JagaTani! ⭐⭐⭐⭐⭐', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showTermsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.black, width: 2.5)),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📄 Syarat & Ketentuan', style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            Text(
              '1. Data telemetri sensor disimpan secara aman dan hanya dapat diakses oleh pemilik akun lahan.\n2. Otomasi aktuator dilengkapi pengaman software & hardware failsafe dari ESP32.\n3. Hak cipta & lisensi aplikasi dimiliki sepenuhnya oleh tim pengembang JagaTani Indonesia.',
              style: GoogleFonts.spaceGrotesk(fontSize: 12.5, height: 1.5, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInputLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
    );
  }

  Widget _buildNeubrutalTextField(TextEditingController controller, String hint) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.spaceGrotesk(fontSize: 12, color: Colors.black38),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: InputBorder.none,
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
                              'Berhasil keluar dari akun. Sampai jumpa! 👋',
                              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
                            ),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                        context.go('/config');
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
