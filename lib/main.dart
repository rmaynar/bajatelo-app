import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bajatelo_app/core/providers/downloader_provider.dart';
import 'package:bajatelo_app/core/theme/app_theme.dart';
import 'package:bajatelo_app/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Auto-detect locale from platform if no saved preference exists
  final prefs = await SharedPreferences.getInstance();
  final savedLang = prefs.getString('ytdl_lang');
  if (savedLang == null) {
    // Detect from platform locale (e.g. "es_ES" → 'es')
    final platformLocale = _detectPlatformLocale();
    await prefs.setString('ytdl_lang', platformLocale);
  }

  runApp(
    const ProviderScope(
      child: BajateloApp(),
    ),
  );
}

/// Detects the device locale and returns 'es' for Spanish, 'en' otherwise.
String _detectPlatformLocale() {
  try {
    final localeName = Platform.localeName; // e.g. "es_ES", "en_US"
    if (localeName.toLowerCase().startsWith('es')) {
      return 'es';
    }
  } catch (_) {
    // Platform.localeName can throw on some environments
  }
  return 'en';
}

/// Root widget — applies the dark theme and wires up locale switching.
class BajateloApp extends ConsumerWidget {
  const BajateloApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch locale to rebuild MaterialApp.locale when the user switches language.
    final localeCode = ref.watch(localeProvider);
    final locale = Locale(localeCode);

    return MaterialApp(
      title: 'bajatelo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('es')],
      home: const HomeScreen(),
    );
  }
}
