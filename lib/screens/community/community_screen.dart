import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:jaga_tani/core/theme/app_colors.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  int _selectedCategory = 0;
  final Set<int> _savedPosts = {};
  final Set<int> _likedPosts = {};

  final List<String> _categories = [
    'Semua',
    'Tips & Trik',
    'Hama & Penyakit',
    'Pupuk',
    'Irigasi',
    'Cuaca',
    'Pasar',
  ];

  final List<Map<String, dynamic>> _posts = [
    {
      'id': 0,
      'avatar': '👨‍🌾',
      'author': 'Pak Slamet',
      'time': '2 jam lalu',
      'title': 'Tips mengatasi daun padi menguning di musim kemarau',
      'content':
          'Musim kemarau sering bikin daun padi jadi kuning. Setelah saya riset dan konsultasi sama penyuluh, ternyata ada beberapa penyebab utama dan cara mengatasinya yang bisa dicoba...',
      'category': 'Hama & Penyakit',
      'categoryColor': Color(0xFFE63946),
      'likes': 45,
      'comments': 12,
    },
    {
      'id': 1,
      'avatar': '👩‍🌾',
      'author': 'Bu Sari',
      'time': '5 jam lalu',
      'title': 'Pengalaman pakai sensor pH: pH 5.8 bikin hasil padi saya turun drastis!',
      'content':
          'Baru tahu kalau pH tanah saya cuma 5.8 setelah pasang sensor IoT dari Jaga Tani. Ternyata itulah kenapa hasil panen padi saya turun 30% dibanding musim sebelumnya...',
      'category': 'Tips & Trik',
      'categoryColor': Color(0xFF1A4D2E),
      'likes': 89,
      'comments': 34,
    },
    {
      'id': 2,
      'avatar': '🧑‍🌾',
      'author': 'Pak Dedi',
      'time': '1 hari lalu',
      'title': 'Berapa dosis pupuk urea yang tepat untuk jagung 1 Ha?',
      'content':
          'Mau tanya ke teman-teman petani jagung. Saya punya lahan 1 Ha dengan jenis tanah lempung berpasir. Menurut pengalaman, berapa kg urea yang ideal dan kapan waktu pemupukan yang paling efektif?',
      'category': 'Pupuk',
      'categoryColor': Color(0xFF9C27B0),
      'likes': 23,
      'comments': 18,
    },
    {
      'id': 3,
      'avatar': '👨‍🌾',
      'author': 'Pak Rudi',
      'time': '1 hari lalu',
      'title': 'Harga cabai di pasar Surabaya naik 20% minggu ini',
      'content':
          'Update harga cabai terbaru: Cabai rawit merah sekarang Rp 85.000/kg, naik dari Rp 70.000 minggu lalu. Cabai keriting juga ikut naik ke Rp 55.000/kg. Bagus buat yang mau panen sekarang!',
      'category': 'Pasar',
      'categoryColor': Color(0xFFFF6B35),
      'likes': 67,
      'comments': 5,
    },
    {
      'id': 4,
      'avatar': '👩‍🌾',
      'author': 'Bu Dewi',
      'time': '2 hari lalu',
      'title': 'Cara setting irigasi tetes untuk lahan cabai sempit',
      'content':
          'Untuk lahan cabai yang lahannya sempit kayak punya saya (0.3 Ha), irigasi tetes ternyata jauh lebih efisien. Saya bisa hemat air sampai 40% dibanding irigasi biasa. Begini cara setting-nya...',
      'category': 'Irigasi',
      'categoryColor': Color(0xFF2196F3),
      'likes': 31,
      'comments': 9,
    },
  ];

  List<Map<String, dynamic>> get _filteredPosts {
    if (_selectedCategory == 0) return _posts;
    final cat = _categories[_selectedCategory];
    return _posts.where((p) => p['category'] == cat).toList();
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
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/dashboard');
              }
            },
          ),
          title: Text(
            '👥 Komunitas Tani',
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          actions: [
            GestureDetector(
              onTap: _showCreatePostSheet,
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  border: Border.all(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 0)],
                ),
                child: const Icon(Iconsax.add, color: Colors.black, size: 20),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            _buildCategoryFilter(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildCreatePrompt(),
                  const SizedBox(height: 16),
                  if (_filteredPosts.isEmpty)
                    _buildEmptyState()
                  else
                    ..._filteredPosts
                        .map((post) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _buildPostCard(post),
                            ))
                        ,
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Category Filter ──────────────────────────────────────────────────────────
  Widget _buildCategoryFilter() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SizedBox(
        height: 40,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final isSelected = index == _selectedCategory;
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.background,
                  border: Border.all(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected
                      ? const [BoxShadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 0)]
                      : null,
                ),
                child: Text(
                  _categories[index],
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ─── Create Prompt ────────────────────────────────────────────────────────────
  Widget _buildCreatePrompt() {
    return GestureDetector(
      onTap: _showCreatePostSheet,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.accent,
          border: Border.all(color: Colors.black, width: 2),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0)],
        ),
        child: Row(
          children: [
            const Text('✍️', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Bagikan pengalaman bertani Anda...',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                border: Border.all(color: Colors.black, width: 2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Posting',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Post Card ────────────────────────────────────────────────────────────────
  Widget _buildPostCard(Map<String, dynamic> post) {
    final postId = post['id'] as int;
    final isLiked = _likedPosts.contains(postId);
    final isSaved = _savedPosts.contains(postId);
    final likes = (post['likes'] as int) + (isLiked ? 1 : 0);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    border: Border.all(color: Colors.black, width: 2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(post['avatar'], style: const TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post['author'],
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        post['time'],
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildCategoryChip(post['category'], post['categoryColor']),
              ],
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Text(
              post['title'],
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                height: 1.35,
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Text(
              post['content'],
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
          // Divider
          const Divider(height: 1, color: Colors.black12),
          // Footer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                _buildActionButton(
                  icon: isLiked ? Iconsax.like_15 : Iconsax.like_1,
                  label: '$likes',
                  color: isLiked ? AppColors.danger : AppColors.textSecondary,
                  onTap: () => setState(() {
                    if (isLiked) {
                      _likedPosts.remove(postId);
                    } else {
                      _likedPosts.add(postId);
                    }
                  }),
                ),
                const SizedBox(width: 16),
                _buildActionButton(
                  icon: Iconsax.message,
                  label: '${post['comments']}',
                  color: AppColors.textSecondary,
                  onTap: () {},
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() {
                    if (isSaved) {
                      _savedPosts.remove(postId);
                    } else {
                      _savedPosts.add(postId);
                    }
                  }),
                  child: Row(
                    children: [
                      Icon(
                        isSaved ? Iconsax.bookmark5 : Iconsax.bookmark,
                        size: 16,
                        color: isSaved ? AppColors.primary : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Simpan',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSaved ? AppColors.primary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Empty State ──────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            const Text('🌾', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              'Belum ada postingan',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Jadilah yang pertama berbagi!',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Create Post Bottom Sheet ─────────────────────────────────────────────────
  void _showCreatePostSheet() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String selectedCategory = 'Tips & Trik';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setSheetState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: AppColors.background,
              border: Border(
                top: BorderSide(color: Colors.black, width: 2),
                left: BorderSide(color: Colors.black, width: 2),
                right: BorderSide(color: Colors.black, width: 2),
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      Text(
                        'Buat Postingan Baru',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black, width: 2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.close, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 20, color: Colors.black26),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      0,
                      16,
                      MediaQuery.of(context).viewInsets.bottom + 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Author row
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                border: Border.all(color: Colors.black, width: 2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Text('👨‍🌾', style: TextStyle(fontSize: 20)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Pak Budi Santoso',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Title Field
                        _buildSheetLabel('Judul Postingan *'),
                        const SizedBox(height: 6),
                        _buildTextField(
                          controller: titleController,
                          hint: 'Contoh: Tips mengatasi hama wereng...',
                          maxLines: 1,
                        ),
                        const SizedBox(height: 14),
                        // Content Field
                        _buildSheetLabel('Ceritakan Pengalaman Anda *'),
                        const SizedBox(height: 6),
                        _buildTextField(
                          controller: contentController,
                          hint: 'Ceritakan pengalaman, pertanyaan, atau tips Anda...',
                          maxLines: 5,
                        ),
                        const SizedBox(height: 14),
                        // Category
                        _buildSheetLabel('Kategori'),
                        const SizedBox(height: 6),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            border: Border.all(color: Colors.black, width: 2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedCategory,
                              isExpanded: true,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              items: _categories.skip(1).map((cat) {
                                return DropdownMenuItem(
                                  value: cat,
                                  child: Text(cat),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setSheetState(() => selectedCategory = val);
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Post Button
                        GestureDetector(
                          onTap: () {
                            final title = titleController.text.trim();
                            final content = contentController.text.trim();
                            if (title.isEmpty || content.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Judul dan isi postingan tidak boleh kosong!',
                                    style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
                                  ),
                                  backgroundColor: AppColors.danger,
                                ),
                              );
                              return;
                            }

                            Color catColor = const Color(0xFF1A4D2E);
                            switch (selectedCategory) {
                              case 'Hama & Penyakit':
                                catColor = const Color(0xFFE63946);
                                break;
                              case 'Pupuk':
                                catColor = const Color(0xFF9C27B0);
                                break;
                              case 'Irigasi':
                                catColor = const Color(0xFF2196F3);
                                break;
                              case 'Pasar':
                                catColor = const Color(0xFFFF6B35);
                                break;
                              case 'Cuaca':
                                catColor = const Color(0xFF009688);
                                break;
                              default:
                                catColor = const Color(0xFF1A4D2E);
                            }

                            final newPost = {
                              'id': DateTime.now().millisecondsSinceEpoch,
                              'avatar': '👨‍🌾',
                              'author': 'Pak Budi Santoso',
                              'time': 'Baru saja',
                              'title': title,
                              'content': content,
                              'category': selectedCategory,
                              'categoryColor': catColor,
                              'likes': 0,
                              'comments': 0,
                            };

                            setState(() {
                              _posts.insert(0, newPost);
                              _selectedCategory = 0; // Tampilkan 'Semua' agar postingan langsung terlihat
                            });

                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Postingan berhasil dikirim! 🎉',
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
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('📢', style: TextStyle(fontSize: 18)),
                                const SizedBox(width: 8),
                                Text(
                                  'Posting Sekarang',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
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
              ],
            ),
          );
        });
      },
    );
  }

  Widget _buildSheetLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.spaceGrotesk(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required int maxLines,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: GoogleFonts.spaceGrotesk(fontSize: 14, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.spaceGrotesk(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(12),
        ),
      ),
    );
  }
}
