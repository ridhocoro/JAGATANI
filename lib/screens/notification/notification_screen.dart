import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:jaga_tani/core/theme/app_colors.dart';
import 'package:jaga_tani/data/services/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _service = NotificationService();
  int _selectedFilterIndex = 0; // 0: Semua, 1: Peringatan, 2: AI, 3: Irigasi

  @override
  void initState() {
    super.initState();
    _service.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  List<AppNotificationItem> _getFilteredNotifications() {
    final list = _service.notifications;
    switch (_selectedFilterIndex) {
      case 1:
        return list
            .where((n) => n.category == NotificationCategory.critical)
            .toList();
      case 2:
        return list
            .where((n) => n.category == NotificationCategory.ai)
            .toList();
      case 3:
        return list
            .where((n) => n.category == NotificationCategory.actuator)
            .toList();
      default:
        return list;
    }
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit yang lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam yang lalu';
    return '${diff.inDays} hari yang lalu';
  }

  @override
  Widget build(BuildContext context) {
    final items = _getFilteredNotifications();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
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
          centerTitle: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/dashboard');
              }
            },
          ),
        title: Text(
          'Pusat Notifikasi',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _service.markAllAsRead();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Semua notifikasi ditandai sudah dibaca',
                      style: GoogleFonts.spaceGrotesk()),
                  backgroundColor: AppColors.primary,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Text(
              'Baca Semua',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner Test Notification ke HP
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              border: Border.all(color: Colors.black, width: 2),
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black, width: 1.5),
                  ),
                  child: const Icon(Iconsax.notification_bing, color: Colors.black, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Uji Notifikasi ke HP Anda',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Tekan tombol untuk memunculkan notifikasi di baris status HP',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    await _service.sendTestNotification();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Notifikasi telah dikirim ke HP Anda!',
                            style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600),
                          ),
                          backgroundColor: AppColors.success,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Colors.black, width: 1.5),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Tes HP',
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

          // Filter pills
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Semua (${_service.notifications.length})', 0),
                  const SizedBox(width: 8),
                  _buildFilterChip('🚨 Peringatan', 1),
                  const SizedBox(width: 8),
                  _buildFilterChip('🤖 AI', 2),
                  const SizedBox(width: 8),
                  _buildFilterChip('🚿 Irigasi', 3),
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          // List notifikasi
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Iconsax.notification_1, size: 54, color: AppColors.textSecondary),
                        const SizedBox(height: 12),
                        Text(
                          'Belum ada notifikasi',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final notif = items[index];
                      return _buildNotificationCard(notif);
                    },
                  ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildFilterChip(String label, int index) {
    final isSelected = _selectedFilterIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilterIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black, width: 1.5),
          boxShadow: isSelected
              ? const [BoxShadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 0)]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(AppNotificationItem notif) {
    Color badgeColor;
    Color iconBgColor;
    IconData iconData;

    switch (notif.category) {
      case NotificationCategory.critical:
        badgeColor = AppColors.danger;
        iconBgColor = AppColors.danger.withValues(alpha: 0.15);
        iconData = Iconsax.warning_2;
        break;
      case NotificationCategory.ai:
        badgeColor = const Color(0xFF673AB7);
        iconBgColor = const Color(0xFF673AB7).withValues(alpha: 0.15);
        iconData = Iconsax.cpu_charge;
        break;
      case NotificationCategory.actuator:
        badgeColor = AppColors.primary;
        iconBgColor = AppColors.primary.withValues(alpha: 0.15);
        iconData = Iconsax.drop;
        break;
      case NotificationCategory.reminder:
        badgeColor = AppColors.warning;
        iconBgColor = AppColors.warning.withValues(alpha: 0.15);
        iconData = Iconsax.clock;
        break;
    }

    return GestureDetector(
      onTap: () {
        if (!notif.isRead) {
          _service.markAsRead(notif.id);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: notif.isRead ? AppColors.surface : AppColors.surface,
          border: Border.all(
            color: Colors.black,
            width: notif.isRead ? 1.8 : 2.2,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black,
              offset: Offset(notif.isRead ? 2 : 3.5, notif.isRead ? 2 : 3.5),
              blurRadius: 0,
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: badgeColor, width: 1.5),
              ),
              child: Icon(iconData, color: badgeColor, size: 20),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notif.title,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 13.5,
                            fontWeight: notif.isRead ? FontWeight.w700 : FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (!notif.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.danger,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif.body,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatTimeAgo(notif.timestamp),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
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
}
