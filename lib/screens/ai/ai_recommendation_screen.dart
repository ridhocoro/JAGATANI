import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:jaga_tani/core/theme/app_colors.dart';
import 'package:jaga_tani/data/models/ml_result_models.dart';
import 'package:jaga_tani/data/models/aktuator_models.dart';
import 'package:jaga_tani/data/services/ml_service.dart';
import 'package:jaga_tani/data/services/aktuator_service.dart';
import 'package:jaga_tani/widgets/neu_badge.dart';

class AiRecommendationScreen extends StatefulWidget {
  const AiRecommendationScreen({super.key});

  @override
  State<AiRecommendationScreen> createState() => _AiRecommendationScreenState();
}

class _AiRecommendationScreenState extends State<AiRecommendationScreen> {
  String _selectedZone = 'zone_a';
  bool _isLoading = true;
  bool _isActionLoading = false;

  F01MoisturePredictionResponse? _f01Data;
  F02IrrigationDecisionResponse? _f02Data;
  F03FertilizerRecommendationResponse? _f03Data;
  ModeZonaModel? _modeZona;
  StatusPompaModel? _statusPompa;
  List<AksiAktuatorModel> _riwayatAksi = [];

  bool _fertilizerConfirmed = false;

  @override
  void initState() {
    super.initState();
    _loadAllMlData();
  }

