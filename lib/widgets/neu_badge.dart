import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jaga_tani/core/theme/app_colors.dart';

/// A small Neubrutalism pill-shaped badge.
///
/// Use the factory constructors for semantic priorities:
/// - [NeuBadge.urgent] → Red, label "Mendesak"
/// - [NeuBadge.attention] → Orange, label "Perhatian"
/// - [NeuBadge.safe] → Green, label "Aman"
class NeuBadge extends StatelessWidget {
  const NeuBadge({
    super.key,
    required this.label,
    required this.color,
    this.textColor = Colors.black,
    this.icon,
  });

  /// Factory for urgent/high-priority badges (red).
  factory NeuBadge.urgent({String label = 'Mendesak'}) => NeuBadge(
        label: label,
        color: AppColors.danger,
        textColor: Colors.white,
        icon: Icons.priority_high_rounded,
      );

  /// Factory for attention/medium-priority badges (orange).
  factory NeuBadge.attention({String label = 'Perhatian'}) => NeuBadge(
        label: label,
        color: AppColors.warning,
        textColor: Colors.white,
        icon: Icons.warning_amber_rounded,
      );

  /// Factory for safe/low-priority badges (green).
  factory NeuBadge.safe({String label = 'Aman'}) => NeuBadge(
        label: label,
        color: AppColors.success,
        textColor: Colors.white,
        icon: Icons.check_circle_outline_rounded,
      );

  final String label;
  final Color color;
  final Color textColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            offset: Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
