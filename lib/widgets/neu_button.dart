import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jaga_tani/core/theme/app_colors.dart';

/// Size variants for [NeuButton].
enum NeuButtonSize { small, medium, large }

/// A Neubrutalism-styled button with hard shadow press animation.
///
/// Supports optional icon, full-width layout, disabled state, and
/// three size presets via [NeuButtonSize].
class NeuButton extends StatefulWidget {
  const NeuButton({
    super.key,
    required this.label,
    this.onPressed,
    this.backgroundColor,
    this.textColor = Colors.black,
    this.icon,
    this.isFullWidth = false,
    this.size = NeuButtonSize.medium,
    this.borderRadius = 8.0,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color textColor;
  final IconData? icon;
  final bool isFullWidth;
  final NeuButtonSize size;
  final double borderRadius;

  @override
  State<NeuButton> createState() => _NeuButtonState();
}

class _NeuButtonState extends State<NeuButton> {
  bool _isPressed = false;

  bool get _isDisabled => widget.onPressed == null;

  void _onTapDown(TapDownDetails _) {
    if (!_isDisabled) setState(() => _isPressed = true);
  }

  void _onTapUp(TapUpDetails _) {
    if (!_isDisabled) setState(() => _isPressed = false);
  }

  void _onTapCancel() {
    if (!_isDisabled) setState(() => _isPressed = false);
  }

  /// Resolves padding based on [NeuButtonSize].
  EdgeInsets get _padding {
    switch (widget.size) {
      case NeuButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      case NeuButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 12);
      case NeuButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 28, vertical: 16);
    }
  }

  /// Resolves font size based on [NeuButtonSize].
  double get _fontSize {
    switch (widget.size) {
      case NeuButtonSize.small:
        return 12;
      case NeuButtonSize.medium:
        return 14;
      case NeuButtonSize.large:
        return 16;
    }
  }

  /// Resolves icon size based on [NeuButtonSize].
  double get _iconSize {
    switch (widget.size) {
      case NeuButtonSize.small:
        return 14;
      case NeuButtonSize.medium:
        return 18;
      case NeuButtonSize.large:
        return 22;
    }
  }

  @override
  Widget build(BuildContext context) {
    const double shadowSize = 3.0;
    final double currentShadow = _isPressed ? 0.0 : shadowSize;
    final Color bgColor = _isDisabled
        ? AppColors.surfaceAlt
        : (widget.backgroundColor ?? AppColors.accent);
    final Color textColor = _isDisabled ? AppColors.textSecondary : widget.textColor;

    final Widget buttonContent = Row(
      mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: _iconSize, color: textColor),
          const SizedBox(width: 8),
        ],
        Text(
          widget.label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: _fontSize,
            fontWeight: FontWeight.w700,
            color: textColor,
            height: 1.0,
          ),
        ),
      ],
    );

    return GestureDetector(
      onTap: _isDisabled ? null : widget.onPressed,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeInOut,
        width: widget.isFullWidth ? double.infinity : null,
        transform: Matrix4.translationValues(
          _isPressed ? shadowSize : 0,
          _isPressed ? shadowSize : 0,
          0,
        ),
        padding: _padding,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: _isDisabled ? AppColors.textSecondary : Colors.black,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: _isDisabled ? Colors.transparent : Colors.black,
              offset: Offset(currentShadow, currentShadow),
              blurRadius: 0,
            ),
          ],
        ),
        child: buttonContent,
      ),
    );
  }
}
