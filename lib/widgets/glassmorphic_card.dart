import 'package:flutter/material.dart';

/// A card with a glassmorphism visual effect — backdrop blur, translucent
/// background, subtle border, and optional glow — replicating the
/// `.search-card` / `.video-card` CSS styles from index.css.
class GlassmorphicCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color backgroundColor;
  final Color borderColor;
  final List<BoxShadow>? boxShadow;

  const GlassmorphicCard({
    super.key,
    required this.child,
    this.borderRadius = 18.0,
    this.padding = const EdgeInsets.all(20.0),
    this.backgroundColor = const Color(0xD9121A2B),
    this.borderColor = const Color(0x14FFFFFF),
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: Colors.black.withAlpha(89), // ~0.35 opacity
                blurRadius: 36,
                offset: const Offset(0, 12),
              ),
              const BoxShadow(
                color: Color(0x1F3B82F6), // card-glow
                blurRadius: 24,
                spreadRadius: 0,
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: padding != null
            ? Padding(padding: padding!, child: child)
            : child,
      ),
    );
  }
}
