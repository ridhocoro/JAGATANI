import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jaga_tani/core/theme/app_colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _namaController = TextEditingController();
  final _hpController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();
  final _lahanController = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String _selectedProvinsi = 'Jawa Tengah';
  String _selectedTanaman = 'Padi';

  final List<String> _provinsiList = [
    'Jawa Tengah', 'Jawa Barat', 'Jawa Timur', 'Sumatera Utara', 'Sulawesi Selatan'
  ];
  final List<String> _tanamanList = [
    'Padi', 'Jagung', 'Cabai', 'Tomat', 'Kedelai'
  ];

  @override
  void dispose() {
    _namaController.dispose();
    _hpController.dispose();
    _emailController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    _lahanController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) context.go('/dashboard');
  }

  Widget _buildLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: GoogleFonts.spaceGrotesk(
              fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
      );

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required String emoji,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    VoidCallback? onToggleObscure,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0)
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        style: GoogleFonts.spaceGrotesk(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.spaceGrotesk(color: AppColors.textSecondary, fontSize: 14),
          prefixIcon: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(emoji, style: const TextStyle(fontSize: 18))),
          suffixIcon: onToggleObscure != null
              ? IconButton(
                  icon: Icon(obscure ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textSecondary, size: 20),
                  onPressed: onToggleObscure)
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
    required String emoji,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0)
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500),
                items: items
                    .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e,
                            style: GoogleFonts.spaceGrotesk(fontSize: 14))))
                    .toList(),
                onChanged: onChanged,
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              color: AppColors.primary,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 20,
                bottom: 32,
                left: 24,
                right: 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white30, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.arrow_back, color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Text('Kembali',
                              style: GoogleFonts.spaceGrotesk(
                                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Daftar Akun\nBaru 🌱',
                      style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 30,
                          height: 1.2)),
                  const SizedBox(height: 6),
                  Text('Bergabung dan mulai pantau lahan Anda',
                      style: GoogleFonts.spaceGrotesk(
                          color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),

            // Form
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),

                  _buildLabel('Nama Lengkap'),
                  _buildTextField(
                      controller: _namaController,
                      hint: 'Pak Budi Santoso',
                      emoji: '👤'),

                  _buildLabel('No. HP / WhatsApp'),
                  _buildTextField(
                      controller: _hpController,
                      hint: '08123456789',
                      emoji: '📱',
                      keyboardType: TextInputType.phone),

                  _buildLabel('Email'),
                  _buildTextField(
                      controller: _emailController,
                      hint: 'budi@email.com',
                      emoji: '📧',
                      keyboardType: TextInputType.emailAddress),

                  _buildLabel('Kata Sandi'),
                  _buildTextField(
                      controller: _passController,
                      hint: 'Min. 8 karakter',
                      emoji: '🔒',
                      obscure: _obscurePass,
                      onToggleObscure: () =>
                          setState(() => _obscurePass = !_obscurePass)),

                  _buildLabel('Konfirmasi Kata Sandi'),
                  _buildTextField(
                      controller: _confirmPassController,
                      hint: 'Ulangi kata sandi',
                      emoji: '🔒',
                      obscure: _obscureConfirm,
                      onToggleObscure: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm)),

                  _buildLabel('Provinsi'),
                  _buildDropdown(
                      label: 'Provinsi',
                      value: _selectedProvinsi,
                      items: _provinsiList,
                      onChanged: (v) => setState(() => _selectedProvinsi = v!),
                      emoji: '📍'),

                  _buildLabel('Luas Lahan (Hektar)'),
                  _buildTextField(
                      controller: _lahanController,
                      hint: 'Contoh: 1.5',
                      emoji: '🌾',
                      keyboardType: TextInputType.number),

                  _buildLabel('Jenis Tanaman Utama'),
                  _buildDropdown(
                      label: 'Tanaman',
                      value: _selectedTanaman,
                      items: _tanamanList,
                      onChanged: (v) => setState(() => _selectedTanaman = v!),
                      emoji: '🌱'),

                  const SizedBox(height: 8),

                  // Register button
                  GestureDetector(
                    onTap: _isLoading ? null : _register,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
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
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.black, strokeWidth: 2.5))
                            : Text('DAFTAR SEKARANG',
                                style: GoogleFonts.spaceGrotesk(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black,
                                    letterSpacing: 1)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: GestureDetector(
                      onTap: () => context.go('/login'),
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.spaceGrotesk(
                              fontSize: 14, color: AppColors.textSecondary),
                          children: [
                            const TextSpan(text: 'Sudah punya akun? '),
                            TextSpan(
                                text: 'Masuk',
                                style: GoogleFonts.spaceGrotesk(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                    decoration: TextDecoration.underline)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
