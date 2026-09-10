import 'package:flutter/material.dart';

/// A circular progress indicator with an optional percentage label,
/// used during the download phase.
class DownloadProgressIndicator extends StatelessWidget {
  final double progress; // 0.0 – 1.0
  final double size;
  final double strokeWidth;
  final Color color;
  final bool showLabel;

  const DownloadProgressIndicator({
    super.key,
    required this.progress,
    this.size = 48.0,
    this.strokeWidth = 3.5,
    this.color = const Color(0xFF3B82F6),
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).round();
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: strokeWidth,
            backgroundColor: color.withAlpha(51), // 20% opacity track
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          if (showLabel)
            Text(
              '$pct%',
              style: TextStyle(
                fontSize: size * 0.22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}

/// Animated spinning indicator — replicates the CSS `.spinner`.
class SpinnerWidget extends StatefulWidget {
  final double size;
  final Color color;
  final Color trackColor;

  const SpinnerWidget({
    super.key,
    this.size = 18.0,
    this.color = Colors.white,
    this.trackColor = const Color(0x4DFFFFFF), // rgba(255,255,255,0.30)
  });

  @override
  State<SpinnerWidget> createState() => _SpinnerWidgetState();
}

class _SpinnerWidgetState extends State<SpinnerWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => CircularProgressIndicator(
          value: null, // indeterminate
          strokeWidth: 2.0,
          backgroundColor: widget.trackColor,
          valueColor: AlwaysStoppedAnimation<Color>(widget.color),
        ),
      ),
    );
  }
}
