import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bajatelo/core/interfaces/i_downloader_service.dart';
import 'package:bajatelo/core/models/download_result.dart';
import 'package:bajatelo/core/providers/download_state.dart';
import 'package:bajatelo/core/providers/download_notifier.dart';
import 'package:bajatelo/core/services/mock_downloader_service.dart';

import 'dart:io' show Platform;
import 'package:bajatelo/services/android_downloader_service.dart';
import 'package:bajatelo/services/desktop_downloader_service.dart';

/// Provides the [IDownloaderService] for the current platform.
final downloaderServiceProvider = Provider<IDownloaderService>((ref) {
  if (Platform.isAndroid) {
    return AndroidDownloaderService();
  } else if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
    return DesktopDownloaderService();
  }
  return MockDownloaderService();
});

/// Provides the [DownloadNotifier] backed by [DownloadState].
final downloadNotifierProvider =
    StateNotifierProvider<DownloadNotifier, DownloadState>((ref) {
  final service = ref.watch(downloaderServiceProvider);
  return DownloadNotifier(service);
});

/// Persists and exposes the chosen locale code ('en' or 'es').
final localeProvider =
    StateNotifierProvider<LocaleNotifier, String>((ref) => LocaleNotifier());

// ── History ──────────────────────────────────────────────────────────────────

/// Persists and exposes the list of completed [DownloadResult] objects.
final downloadHistoryProvider =
    StateNotifierProvider<DownloadHistoryNotifier, List<DownloadResult>>(
        (ref) => DownloadHistoryNotifier());

// ── Notifiers ─────────────────────────────────────────────────────────────────

/// Manages the locale selection, persisted via [SharedPreferences].
class LocaleNotifier extends StateNotifier<String> {
  static const _key = 'ytdl_lang';

  LocaleNotifier() : super('en') {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null) {
      state = saved;
    }
  }

  Future<void> setLocale(String code) async {
    state = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, code);
  }
}

/// Persists the download history to [SharedPreferences].
class DownloadHistoryNotifier extends StateNotifier<List<DownloadResult>> {
  static const _key = 'download_history';

  DownloadHistoryNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    state = raw
        .map((s) {
          try {
            return DownloadResult.fromJsonString(s);
          } catch (_) {
            return null;
          }
        })
        .whereType<DownloadResult>()
        .toList();
  }

  Future<void> add(DownloadResult result) async {
    state = [result, ...state];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _key, state.map((r) => r.toJsonString()).toList());
  }

  Future<void> clear() async {
    state = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
