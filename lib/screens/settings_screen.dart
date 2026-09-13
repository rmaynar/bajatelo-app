import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _channel = MethodChannel('maynar.bajatelo/downloader');
  String? _customDir;

  @override
  void initState() {
    super.initState();
    _loadCustomDir();
  }

  Future<void> _loadCustomDir() async {
    if (!Platform.isAndroid) return;
    try {
      final String? dir = await _channel.invokeMethod('getCustomDownloadDirectory');
      setState(() {
        _customDir = dir;
      });
    } catch (e) {
      debugPrint('Failed to load custom dir: $e');
    }
  }

  Future<void> _pickDir() async {
    if (!Platform.isAndroid) return;
    try {
      final String? dir = await _channel.invokeMethod('pickDownloadDirectory');
      setState(() {
        _customDir = dir;
      });
    } catch (e) {
      debugPrint('Failed to pick custom dir: $e');
    }
  }

  Future<void> _clearDir() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('clearCustomDownloadDirectory');
      setState(() {
        _customDir = null;
      });
    } catch (e) {
      debugPrint('Failed to clear custom dir: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (Platform.isAndroid) ...[
                const Text(
                  'Downloads',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: const Icon(Icons.folder_rounded, color: Colors.white),
                    title: const Text(
                      'Choose Downloads Folder',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      _customDir != null
                          ? 'Saved to custom folder\n$_customDir'
                          : 'Default Downloads Folder',
                      style: TextStyle(color: Colors.white.withOpacity(0.6)),
                    ),
                    trailing: _customDir != null
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: Colors.white54),
                            onPressed: _clearDir,
                            tooltip: 'Reset to default',
                          )
                        : null,
                    onTap: _pickDir,
                  ),
                ),
              ] else ...[
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text(
                      'Settings are only available for Android currently.',
                      style: TextStyle(color: Colors.white54),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
