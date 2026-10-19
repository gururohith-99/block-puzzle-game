import 'package:flutter/material.dart';
import '../core/theme/game_colors.dart';

class CommonButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final Color? color;
  final bool isSecondary;

  const CommonButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color,
    this.isSecondary = false,
  });

  @override
  State<CommonButton> createState() => _CommonButtonState();
}

class _CommonButtonState extends State<CommonButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.color ?? GameColors.primaryAccent;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: widget.isSecondary
                ? (isDark ? GameColors.darkSurface : GameColors.lightSurface)
                : themeColor,
            borderRadius: BorderRadius.circular(20),
            gradient: widget.isSecondary
                ? null
                : LinearGradient(
                    colors: [
                      themeColor,
                      Color.alphaBlend(Colors.black.withValues(alpha: 0.2), themeColor),
                    ],
                  ),
            border: Border.all(
              color: widget.isSecondary
                  ? (isDark ? Colors.white12 : Colors.black12)
                  : Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (widget.isSecondary ? Colors.black : themeColor)
                    .withValues(alpha: isDark ? 0.3 : 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  color: widget.isSecondary
                      ? (isDark ? Colors.white : Colors.black87)
                      : Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      color: widget.isSecondary
                          ? (isDark ? Colors.white : Colors.black87)
                          : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
