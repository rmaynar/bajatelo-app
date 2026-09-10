import 'package:flutter/material.dart';

/// A platform chip pill that replicates the `.platform-pill` CSS style.
class PlatformChip extends StatefulWidget {
  final String icon;
  final String name;

  const PlatformChip({
    super.key,
    required this.icon,
    required this.name,
  });

  @override
  State<PlatformChip> createState() => _PlatformChipState();
}

class _PlatformChipState extends State<PlatformChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform:
            Matrix4.translationValues(0, _hovered ? -1.0 : 0.0, 0),
        decoration: BoxDecoration(
          color: _hovered
              ? const Color(0x14FFFFFF) // rgba(255,255,255,0.08)
              : const Color(0x0AFFFFFF), // rgba(255,255,255,0.04)
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(
            color: _hovered
                ? const Color(0x29FFFFFF) // rgba(255,255,255,0.16)
                : const Color(0x14FFFFFF), // rgba(255,255,255,0.08)
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.icon,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(width: 5),
            Text(
              widget.name,
              style: TextStyle(
                fontSize: 12.0,
                fontWeight: FontWeight.w500,
                color: _hovered
                    ? Colors.white
                    : const Color(0xFFCBD5E1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
