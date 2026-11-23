import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jaga_tani/core/theme/app_colors.dart';
import 'package:jaga_tani/core/utils/sensor_helper.dart';

/// Displays the direction of a sensor value trend.
enum TrendDirection { up, down, stable }

/// A Neubrutalism card that displays a single sensor reading prominently.
///
/// Shows [value] + [unit] in large text, [label] below, a status dot,
/// and an optional trend arrow.
class SensorCard extends StatelessWidget {
  const SensorCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.status,
    this.trend,
    this.onTap,
  });

  final String label;
  final String value;
  final String unit;

  /// An emoji string or icon widget displayed at the top of the card.
  final Widget icon;
  final Color color;
  final SensorStatus status;

  /// Optional trend direction indicator.
  final TrendDirection? trend;
  final VoidCallback? onTap;

  Color get _statusColor {
    switch (status) {
      case SensorStatus.optimal:
        return AppColors.success;
      case SensorStatus.warning:
        return AppColors.warning;
      case SensorStatus.critical:
        return AppColors.danger;
    }
  }

  String get _trendArrow {
    switch (trend) {
      case TrendDirection.up:
        return '↑';
      case TrendDirection.down:
        return '↓';
      case TrendDirection.stable:
        return '→';
      case null:
        return '';
    }
  }

  Color get _trendColor {
    switch (trend) {
      case TrendDirection.up:
        return AppColors.warning;
      case TrendDirection.down:
        return AppColors.sensorHumid;
      case TrendDirection.stable:
        return AppColors.textSecondary;
      case null:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border, width: 2),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              offset: Offset(4, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top color strip with icon
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
                border: Border(
                  bottom: BorderSide(color: color.withOpacity(0.4), width: 1.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  icon,
                  // Status indicator dot
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _statusColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border, width: 1),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        SensorHelper.getStatusLabel(status),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _statusColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Value area
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: color,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      unit,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  if (trend != null) ...[
                    const Spacer(),
                    Text(
                      _trendArrow,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _trendColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Label
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
