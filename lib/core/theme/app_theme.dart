import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

/// Maps the CSS custom properties from index.css to Flutter's ThemeData.
///
/// Key design tokens:
/// | CSS Variable          | Value                    | Flutter usage                  |
/// |-----------------------|--------------------------|--------------------------------|
/// | --bg-main             | #090d16                  | scaffoldBackgroundColor        |
/// | --card-bg             | rgba(18,26,43,0.85)      | CardTheme / glassmorphic cards |
/// | --card-border         | rgba(255,255,255,0.08)   | Card border color              |
/// | --card-glow           | rgba(59,130,246,0.12)    | Card box-shadow tint           |
/// | --accent-red          | #ef4444                  | colorScheme.error / Search btn |
/// | --accent-blue         | #3b82f6                  | colorScheme.primary / Video btn|
/// | --accent-emerald      | #10b981                  | colorScheme.secondary / Audio  |
/// | --accent-purple       | #8b5cf6                  | tertiary                       |
/// | --text-main           | #f8fafc                  | textTheme foreground           |
/// | --text-muted          | #94a3b8                  | bodySmall color                |
/// | --input-bg            | rgba(15,23,42,0.75)      | TextField fill color           |
class AppTheme {
  AppTheme._();

  // ── Colour constants ────────────────────────────────────────────────────────
  static const Color bgMain = Color(0xFF090D16);
  static const Color cardBg = Color(0xD9121A2B); // rgba(18,26,43,0.85)
  static const Color cardBorder = Color(0x14FFFFFF); // rgba(255,255,255,0.08)
  static const Color cardGlow = Color(0x1F3B82F6); // rgba(59,130,246,0.12)

  static const Color accentRed = Color(0xFFEF4444);
  static const Color accentRedHover = Color(0xFFDC2626);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentBlueHover = Color(0xFF2563EB);
  static const Color accentEmerald = Color(0xFF10B981);
  static const Color accentEmeraldHover = Color(0xFF059669);
  static const Color accentPurple = Color(0xFF8B5CF6);

  static const Color textMain = Color(0xFFF8FAFC);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textSubtle = Color(0xFF64748B);
  static const Color textLight = Color(0xFFCBD5E1);

  static const Color inputBg = Color(0xBF0F172A); // rgba(15,23,42,0.75)

  // Gradient colours
  static const List<Color> gradientRed = [Color(0xFFEF4444), Color(0xFFDC2626)];
  static const List<Color> gradientBlue = [Color(0xFF3B82F6), Color(0xFF2563EB)];
  static const List<Color> gradientEmerald = [Color(0xFF10B981), Color(0xFF059669)];
  static const List<Color> gradientLogo = [Color(0xFFFF416C), Color(0xFFFF4B2B)];

  // ── TextStyle helpers ───────────────────────────────────────────────────────
  static TextStyle get _base =>
      GoogleFonts.plusJakartaSans(color: textMain);

  // ── ThemeData ───────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: bgMain,
      colorScheme: const ColorScheme.dark(
        brightness: Brightness.dark,
        primary: accentBlue,
        onPrimary: Colors.white,
        secondary: accentEmerald,
        onSecondary: Colors.white,
        error: accentRed,
        onError: Colors.white,
        tertiary: accentPurple,
        surface: cardBg,
        onSurface: textMain,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).copyWith(
        displayLarge: _base.copyWith(
          fontSize: 37.6, fontWeight: FontWeight.w800, letterSpacing: -1.2),
        displayMedium: _base.copyWith(
          fontSize: 28.0, fontWeight: FontWeight.w800, letterSpacing: -0.8),
        headlineMedium: _base.copyWith(
          fontSize: 18.4, fontWeight: FontWeight.w700),
        titleMedium: _base.copyWith(
          fontSize: 15.2, fontWeight: FontWeight.w600),
        bodyLarge: _base.copyWith(fontSize: 16.0),
        bodyMedium: _base.copyWith(fontSize: 14.4, color: textMuted),
        bodySmall: _base.copyWith(fontSize: 12.8, color: textMuted),
        labelLarge: _base.copyWith(
          fontSize: 15.2, fontWeight: FontWeight.w700),
        labelSmall: _base.copyWith(
          fontSize: 12.0, fontWeight: FontWeight.w600, color: textMuted),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentBlue, width: 1.5),
        ),
        hintStyle: _base.copyWith(color: textMuted, fontSize: 15.2),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: cardBorder),
        ),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0x0AFFFFFF),
        side: const BorderSide(color: cardBorder),
        labelStyle: _base.copyWith(
            fontSize: 12.0, fontWeight: FontWeight.w500, color: textLight),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: const StadiumBorder(),
      ),
      iconTheme: const IconThemeData(color: textMuted),
      dividerColor: cardBorder,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
