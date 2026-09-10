import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bajatelo_app/core/providers/downloader_provider.dart';
import 'package:bajatelo_app/core/theme/app_theme.dart';

/// EN / ES language toggle replicating the `.lang-selector` / `.lang-btn` CSS.
///
/// Reads [localeProvider] and updates it via [LocaleNotifier.setLocale].
class LanguageToggle extends ConsumerWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final notifier = ref.read(localeProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.inputBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LangButton(
            flag: '🇺🇸',
            code: 'EN',
            isActive: currentLocale == 'en',
            onTap: () => notifier.setLocale('en'),
            semanticLabel: 'Switch to English',
          ),
          const SizedBox(width: 2),
          _LangButton(
            flag: '🇪🇸',
            code: 'ES',
            isActive: currentLocale == 'es',
            onTap: () => notifier.setLocale('es'),
            semanticLabel: 'Cambiar a Español',
          ),
        ],
      ),
    );
  }
}

class _LangButton extends StatefulWidget {
  final String flag;
  final String code;
  final bool isActive;
  final VoidCallback onTap;
  final String semanticLabel;

  const _LangButton({
    required this.flag,
    required this.code,
    required this.isActive,
    required this.onTap,
    required this.semanticLabel,
  });

  @override
  State<_LangButton> createState() => _LangButtonState();
}

class _LangButtonState extends State<_LangButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: widget.isActive
                  ? const Color(0x1FFFFFFF) // rgba(255,255,255,0.12)
                  : _hovered
                      ? const Color(0x0DFFFFFF) // rgba(255,255,255,0.05)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              boxShadow: widget.isActive
                  ? [
                      BoxShadow(
                        color: Colors.black.withAlpha(51),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.flag, style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 5),
                Text(
                  widget.code,
                  style: TextStyle(
                    fontSize: 13.6,
                    fontWeight: FontWeight.w600,
                    color: widget.isActive
                        ? Colors.white
                        : _hovered
                            ? Colors.white
                            : AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
