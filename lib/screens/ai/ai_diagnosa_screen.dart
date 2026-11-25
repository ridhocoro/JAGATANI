import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jaga_tani/core/theme/app_colors.dart';

class AiDiagnosaScreen extends StatefulWidget {
  const AiDiagnosaScreen({super.key});
  @override
  State<AiDiagnosaScreen> createState() => _AiDiagnosaScreenState();
}

class _AiDiagnosaScreenState extends State<AiDiagnosaScreen>
    with TickerProviderStateMixin {
  bool _hasPhoto = false;
  bool _isAnalyzing = false;
  bool _hasResult = false;
  String _analyzeText = 'Memulai analisis...';
  Timer? _timer;
  late AnimationController _spinController;
  double _confidence = 0;
  late AnimationController _confController;
  late Animation<double> _confAnim;

  final List<String> _analyzeSteps = [
    'Mendeteksi bagian tanaman...',
    'Mengidentifikasi pola penyakit...',
    'Mencocokkan dengan database...',
    'Menghasilkan rekomendasi...',
    'Selesai! 🎉',
  ];

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _confController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _confAnim =
        Tween<double>(begin: 0, end: 0.89).animate(_confController);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _spinController.dispose();
    _confController.dispose();
    super.dispose();
  }

  void _startAnalysis() {
    setState(() => _isAnalyzing = true);
    int step = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 700), (t) {
      if (!mounted) { t.cancel(); return; }
      if (step < _analyzeSteps.length) {
        setState(() => _analyzeText = _analyzeSteps[step]);
        step++;
      } else {
        t.cancel();
        setState(() {
          _isAnalyzing = false;
          _hasResult = true;
        });
        _confController.forward();
      }
    });
  }

  void _reset() {
    setState(() {
      _hasPhoto = false;
      _isAnalyzing = false;
      _hasResult = false;
      _confidence = 0;
    });
    _confController.reset();
  }

  Widget _buildNeuButton(String label, Color bg, Color textColor, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: Colors.black, width: 2),
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0)
            ],
          ),
          child: Text(label,
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 14, fontWeight: FontWeight.w800, color: textColor)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/ai');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            tooltip: 'Kembali',
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/ai');
              }
            },
          ),
          title: Text('🔬 Diagnosa Tanaman AI',
            style: GoogleFonts.spaceGrotesk(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // State: No Photo
            if (!_hasPhoto && !_isAnalyzing && !_hasResult) ...[
              // Big dashed upload box
              GestureDetector(
                onTap: () => setState(() => _hasPhoto = true),
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: Colors.black45,
                      width: 2,
                      strokeAlign: BorderSide.strokeAlignCenter,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: CustomPaint(
                    painter: _DashedBorderPainter(),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F0),
                            border: Border.all(color: Colors.black, width: 2),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                  color: Colors.black,
                                  offset: Offset(3, 3),
                                  blurRadius: 0)
                            ],
                          ),
                          child: const Center(
                              child: Text('📷', style: TextStyle(fontSize: 36))),
                        ),
                        const SizedBox(height: 14),
                        Text('Foto Tanaman Bermasalah',
                            style: GoogleFonts.spaceGrotesk(
                                fontSize: 16, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        Text('Ketuk untuk ambil foto atau pilih dari galeri',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.spaceGrotesk(
                                fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: _buildNeuButton('📷 Kamera', AppColors.primary,
                        Colors.white, () => setState(() => _hasPhoto = true)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildNeuButton('🖼️ Galeri', Colors.white,
                        AppColors.textPrimary, () => setState(() => _hasPhoto = true)),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Tips
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9E6),
                  border: Border.all(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0)
                  ],
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('💡 Tips Foto yang Baik',
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 14, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    ...['Ambil dari jarak 20–30 cm',
                      'Pastikan pencahayaan cukup (tidak terlalu gelap)',
                      'Foto bagian yang paling menunjukkan gejala',
                      'Fokus pada daun, batang, atau buah bermasalah',
                    ].map((tip) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              const Text('• ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                              Expanded(
                                child: Text(tip,
                                    style: GoogleFonts.spaceGrotesk(
                                        fontSize: 12, color: AppColors.textSecondary)),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ],

            // State: Has Photo - Ready to Analyze
            if (_hasPhoto && !_isAnalyzing && !_hasResult) ...[
              Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  border: Border.all(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0)
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🌿', style: TextStyle(fontSize: 60)),
                    const SizedBox(height: 12),
                    Text('Foto siap dianalisis',
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    Text('Daun padi - Zona A',
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _hasPhoto = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.black, width: 2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                            child: Text('↩ Ganti Foto',
                                style: GoogleFonts.spaceGrotesk(
                                    fontWeight: FontWeight.w700, fontSize: 14))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: _startAnalysis,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          border: Border.all(color: Colors.black, width: 2),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: const [
                            BoxShadow(
                                color: Colors.black,
                                offset: Offset(3, 3),
                                blurRadius: 0)
                          ],
                        ),
                        child: Center(
                            child: Text('🧠 Analisis Sekarang',
                                style: GoogleFonts.spaceGrotesk(
                                    fontWeight: FontWeight.w800, fontSize: 14, color: Colors.black))),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // State: Analyzing
            if (_isAnalyzing) ...[
              const SizedBox(height: 40),
              RotationTransition(
                turns: _spinController,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    border: Border.all(color: Colors.black, width: 2),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0)
                    ],
                  ),
                  child: const Center(
                      child: Text('🧠', style: TextStyle(fontSize: 36))),
                ),
              ),
              const SizedBox(height: 24),
              Text('AI Sedang Menganalisis...',
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(_analyzeText,
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 14, color: AppColors.textSecondary)),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  border: Border.all(color: Colors.black, width: 1.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],

            // State: Has Result
            if (_hasResult) ...[
              // Result header
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  border: Border.all(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0)
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('🔬', style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 8),
                        Text('Hasil Analisis AI',
                            style: GoogleFonts.spaceGrotesk(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.black, width: 1.5),
                          ),
                          child: Text('89% Akurat',
                              style: GoogleFonts.spaceGrotesk(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Defisiensi Nitrogen',
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white)),
                    const SizedBox(height: 6),
                    Text(
                      'Daun tanaman menguning dimulai dari daun bagian bawah ke atas.',
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 13, color: Colors.white70, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    // Confidence bar
                    Row(
                      children: [
                        Text('Akurasi:',
                            style: GoogleFonts.spaceGrotesk(
                                fontSize: 12, color: Colors.white70)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AnimatedBuilder(
                            animation: _confAnim,
                            builder: (c, _) => Container(
                              height: 10,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white30, width: 1),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: LinearProgressIndicator(
                                value: _confAnim.value,
                                backgroundColor: Colors.white12,
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('89%',
                            style: GoogleFonts.spaceGrotesk(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.accent)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Symptoms
              _buildResultSection(
                '🔍 Gejala yang Terdeteksi',
                Colors.white,
                child: Column(
                  children: ['Daun menguning (klorosis) dari bawah ke atas',
                    'Pertumbuhan tanaman terhambat',
                    'Daun terlihat tipis dan lebih kecil dari normal',
                    'Warna hijau memudar secara bertahap']
                      .map((g) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 4, right: 8),
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                      color: AppColors.danger,
                                      shape: BoxShape.circle),
                                ),
                                Expanded(
                                  child: Text(g,
                                      style: GoogleFonts.spaceGrotesk(
                                          fontSize: 13, color: AppColors.textSecondary)),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),

              // Cause
              _buildResultSection(
                '🧪 Penyebab',
                Colors.white,
                child: Text(
                  'Kekurangan unsur Nitrogen (N) dalam tanah. Biasanya terjadi karena: pencucian nutrisi akibat hujan berlebihan, pemupukan tidak cukup, atau pH tanah terlalu rendah yang menghambat penyerapan nitrogen.',
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                ),
              ),

              // Solutions (highlighted)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  border: Border.all(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0)
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('💊 Solusi Rekomendasi',
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black)),
                    const SizedBox(height: 12),
                    ...[
                      'Segera berikan pupuk Urea 50 kg/Ha atau pupuk NPK 15-15-15',
                      'Aplikasikan pupuk cair nitrogen setiap 7 hari',
                      'Periksa pH tanah — nitrogen lebih mudah diserap pada pH 6.5–7.0',
                      'Periksa kembali kondisi tanaman dalam 14 hari',
                    ].asMap().entries.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                margin: const EdgeInsets.only(right: 10, top: 1),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Center(
                                  child: Text('${e.key + 1}',
                                      style: GoogleFonts.spaceGrotesk(
                                          fontSize: 11,
                                          color: AppColors.accent,
                                          fontWeight: FontWeight.w800)),
                                ),
                              ),
                              Expanded(
                                child: Text(e.value,
                                    style: GoogleFonts.spaceGrotesk(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                        height: 1.4)),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),

              // Products
              _buildResultSection(
                '🛒 Produk yang Disarankan',
                Colors.white,
                child: Column(
                  children: [
                    _buildProductRow('Pupuk Urea (Pusri)', '50 kg/Ha', true),
                    _buildProductRow('Pupuk NPK Phonska', '25 kg/Ha', false),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: _buildNeuButton(
                        '🔄 Analisis Ulang', Colors.white, Colors.black, _reset),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildNeuButton('💾 Simpan Hasil', AppColors.primary,
                        Colors.white, () {}),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    ),
  );
}

  Widget _buildResultSection(String title, Color bg, {required Widget child}) =>
      Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: Colors.black, width: 2),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0)
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 14, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            child,
          ],
        ),
      );

  Widget _buildProductRow(String name, String dose, bool isPrimary) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFFFFFEF2) : Colors.white,
          border: Border.all(
              color: isPrimary ? Colors.black : Colors.black26, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Text(isPrimary ? '⭐' : '○', style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(name,
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w500)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(dose,
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success)),
            ),
          ],
        ),
      );
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black38
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 8.0;
    const dashSpace = 6.0;
    const radius = 16.0;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(radius)));

    final dashPath = Path();
    for (final m = path.computeMetrics(); m.isNotEmpty;) {
      final metric = m.first;
      double distance = 0;
      while (distance < metric.length) {
        dashPath.addPath(metric.extractPath(distance, distance + dashWidth),
            Offset.zero);
        distance += dashWidth + dashSpace;
      }
      break;
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
