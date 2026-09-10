import 'package:flutter/material.dart';

/// A button with a linear gradient background, matching the
/// `.btn-fetch`, `.btn-video`, `.btn-audio` CSS styles.
///
/// Provides a subtle elevation lift on hover/press via [AnimatedContainer].
class GradientButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final List<Color> gradientColors;
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final List<BoxShadow> shadowColors;
  final double? minWidth;
  final double? height;

  const GradientButton({
    super.key,
    required this.onPressed,
    required this.gradientColors,
    required this.child,
    this.borderRadius = 12.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    this.shadowColors = const [],
    this.minWidth,
    this.height,
  });

  /// Red gradient — matches `.btn-fetch` (Search button).
  factory GradientButton.red({
    Key? key,
    required VoidCallback? onPressed,
    required Widget child,
    double? minWidth,
  }) =>
      GradientButton(
        key: key,
        onPressed: onPressed,
        gradientColors: const [Color(0xFFEF4444), Color(0xFFDC2626)],
        shadowColors: [
          BoxShadow(
            color: const Color(0xFFEF4444).withAlpha(89), // 0.35
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
        minWidth: minWidth,
        child: child,
      );

  /// Blue gradient — matches `.btn-video` (Download Video button).
  factory GradientButton.blue({
    Key? key,
    required VoidCallback? onPressed,
    required Widget child,
    double? minWidth,
  }) =>
      GradientButton(
        key: key,
        onPressed: onPressed,
        gradientColors: const [Color(0xFF3B82F6), Color(0xFF2563EB)],
        shadowColors: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withAlpha(77), // 0.30
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        minWidth: minWidth,
        child: child,
      );

  /// Emerald gradient — matches `.btn-audio` (Download Audio button).
  factory GradientButton.emerald({
    Key? key,
    required VoidCallback? onPressed,
    required Widget child,
    double? minWidth,
  }) =>
      GradientButton(
        key: key,
        onPressed: onPressed,
        gradientColors: const [Color(0xFF10B981), Color(0xFF059669)],
        shadowColors: [
          BoxShadow(
            color: const Color(0xFF10B981).withAlpha(77), // 0.30
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        minWidth: minWidth,
        child: child,
      );

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _hovered = false;
  bool _pressed = false;

  bool get _disabled => widget.onPressed == null;

  @override
  Widget build(BuildContext context) {
    final offset = (_hovered && !_disabled) ? -2.0 : 0.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: _disabled
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: _disabled ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.translationValues(0, offset, 0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.gradientColors,
            ),
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: _disabled ? [] : widget.shadowColors,
          ),
          child: Opacity(
            opacity: _disabled ? 0.6 : (_pressed ? 0.85 : 1.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: widget.minWidth ?? 0,
                minHeight: widget.height ?? 0,
              ),
              child: Padding(
                padding: widget.padding,
                child: DefaultTextStyle(
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15.2,
                  ),
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
