import 'package:flutter/material.dart';
import 'package:jaga_tani/core/theme/app_colors.dart';

/// A Neubrutalism-styled card widget with hard shadow and optional press animation.
///
/// When [onTap] is provided, the card animates its shadow on press,
/// giving the illusion of the card "pressing in".
class NeuCard extends StatefulWidget {
  const NeuCard({
    super.key,
    required this.child,
    this.backgroundColor,
    this.padding,
    this.onTap,
    this.borderRadius = 12.0,
    this.shadowOffset = 4.0,
    this.borderColor,
    this.borderWidth = 2.0,
  });

  final Widget child;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double borderRadius;
  final double shadowOffset;
  final Color? borderColor;
  final double borderWidth;

  @override
  State<NeuCard> createState() => _NeuCardState();
}

class _NeuCardState extends State<NeuCard> with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  void _onTapDown(TapDownDetails _) {
    if (widget.onTap != null) {
      setState(() => _isPressed = true);
    }
  }

  void _onTapUp(TapUpDetails _) {
    if (widget.onTap != null) {
      setState(() => _isPressed = false);
    }
  }

  void _onTapCancel() {
    if (widget.onTap != null) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double currentOffset = _isPressed ? 1.0 : widget.shadowOffset;
    final Color bColor = widget.borderColor ?? AppColors.border;
    final Color bgColor = widget.backgroundColor ?? AppColors.surface;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeInOut,
        transform: Matrix4.translationValues(
          _isPressed ? widget.shadowOffset - currentOffset : 0,
          _isPressed ? widget.shadowOffset - currentOffset : 0,
          0,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(color: bColor, width: widget.borderWidth),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              offset: Offset(currentOffset, currentOffset),
              blurRadius: 0,
            ),
          ],
        ),
        padding: widget.padding,
        child: widget.child,
      ),
    );
  }
}
