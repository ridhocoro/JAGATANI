import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:jaga_tani/core/theme/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      'emoji': '📡',
      'title': 'Pantau Lahan\nReal-Time',
      'desc':
          'Sensor IoT canggih memantau suhu, kelembaban tanah, dan pH lahan Anda 24 jam sehari, 7 hari seminggu.',
      'color': '#E8F5E9',
    },
    {
      'emoji': '🤖',
      'title': 'Otomasi\nCerdas',
      'desc':
          'Irigasi dan pemupukan berjalan otomatis berdasarkan data sensor. Hemat waktu, hemat biaya, hasil lebih optimal!',
      'color': '#E3F2FD',
    },
    {
      'emoji': '🧠',
      'title': 'Rekomendasi\nAI Langsung',
      'desc':
          'Dapatkan saran tindakan dari AI berdasarkan kondisi sensor lahan Anda secara real-time. Pertanian presisi di genggaman tangan.',
      'color': '#F3E5F5',
    },
  ];

  final List<Color> _bgColors = [
    const Color(0xFFE8F5E9),
    const Color(0xFFE3F2FD),
    const Color(0xFFF3E5F5),
  ];

  final List<Color> _accentColors = [
    AppColors.primary,
    const Color(0xFF1565C0),
    const Color(0xFF6A1B9A),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColors[_currentPage],
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.black, width: 2),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [
                            BoxShadow(
                                color: Colors.black,
                                offset: Offset(2, 2),
                                blurRadius: 0)
                          ],
                        ),
                        child: const Center(
                            child: Text('🌾',
                                style: TextStyle(fontSize: 16))),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Jaga Tani',
                        style: GoogleFonts.spaceGrotesk(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => context.go('/config'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black, width: 1.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Lewati',
                        style: GoogleFonts.spaceGrotesk(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Emoji container
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border:
                                Border.all(color: Colors.black, width: 2.5),
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: const [
                              BoxShadow(
                                  color: Colors.black,
                                  offset: Offset(6, 6),
                                  blurRadius: 0)
                            ],
                          ),
                          child: Center(
                            child: Text(
                              page['emoji']!,
                              style: const TextStyle(fontSize: 80),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Page indicator badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: _accentColors[index],
                            borderRadius: BorderRadius.circular(20),
                            border:
                                Border.all(color: Colors.black, width: 1.5),
                          ),
                          child: Text(
                            '${index + 1} / ${_pages.length}',
                            style: GoogleFonts.spaceGrotesk(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 11),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Title
                        Text(
                          page['title']!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Description
                        Text(
                          page['desc']!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom section
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: _pages.length,
                    effect: WormEffect(
                      dotColor: Colors.black26,
                      activeDotColor: _accentColors[_currentPage],
                      dotHeight: 10,
                      dotWidth: 10,
                      spacing: 8,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Next / Mulai button
                  GestureDetector(
                    onTap: () {
                      if (_currentPage < _pages.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        context.go('/config');
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _currentPage == _pages.length - 1
                            ? AppColors.accent
                            : AppColors.primary,
                        border: Border.all(color: Colors.black, width: 2.5),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black,
                              offset: Offset(4, 4),
                              blurRadius: 0)
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: Center(
                        child: Text(
                          _currentPage == _pages.length - 1
                              ? '🚀 Mulai Sekarang'
                              : 'Lanjut →',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: _currentPage == _pages.length - 1
                                ? Colors.black
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                  if (_currentPage == _pages.length - 1) ...[
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: () => context.go('/config'),
                      child: Text(
                        '⚙️ Pengaturan Gateway Zigbee MQTT',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
