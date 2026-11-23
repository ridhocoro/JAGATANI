import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:jaga_tani/core/theme/app_colors.dart';

/// Tab model for [JagaTaniBottomNav].
class _NavItem {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

/// Neubrutalism bottom navigation bar with 5 tabs.
///
/// The selected tab receives a yellow [AppColors.accent] background
/// with a black border. Inactive tabs use the primary dark green color.
class JagaTaniBottomNav extends StatelessWidget {
  const JagaTaniBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabChanged,
  });

  final int currentIndex;
  final ValueChanged<int> onTabChanged;

  static const List<_NavItem> _items = [
    _NavItem(
      label: 'Beranda',
      icon: Iconsax.home,
      activeIcon: Iconsax.home5,
    ),
    _NavItem(
      label: 'Monitor',
      icon: Iconsax.chart,
      activeIcon: Iconsax.chart5,
    ),
    _NavItem(
      label: 'Kontrol',
      icon: Iconsax.setting_2,
      activeIcon: Iconsax.setting5,
    ),
    _NavItem(
      label: 'AI',
      icon: Iconsax.star,
      activeIcon: Iconsax.star5,
    ),
    _NavItem(
      label: 'Profil',
      icon: Iconsax.user,
      activeIcon: Iconsax.user5,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 2),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            offset: Offset(0, -3),
            blurRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              _items.length,
              (index) => _NavTabItem(
                item: _items[index],
                isSelected: currentIndex == index,
                onTap: () => onTabChanged(index),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTabItem extends StatelessWidget {
  const _NavTabItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(color: AppColors.border, width: 2)
              : Border.all(color: Colors.transparent, width: 2),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: AppColors.shadow,
                    offset: Offset(2, 2),
                    blurRadius: 0,
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? item.activeIcon : item.icon,
              size: 22,
              color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
