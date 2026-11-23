import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jaga_tani/core/theme/app_colors.dart';
import 'package:jaga_tani/core/utils/sensor_helper.dart';
import 'dart:math' as math;

/// A circular arc gauge rendered via [CustomPainter].
///
/// The arc sweeps 240° (from 150° to 390°). The fill color adapts
/// to [SensorStatus]: green (normal), orange (warning), red (critical).
class SensorGauge extends StatefulWidget {
  const SensorGauge({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.label,
    required this.unit,
    required this.color,
    required this.status,
    this.size = 160.0,
    this.strokeWidth = 14.0,
  });

  final double value;
  final double min;
  final double max;
  final String label;
  final String unit;
  final Color color;
  final SensorStatus status;
  final double size;
  final double strokeWidth;

  @override
  State<SensorGauge> createState() => _SensorGaugeState();
}

class _SensorGaugeState extends State<SensorGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation = Tween<double>(begin: 0, end: _fraction).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(SensorGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: _fraction,
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _fraction {
    final range = widget.max - widget.min;
    if (range == 0) return 0;
    return ((widget.value - widget.min) / range).clamp(0.0, 1.0);
  }

  Color get _gaugeColor {
    switch (widget.status) {
      case SensorStatus.optimal:
        return AppColors.success;
      case SensorStatus.warning:
        return AppColors.warning;
      case SensorStatus.critical:
        return AppColors.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size * 0.85,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, _) {
              return CustomPaint(
                painter: _GaugePainter(
                  fraction: _animation.value,
                  gaugeColor: _gaugeColor,
                  trackColor: AppColors.surfaceAlt,
                  strokeWidth: widget.strokeWidth,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 14),
                      Text(
                        widget.value.toStringAsFixed(
                          widget.value.truncateToDouble() == widget.value ? 0 : 1,
                        ),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: widget.size * 0.18,
                          fontWeight: FontWeight.w800,
                          color: _gaugeColor,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        widget.unit,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: widget.size * 0.09,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _gaugeColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: _gaugeColor, width: 1),
                        ),
                        child: Text(
                          SensorHelper.getStatusLabel(widget.status),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: widget.size * 0.07,
                            fontWeight: FontWeight.w700,
                            color: _gaugeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Min / Max labels
        SizedBox(
          width: widget.size,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: widget.strokeWidth * 0.5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.min.toStringAsFixed(0),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  widget.max.toStringAsFixed(0),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),

        // Label
        Text(
          widget.label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// Custom painter that draws the arc gauge track and filled arc.
class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.fraction,
    required this.gaugeColor,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double fraction;
  final Color gaugeColor;
  final Color trackColor;
  final double strokeWidth;

  // Gauge sweeps 240° starting at 150° (bottom-left)
  static const double _startAngle = 150.0;
  static const double _sweepAngle = 240.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + size.height * 0.06);
    final radius = (math.min(size.width, size.height) / 2) - strokeWidth;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // --- Track arc ---
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      _toRad(_startAngle),
      _toRad(_sweepAngle),
      false,
      trackPaint,
    );

    // --- Black border arc (slightly wider) ---
    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      _toRad(_startAngle),
      _toRad(_sweepAngle),
      false,
      borderPaint,
    );

    // Redraw track on top of border
    canvas.drawArc(
      rect,
      _toRad(_startAngle),
      _toRad(_sweepAngle),
      false,
      trackPaint,
    );

    if (fraction <= 0) return;

    // --- Filled arc ---
    final fillPaint = Paint()
      ..color = gaugeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      _toRad(_startAngle),
      _toRad(_sweepAngle * fraction),
      false,
      fillPaint,
    );

    // --- Tip dot ---
    final tipAngle = _toRad(_startAngle + _sweepAngle * fraction);
    final tipX = center.dx + radius * math.cos(tipAngle);
    final tipY = center.dy + radius * math.sin(tipAngle);

    final tipBorderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(tipX, tipY), strokeWidth * 0.65, tipBorderPaint);

    final tipFillPaint = Paint()
      ..color = gaugeColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(tipX, tipY), strokeWidth * 0.45, tipFillPaint);
  }

  double _toRad(double degrees) => degrees * math.pi / 180;

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.fraction != fraction ||
      old.gaugeColor != gaugeColor ||
      old.strokeWidth != strokeWidth;
}