  Future<void> _loadAllMlData() async {
    setState(() => _isLoading = true);

    try {
      final f01Future = MlService.fetchMoisturePrediction(zonaId: _selectedZone);
      final f02Future = MlService.fetchIrrigationDecision(zonaId: _selectedZone);
      final f03Future = MlService.fetchFertilizerRecommendation(zonaId: _selectedZone);
      final modeFuture = AktuatorService.fetchModeZona(_selectedZone);
      final statusFuture = AktuatorService.fetchStatusPompa(_selectedZone);
      final riwayatFuture = AktuatorService.fetchRiwayatAksi(zonaId: _selectedZone, limit: 10);

      final results = await Future.wait([
        f01Future,
        f02Future,
        f03Future,
        modeFuture,
        statusFuture,
        riwayatFuture,
      ]);

      if (mounted) {
        setState(() {
          _f01Data = results[0] as F01MoisturePredictionResponse;
          _f02Data = results[1] as F02IrrigationDecisionResponse;
          _f03Data = results[2] as F03FertilizerRecommendationResponse;
          _modeZona = results[3] as ModeZonaModel;
          _statusPompa = results[4] as StatusPompaModel;
          _riwayatAksi = results[5] as List<AksiAktuatorModel>;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onZoneChanged(String zoneId) {
    if (_selectedZone != zoneId) {
      setState(() {
        _selectedZone = zoneId;
        _fertilizerConfirmed = false;
      });
      _loadAllMlData();
    }
  }

  Future<void> _ubahMode(String modeBaru) async {
    if (_modeZona?.mode == modeBaru) return;

    if (modeBaru == 'otomatis') {
      final setuju = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.black, width: 2),
          ),
          title: Row(
            children: [
              const Text('⚠️ ', style: TextStyle(fontSize: 22)),
              Text(
                'Konfirmasi Mode Otomatis',
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ],
          ),
          content: Text(
            'Pada mode otomatis, sistem JagaTani akan menyalakan pompa irigasi secara mandiri jika model F-02 memutuskan "Perlu" dan lolos 8 lapis syarat pengaman.\n\nApakah Anda yakin mengaktifkan mode ini untuk ${_selectedZone.toUpperCase()}?',
            style: GoogleFonts.spaceGrotesk(fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Batal', style: GoogleFonts.spaceGrotesk(color: Colors.black54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Colors.black, width: 1.5),
                ),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Ya, Aktifkan Otomatis', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      if (setuju != true) return;
    }

    setState(() => _isActionLoading = true);
    final sukses = await AktuatorService.updateModeZona(_selectedZone, modeBaru);
    if (sukses) {
      final updatedMode = await AktuatorService.fetchModeZona(_selectedZone);
      if (mounted) {
        setState(() {
          _modeZona = updatedMode;
          _isActionLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mode zona $_selectedZone berhasil diubah ke: ${modeBaru.toUpperCase()}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } else {
      if (mounted) {
        setState(() => _isActionLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengubah mode. Periksa koneksi backend.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _triggerSiramManual() async {
    setState(() => _isActionLoading = true);

    final hasil = await AktuatorService.triggerPompa(
      zonaId: _selectedZone,
      durasiMenit: 15,
      sumber: _modeZona?.mode ?? 'semi_otomatis',
    );

    final updatedStatus = await AktuatorService.fetchStatusPompa(_selectedZone);
    final updatedRiwayat = await AktuatorService.fetchRiwayatAksi(zonaId: _selectedZone, limit: 10);

    if (mounted) {
      setState(() {
        _statusPompa = updatedStatus;
        _riwayatAksi = updatedRiwayat;
        _isActionLoading = false;
      });

      if (hasil.perintahDikirim) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Perintah siram ${hasil.durasiMenit} menit berhasil dikirim ke perangkat ESP32!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Colors.black, width: 2),
            ),
            title: Row(
              children: [
                const Text('🛡️ ', style: TextStyle(fontSize: 22)),
                Text(
                  'Ditolak oleh Pengaman',
                  style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ],
            ),
            content: Text(
              hasil.alasanTolak ?? 'Syarat pengaman sistem belum terpenuhi.',
              style: GoogleFonts.spaceGrotesk(fontSize: 13, height: 1.4),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Colors.black, width: 1.5),
                  ),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: Text('Mengerti', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _matikanPompaSegera() async {
    setState(() => _isActionLoading = true);
    final sukses = await AktuatorService.matikanPompa(_selectedZone);
    final updatedStatus = await AktuatorService.fetchStatusPompa(_selectedZone);
    final updatedRiwayat = await AktuatorService.fetchRiwayatAksi(zonaId: _selectedZone, limit: 10);

    if (mounted) {
      setState(() {
        _statusPompa = updatedStatus;
        _riwayatAksi = updatedRiwayat;
        _isActionLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(sukses ? '🛑 Pompa irigasi berhasil dimatikan segera.' : 'Gagal mematikan pompa.'),
          backgroundColor: sukses ? AppColors.danger : Colors.black,
        ),
      );
    }
  }

  void _showFormCatatPemupukan(BuildContext context) {
    // Ambil default dari aturan F-03 jika ada
    String defaultPupuk = 'NPK 15-15-15';
    String defaultDosis = '150 kg/ha';

    if (_f03Data != null && _f03Data!.daftarRekomendasi.isNotEmpty) {
      final firstRule = _f03Data!.daftarRekomendasi.first;
      if (firstRule.saran.contains('NPK')) {
        defaultPupuk = 'NPK 15-15-15';
      } else if (firstRule.saran.contains('Dolomit')) {
        defaultPupuk = 'Kapur Dolomit';
        defaultDosis = '1.5 ton/ha';
      }
    }

    final pupukController = TextEditingController(text: defaultPupuk);
    final dosisController = TextEditingController(text: defaultDosis);
    final messenger = ScaffoldMessenger.of(context);
    bool setuju = true;

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
                  Text(
                    '📝 Form Catat Pemupukan',
                    style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Catat pemupukan aktual yang telah diaplikasikan di lapangan ke dalam buku log digital.',
                style: GoogleFonts.spaceGrotesk(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              Text('Jenis Pupuk:', style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: pupukController,
                decoration: InputDecoration(
                  hintText: 'Misal: NPK 15-15-15 atau Pupuk Kandang',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 12),
              Text('Dosis Diberikan:', style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: dosisController,
                decoration: InputDecoration(
                  hintText: 'Misal: 150 kg/ha atau 2 ton/ha',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: setuju,
                onChanged: (v) => setModalState(() => setuju = v ?? true),
                title: Text(
                  'Saya setuju dan memverifikasi aplikasi pupuk ini di lahan.',
                  style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 16),
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
                  onPressed: !setuju
                      ? null
                      : () async {
                          Navigator.pop(ctx);
                          final sukses = await AktuatorService.catatPemupukan(
                            zonaId: _selectedZone,
                            jenisPupuk: pupukController.text.trim(),
                            dosis: dosisController.text.trim(),
                            idRekomendasiF03: _f03Data?.daftarRekomendasi.isNotEmpty == true
                                ? _f03Data!.daftarRekomendasi.first.idAturan
                                : null,
                          );

                          if (sukses) {
                            setState(() => _fertilizerConfirmed = true);
                            final updatedRiwayat = await AktuatorService.fetchRiwayatAksi(zonaId: _selectedZone, limit: 10);
                            if (mounted) {
                              setState(() => _riwayatAksi = updatedRiwayat);
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Catatan pemupukan berhasil disimpan ke riwayat log!'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          } else {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Gagal mencatat pemupukan. Pastikan dosis dan jenis terisi valid.'),
                                backgroundColor: AppColors.danger,
                              ),
                            );
                          }
                        },
                  icon: const Icon(Icons.save_rounded, size: 18),
                  label: Text('Simpan Catatan Pemupukan', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.black, width: 2),
        ),
        title: Row(
          children: [
            const Text('🚩 ', style: TextStyle(fontSize: 20)),
            Text(
              'Laporkan Keputusan',
              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Apakah rekomendasi AI tidak sesuai dengan kondisi riil lahan Anda?',
              style: GoogleFonts.spaceGrotesk(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Misal: Tanah sebenarnya masih basah karena ada genangan lokal...',
                hintStyle: GoogleFonts.spaceGrotesk(fontSize: 12, color: Colors.black38),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.black, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: GoogleFonts.spaceGrotesk(color: Colors.black54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Colors.black, width: 1.5),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Umpan balik berhasil dicatat untuk iterasi model berikutnya!'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
            child: Text('Kirim Laporan', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showServerConfigDialog() {
    final controller = TextEditingController(text: MlService.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.black, width: 2),
        ),
        title: Row(
          children: [
            const Text('🌐 ', style: TextStyle(fontSize: 20)),
            Text(
              'Alamat Server Backend',
              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Masukkan IP host laptop/PC yang menjalankan backend FastAPI di jaringan Wi-Fi yang sama.',
              style: GoogleFonts.spaceGrotesk(fontSize: 12, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'http://192.168.1.10:8000',
                labelText: 'URL Server Backend',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: GoogleFonts.spaceGrotesk(color: Colors.black54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Colors.black, width: 1.5),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              MlService.setBaseUrl(controller.text.trim());
              _loadAllMlData();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Alamat server diubah ke: ${MlService.baseUrl}'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: Text('Simpan & Hubungkan', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold)),
          ),
        ],
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
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            tooltip: 'Kembali',
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/dashboard');
              }
            },
          ),
          title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            '🌾 Rekomendasi Cerdas AI',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_ethernet_rounded, color: Colors.white),
            tooltip: 'Konfigurasi IP Server Backend',
            onPressed: _showServerConfigDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Segarkan Data',
            onPressed: _loadAllMlData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text('Menghubungkan ke layanan AI JagaTani...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildZoneSelector(),
                  const SizedBox(height: 12),
                  _buildModeSelector(),
                  const SizedBox(height: 12),
                  _buildOfflineStatusBanner(),
                  const SizedBox(height: 16),
                  _buildF02IrrigationCard(),
                  const SizedBox(height: 20),
                  _buildF01MoisturePredictionCard(),
                  const SizedBox(height: 20),
                  _buildF03FertilizerCard(),
                  const SizedBox(height: 20),
                  _buildRiwayatAksiCard(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildZoneSelector() {
    final zones = [
      {'id': 'zone_a', 'name': 'Zona A', 'crop': 'Padi'},
      {'id': 'zone_b', 'name': 'Zona B', 'crop': 'Jagung'},
      {'id': 'zone_c', 'name': 'Zona C', 'crop': 'Cabai'},
    ];

    return Row(
      children: zones.map((z) {
        final isSelected = _selectedZone == z['id'];
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () => _onZoneChanged(z['id']!),
              child: Container(
                height: 54,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accent : Colors.white,
                  border: Border.all(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? const [BoxShadow(color: Colors.black, offset: Offset(3, 3))]
                      : const [BoxShadow(color: Colors.black26, offset: Offset(2, 2))],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      z['name']!,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '(${z['crop']!})',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.black87 : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildModeSelector() {
    final modes = [
      {'id': 'manual', 'label': 'Manual'},
      {'id': 'semi_otomatis', 'label': 'Semi-Otomatis (Default)'},
      {'id': 'otomatis', 'label': 'Otomatis'},
    ];
    final currentMode = _modeZona?.mode ?? 'semi_otomatis';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(3, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '⚙️ Mode Kontrol Zona',
                style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w800),
              ),
              if (_isActionLoading)
                const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
              else
                NeuBadge(
                  label: currentMode.toUpperCase(),
                  color: currentMode == 'otomatis'
                      ? AppColors.danger
                      : (currentMode == 'semi_otomatis' ? AppColors.primary : Colors.grey[700]!),
                  textColor: Colors.white,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: modes.map((m) {
              final isSel = currentMode == m['id'];
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: isSel ? AppColors.primary : const Color(0xFFF8F9FA),
                      foregroundColor: isSel ? Colors.white : Colors.black87,
                      side: BorderSide(color: Colors.black, width: isSel ? 2 : 1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    ),
                    onPressed: _isActionLoading ? null : () => _ubahMode(m['id']!),
                    child: Text(
                      m['label']!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: isSel ? FontWeight.w800 : FontWeight.w600),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineStatusBanner() {
    final isOffline = _f01Data?.status == 'offline_cache';
    return InkWell(
      onTap: _showServerConfigDialog,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isOffline ? const Color(0xFFFFF3CD) : const Color(0xFFD1E7DD),
          border: Border.all(color: Colors.black, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              isOffline ? Icons.cloud_off_rounded : Icons.cloud_done_rounded,
              size: 18,
              color: isOffline ? Colors.orange[800] : Colors.green[800],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isOffline
                    ? 'Mode Cadangan Offline • Ketuk untuk ubah IP Server'
                    : 'Terhubung ke Backend AI FastAPI • Inferensi Real-Time Aktif',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ),
            const Icon(Icons.edit_rounded, size: 14, color: Colors.black54),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // F-02: KEPUTUSAN IRIGASI
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildF02IrrigationCard() {
    final d = _f02Data;
    if (d == null) return const SizedBox.shrink();

    Color cardBg;
    Widget badge;

    if (d.isTidakYakin) {
      cardBg = const Color(0xFFFFFBEA);
      badge = const NeuBadge(
        label: '🤔 TIDAK YAKIN (PERIKSA LAHAN)',
        color: AppColors.warning,
        textColor: Colors.black,
      );
    } else if (d.isPerlu) {
      cardBg = const Color(0xFFFFEBEE);
      badge = NeuBadge.urgent(label: '🚨 PERLU IRIGASI SEKARANG');
    } else {
      cardBg = const Color(0xFFE8F5E9);
      badge = NeuBadge.safe(label: '✅ TIDAK PERLU IRIGASI');
    }

    final confPercent = (d.confidence * 100).toInt();

    return _buildContainerNeu(
      bgColor: cardBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'F-02: KEPUTUSAN IRIGASI',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: badge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tingkat Keyakinan Model:',
                      style: GoogleFonts.spaceGrotesk(fontSize: 12, color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '$confPercent%',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: d.isPerlu ? AppColors.danger : (d.isTidakYakin ? Colors.orange[800] : AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${d.statusKeyakinan.toUpperCase()})',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black, width: 1.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text('Model', style: GoogleFonts.spaceGrotesk(fontSize: 10, color: Colors.black54)),
                    Text('Random Forest', style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black, width: 1.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('💡 ', style: TextStyle(fontSize: 14)),
                    Text(
                      'Alasan Agronomi (Explainability):',
                      style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  d.alasan,
                  style: GoogleFonts.spaceGrotesk(fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Real-time ESP32 Status Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: (_statusPompa?.isOn == true) ? const Color(0xFFE1F5FE) : const Color(0xFFF5F5F5),
              border: Border.all(color: Colors.black, width: 1.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  (_statusPompa?.isOn == true) ? Icons.water_drop_rounded : Icons.power_settings_new_rounded,
                  color: (_statusPompa?.isOn == true) ? Colors.blue[900] : Colors.grey[700],
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    (_statusPompa?.isOn == true)
                        ? 'Status ESP32: Pompa Menyiram (Sisa: ${_statusPompa?.sisaDetik ?? 0} dtk)'
                        : 'Status ESP32: Pompa Standby (Mati)',
                    style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (_statusPompa?.isOn == true)
                        ? Colors.grey[400]
                        : (d.isPerlu ? AppColors.danger : AppColors.primary),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: Colors.black, width: 2),
                    ),
                  ),
                  onPressed: (_isActionLoading || _statusPompa?.isOn == true)
                      ? null
                      : () => _triggerSiramManual(),
                  icon: _isActionLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.water_drop_rounded, size: 18),
                  label: Text(
                    _statusPompa?.isOn == true ? 'Pompa Sedang Menyiram' : 'Konfirmasi Siram 15 Menit',
                    style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, fontSize: 11),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: Colors.black, width: 2),
                  ),
                ),
                onPressed: _isActionLoading ? null : () => _matikanPompaSegera(),
                icon: const Icon(Icons.stop_circle_rounded, size: 18),
                label: Text(
                  'Matikan',
                  style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, fontSize: 11),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Colors.black, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                tooltip: 'Laporkan Jawaban Keliru',
                onPressed: () => _showReportDialog(context),
                icon: const Icon(Icons.flag_outlined, size: 20, color: Colors.black87),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // F-01: PREDIKSI KELEMBABAN TANAH 24 JAM
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildF01MoisturePredictionCard() {
    final p = _f01Data;
    if (p == null) return const SizedBox.shrink();

    final pts = p.prediksi24Jam;
    final spots = pts.map((e) => FlSpot(e.jamKe.toDouble(), e.prediksi)).toList();
    final upperSpots = pts.map((e) => FlSpot(e.jamKe.toDouble(), e.batasAtas)).toList();
    final lowerSpots = pts.map((e) => FlSpot(e.jamKe.toDouble(), e.batasBawah)).toList();

    return _buildContainerNeu(
      bgColor: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'F-01: PREDIKSI KELEMBABAN 24 JAM',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      border: Border.all(color: Colors.black, width: 1.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'MAE: ${p.mae}% • ±${p.rmse}%',
                      style: GoogleFonts.spaceGrotesk(fontSize: 10.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Grafik Prediksi Multi-Output (+ Ketidakpastian ±1 RMSE)',
            style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Nilai aktual terakhir: ${p.nilaiAktualTerakhir}% • Prakiraan terhubung ke Open-Meteo',
            style: GoogleFonts.spaceGrotesk(fontSize: 11, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 190,
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          '${spot.y.toStringAsFixed(2)}%',
                          GoogleFonts.spaceGrotesk(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                minY: 10,
                maxY: 80,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) =>
                      const FlLine(color: Colors.black12, strokeWidth: 1),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.black54, width: 1.5),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (v, m) => Text(
                        '${v.toInt()}%',
                        style: GoogleFonts.spaceGrotesk(fontSize: 9, color: Colors.black54),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 4,
                      getTitlesWidget: (v, m) => Text(
                        '+${v.toInt()}h',
                        style: GoogleFonts.spaceGrotesk(fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                lineBarsData: [
                  // Upper uncertainty bound
                  LineChartBarData(
                    spots: upperSpots,
                    isCurved: true,
                    color: Colors.blue.withValues(alpha: 0.35),
                    barWidth: 1.5,
                    dashArray: [4, 4],
                    dotData: const FlDotData(show: false),
                  ),
                  // Lower uncertainty bound
                  LineChartBarData(
                    spots: lowerSpots,
                    isCurved: true,
                    color: Colors.blue.withValues(alpha: 0.35),
                    barWidth: 1.5,
                    dashArray: [4, 4],
                    dotData: const FlDotData(show: false),
                  ),
                  // Main prediction line
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withValues(alpha: 0.08),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 14, height: 3, color: AppColors.primary),
              const SizedBox(width: 4),
              Text('Prediksi Utama', style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              Container(width: 14, height: 2, color: Colors.blue),
              const SizedBox(width: 4),
              Text('Rentang Toleransi (±1 RMSE)', style: GoogleFonts.spaceGrotesk(fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // F-03: REKOMENDASI PEMUPUKAN EXPERT SYSTEM
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildF03FertilizerCard() {
    final f = _f03Data;
    if (f == null) return const SizedBox.shrink();

    return _buildContainerNeu(
      bgColor: const Color(0xFFFBF8EE),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'F-03: REKOMENDASI PUPUK',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: NeuBadge(
                    label: f.bolehMemupuk ? '🌱 DAPAT MEMUPUK' : '⏳ TUNDA / KOREKSI',
                    color: f.bolehMemupuk ? AppColors.success : AppColors.warning,
                    textColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSensorChip('🧪 pH Tanah', '${f.phTanah}', f.phTanah >= 5.5 && f.phTanah <= 7.5),
              const SizedBox(width: 8),
              _buildSensorChip('💧 Kelembaban', '${f.kelembabanTanah}%', f.kelembabanTanah >= 30.0),
              const SizedBox(width: 8),
              _buildSensorChip('🌧️ Hujan 24h', '${f.curahHujan24h} mm', f.curahHujan24h < 20.0),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Aturan Agronomi yang Terpicu:',
            style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          ...f.daftarRekomendasi.map((rule) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black, width: 1.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '[${rule.idAturan}] ${rule.judul}',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: rule.status == 'warning' ? Colors.orange[900] : Colors.green[900],
                    ),
                    softWrap: true,
                  ),
                  const SizedBox(height: 4),
                  Text(rule.penjelasan, style: GoogleFonts.spaceGrotesk(fontSize: 11, height: 1.3)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('👉 ', style: TextStyle(fontSize: 12)),
                        Expanded(
                          child: Text(
                            rule.saran,
                            style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sumber: ${rule.sumber}',
                    style: GoogleFonts.spaceGrotesk(fontSize: 9, fontStyle: FontStyle.italic, color: Colors.black45),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _fertilizerConfirmed ? AppColors.success : AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: Colors.black, width: 2),
                ),
              ),
              onPressed: () => _showFormCatatPemupukan(context),
              icon: Icon(_fertilizerConfirmed ? Icons.check_circle_rounded : Icons.edit_note_rounded, size: 18),
              label: Text(
                _fertilizerConfirmed ? 'Catatan Pemupukan Tersimpan (Tambah Baru)' : 'Catat Pemupukan Lapangan',
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // LOG RIWAYAT AKSI AKTUATOR & PEMUPUKAN
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildRiwayatAksiCard() {
    return _buildContainerNeu(
      bgColor: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '📋 RIWAYAT AKSI & PEMUPUKAN',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_riwayatAksi.length} Log Terbaru',
                style: GoogleFonts.spaceGrotesk(fontSize: 10, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_riwayatAksi.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.center,
              child: Text(
                'Belum ada aktivitas pompa atau pemupukan tercatat di zona ini.',
                style: GoogleFonts.spaceGrotesk(fontSize: 12, color: Colors.black45),
              ),
            )
          else
            ..._riwayatAksi.map((aksi) {
              Color statusColor;
              String statusLabel;
              if (aksi.status == 'berhasil') {
                statusColor = AppColors.success;
                statusLabel = 'BERHASIL';
              } else if (aksi.status == 'dikirim') {
                statusColor = Colors.blue[700]!;
                statusLabel = 'DIKIRIM (ON)';
              } else if (aksi.status == 'ditolak_pengaman') {
                statusColor = AppColors.danger;
                statusLabel = 'DITOLAK PENGAMAN';
              } else {
                statusColor = Colors.orange[800]!;
                statusLabel = aksi.status.toUpperCase();
              }

              final isPompa = aksi.jenis == 'pompa_irigasi';

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F9FB),
                  border: Border.all(color: Colors.black12, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Text(isPompa ? '💧 ' : '🌱 ', style: const TextStyle(fontSize: 14)),
                              Expanded(
                                child: Text(
                                  isPompa
                                      ? 'Pompa Irigasi (${aksi.durasiMenit ?? 15} Menit)'
                                      : '${aksi.jenisPupuk ?? "Pupuk"} (${aksi.dosis ?? "-"})',
                                  style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            statusLabel,
                            style: GoogleFonts.spaceGrotesk(fontSize: 9, fontWeight: FontWeight.w800, color: statusColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      aksi.alasanTolak ?? aksi.alasan ?? '-',
                      style: GoogleFonts.spaceGrotesk(fontSize: 11, color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sumber: ${aksi.sumber.toUpperCase()}',
                          style: GoogleFonts.spaceGrotesk(fontSize: 9, color: Colors.black45, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          aksi.waktu,
                          style: GoogleFonts.spaceGrotesk(fontSize: 9, color: Colors.black45),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildSensorChip(String label, String value, bool isOk) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: isOk ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
          border: Border.all(color: Colors.black, width: 1.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(label, style: GoogleFonts.spaceGrotesk(fontSize: 9, color: Colors.black87)),
            const SizedBox(height: 2),
            Text(
              value,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isOk ? Colors.green[900] : Colors.red[900],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContainerNeu({required Widget child, Color? bgColor}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor ?? Colors.white,
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0),
        ],
      ),
      child: child,
    );
  }
}
