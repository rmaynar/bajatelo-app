import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bajatelo/core/interfaces/i_downloader_service.dart';

import 'package:bajatelo/core/providers/download_state.dart';
import 'package:bajatelo/core/providers/downloader_provider.dart';
import 'package:bajatelo/core/theme/app_theme.dart';
import 'package:bajatelo/widgets/glassmorphic_card.dart';
import 'package:bajatelo/widgets/gradient_button.dart';
import 'package:bajatelo/widgets/language_toggle.dart';
import 'package:bajatelo/widgets/platform_chip.dart';
import 'package:bajatelo/widgets/progress_indicator.dart';

// ─── Supported platform data ──────────────────────────────────────────────────

const _kPlatforms = [
  ('▶', 'YouTube'),
  ('🎵', 'TikTok'),
  ('📷', 'Instagram'),
  ('𝕏', 'Twitter / X'),
  ('💬', 'Facebook'),
  ('👾', 'Twitch'),
  ('☁', 'SoundCloud'),
  ('🤖', 'Reddit'),
  ('✨', '+1000 more'),
];

// ─── Breakpoints ──────────────────────────────────────────────────────────────

const _kBpNarrow = 480.0; // buttons stack vertically / single-col features
const _kBpMedium = 640.0; // input+button stack vertically
const _kBpWide = 700.0;   // two-column video card

/// Main application screen — a faithful Flutter port of App.jsx.
///
/// Layout (top → bottom):
/// 1. Header (logo + language toggle)
/// 2. Hero section (badge + title + subtitle)
/// 3. Search card (URL input + paste/clear + Search button)
/// 4. Platform chips
/// 5. Error banner (AnimatedSwitcher)
/// 6. Video result card (thumbnail + download buttons)
/// 7. Features grid
/// 8. Footer
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _urlController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _urlController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Translations ─────────────────────────────────────────────────────────

  Map<String, String> get _t {
    final locale = ref.watch(localeProvider);
    return locale == 'es' ? _esTranslations : _enTranslations;
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _handlePaste() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim();
      if (text != null && text.isNotEmpty) {
        _urlController.text = text;
        _urlController.selection = TextSelection.fromPosition(
          TextPosition(offset: text.length),
        );
      }
    } catch (_) {
      // Silently ignore clipboard errors — user can paste manually
    }
  }

  void _handleSearch() {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;
    ref.read(downloadNotifierProvider.notifier).fetchInfo(url);
  }

  void _handleDownload(DownloadFormat format) {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;
    final notifier = ref.read(downloadNotifierProvider.notifier);
    notifier.download(url, format).then((_) {
      final state = ref.read(downloadNotifierProvider);
      if (state.isCompleted && state.result != null) {
        ref.read(downloadHistoryProvider.notifier).add(state.result!);
      }
    });
  }

  void _handleCancel() {
    ref.read(downloadNotifierProvider.notifier).cancel();
  }

  void _dismissError() {
    ref.read(downloadNotifierProvider.notifier).clearError();
  }

  void _handleUpdateEngine() {
    ref.read(downloadNotifierProvider.notifier).updateEngine().then((_) {
      // After a successful update, auto-retry the search if there's a URL
      final url = _urlController.text.trim();
      final state = ref.read(downloadNotifierProvider);
      if (url.isNotEmpty && !state.hasError) {
        ref.read(downloadNotifierProvider.notifier).fetchInfo(url);
      }
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(downloadNotifierProvider);
    final width = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: AppTheme.bgMain,
      body: Stack(
        children: [
          // Background radial gradients (matching CSS body background-image)
          Positioned.fill(
            child: CustomPaint(painter: _BackgroundPainter()),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 56),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 40),
                      _buildHero(),
                      const SizedBox(height: 36),
                      _buildSearchCard(state, width),
                      const SizedBox(height: 28),
                      _buildErrorBanner(state),
                      _buildVideoCard(state, width),
                      _buildFeaturesGrid(width),
                      const SizedBox(height: 32),
                      _buildFooter(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      children: [
        // Logo
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF4B2B).withAlpha(89),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.download_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Colors.white, Color(0xFF94A3B8)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ).createShader(bounds),
              child: Text(
                _t['logo']!,
                style: const TextStyle(
                  fontSize: 21.6,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.35,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const Spacer(),
        // Language toggle
        const LanguageToggle(),
      ],
    );
  }

  // ── Hero ──────────────────────────────────────────────────────────────────

  Widget _buildHero() {
    return Column(
      children: [
        // Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0x1A3B82F6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0x403B82F6)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bolt_rounded,
                  size: 14, color: Color(0xFF60A5FA)),
              const SizedBox(width: 6),
              Text(
                _t['badge']!,
                style: const TextStyle(
                  fontSize: 12.8,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF60A5FA),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Title with gradient on second line
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(
              fontSize: 37.6,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
              height: 1.2,
              color: Colors.white,
            ),
            children: [
              TextSpan(text: '${_t['heroTitle1']!}\n'),
              WidgetSpan(
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFEF4444), Color(0xFFF97316)],
                  ).createShader(bounds),
                  child: Text(
                    _t['heroTitle2']!,
                    style: const TextStyle(
                      fontSize: 37.6,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Subtitle
        Text(
          _t['heroSubtitle']!,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16.0,
            color: Color(0xFF94A3B8),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // ── Search Card ───────────────────────────────────────────────────────────

  Widget _buildSearchCard(DownloadState state, double width) {
    final isFetching = state.isFetchingInfo;
    final canSearch =
        !isFetching && _urlController.text.trim().isNotEmpty;
    final stackVertically = width < _kBpMedium;

    return GlassmorphicCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Input + button row (or column on narrow)
          stackVertically
              ? Column(
                  children: [
                    _buildUrlInput(isFetching),
                    const SizedBox(height: 12),
                    _buildSearchButton(isFetching, canSearch, fullWidth: true),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _buildUrlInput(isFetching)),
                    const SizedBox(width: 12),
                    _buildSearchButton(isFetching, canSearch),
                  ],
                ),
          const SizedBox(height: 16),
          // Platforms row
          _buildPlatformsRow(),
        ],
      ),
    );
  }

  Widget _buildUrlInput(bool disabled) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _urlController,
      builder: (_, value, __) {
        final hasText = value.text.isNotEmpty;
        return TextField(
          controller: _urlController,
          enabled: !disabled,
          onSubmitted: disabled ? null : (_) => _handleSearch(),
          onChanged: (_) => setState(() {}),
          style: const TextStyle(color: Colors.white, fontSize: 15.2),
          decoration: InputDecoration(
            hintText: _t['inputPlaceholder'],
            prefixIcon: const Icon(Icons.link_rounded,
                color: Color(0xFF94A3B8), size: 20),
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: hasText
                  ? _IconActionButton(
                      tooltip: _t['clearTooltip']!,
                      icon: Icons.close_rounded,
                      onTap: () {
                        _urlController.clear();
                        setState(() {});
                      },
                    )
                  : _IconActionButton(
                      tooltip: _t['pasteTooltip']!,
                      icon: Icons.content_paste_rounded,
                      onTap: _handlePaste,
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchButton(bool isFetching, bool canSearch,
      {bool fullWidth = false}) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: GradientButton(
        onPressed: canSearch ? _handleSearch : null,
        gradientColors: AppTheme.gradientRed,
        shadowColors: [
          BoxShadow(
            color: AppTheme.accentRed.withAlpha(89),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: isFetching
              ? [
                  const SpinnerWidget(size: 18),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(_t['searchingBtn']!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ]
              : [
                  const Icon(Icons.search_rounded,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(_t['searchBtn']!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ],
        ),
      ),
    );
  }

  Widget _buildPlatformsRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 1,
          color: const Color(0x0DFFFFFF),
          margin: const EdgeInsets.only(bottom: 14),
        ),
        Text(
          _t['supportedPlatformsLabel']!,
          style: const TextStyle(
            fontSize: 12.0,
            fontWeight: FontWeight.w600,
            color: Color(0xFF94A3B8),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: _kPlatforms
              .map((p) => PlatformChip(icon: p.$1, name: p.$2))
              .toList(),
        ),
      ],
    );
  }

  // ── Error Banner ──────────────────────────────────────────────────────────

  Widget _buildErrorBanner(DownloadState state) {
    final showBanner =
        (state.hasError && state.errorMessage != null) || state.isUpdatingEngine;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.2),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: showBanner
          ? Padding(
              key: ValueKey('${state.errorMessage}_${state.isUpdatingEngine}'),
              padding: const EdgeInsets.only(bottom: 24),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: state.isUpdatingEngine
                      ? const Color(0x1A3B82F6)
                      : const Color(0x1FEF4444),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: state.isUpdatingEngine
                        ? const Color(0x403B82F6)
                        : const Color(0x4DEF4444),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: icon + message + close
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          state.isUpdatingEngine
                              ? Icons.system_update_rounded
                              : Icons.info_outline_rounded,
                          color: state.isUpdatingEngine
                              ? const Color(0xFF60A5FA)
                              : const Color(0xFFFCA5A5),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            state.isUpdatingEngine
                                ? _t['updatingEngine']!
                                : state.errorMessage!,
                            style: TextStyle(
                              color: state.isUpdatingEngine
                                  ? const Color(0xFF60A5FA)
                                  : const Color(0xFFFCA5A5),
                              fontSize: 14.4,
                              height: 1.4,
                            ),
                          ),
                        ),
                        if (!state.isUpdatingEngine)
                          GestureDetector(
                            onTap: _dismissError,
                            child: const Icon(Icons.close,
                                color: Color(0xFFFCA5A5), size: 18),
                          ),
                      ],
                    ),
                    // Update Engine button (when engine is outdated)
                    if (state.needsEngineUpdate && !state.isUpdatingEngine) ...[
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: GradientButton(
                          onPressed: _handleUpdateEngine,
                          gradientColors: const [
                            Color(0xFF3B82F6),
                            Color(0xFF2563EB),
                          ],
                          shadowColors: [
                            BoxShadow(
                              color: const Color(0xFF3B82F6).withAlpha(89),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.system_update_rounded,
                                  color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                _t['updateEngineBtn']!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    // Updating spinner
                    if (state.isUpdatingEngine) ...[
                      const SizedBox(height: 12),
                      const Center(
                        child: SpinnerWidget(
                          size: 20,
                          color: Color(0xFF60A5FA),
                          trackColor: Color(0x6660A5FA),
                        ),
                      ),
                    ],
                    // Collapsible raw details
                    if (state.rawErrorDetails != null &&
                        state.rawErrorDetails!.isNotEmpty &&
                        !state.isUpdatingEngine) ...[
                      const SizedBox(height: 10),
                      _ErrorDetailsToggle(
                        label: _t['showDetails']!,
                        details: state.rawErrorDetails!,
                      ),
                    ],
                  ],
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  // ── Video Card ────────────────────────────────────────────────────────────

  Widget _buildVideoCard(DownloadState state, double width) {
    final info = state.videoInfo;
    if (info == null) return const SizedBox.shrink();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: Padding(
        key: ValueKey(info.id),
        padding: const EdgeInsets.only(bottom: 32),
        child: GlassmorphicCard(
          borderRadius: 20,
          padding: const EdgeInsets.all(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(102),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ],
          child: width >= _kBpWide
              ? _buildVideoCardWide(state, info)
              : _buildVideoCardNarrow(state, info),
        ),
      ),
    );
  }

  Widget _buildVideoCardWide(DownloadState state, videoInfo) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 280,
          child: _buildThumbnail(videoInfo),
        ),
        const SizedBox(width: 24),
        Expanded(child: _buildVideoDetails(state, videoInfo)),
      ],
    );
  }

  Widget _buildVideoCardNarrow(DownloadState state, videoInfo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildThumbnail(videoInfo),
        const SizedBox(height: 20),
        _buildVideoDetails(state, videoInfo),
      ],
    );
  }

  Widget _buildThumbnail(videoInfo) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: videoInfo.thumbnailUrl != null
                ? Image.network(
                    videoInfo.thumbnailUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (_, __, ___) => _buildThumbnailPlaceholder(),
                  )
                : _buildThumbnailPlaceholder(),
          ),
          if (videoInfo.durationSeconds != null)
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xD1000000),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: const Color(0x1AFFFFFF), width: 0.5),
                ),
                child: Text(
                  _formatDuration(videoInfo.durationSeconds!),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildThumbnailPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Center(
        child: Icon(Icons.movie_outlined,
            color: Color(0xFF334155), size: 48),
      ),
    );
  }

  Widget _buildVideoDetails(DownloadState state, videoInfo) {
    final width = MediaQuery.sizeOf(context).width;
    final isNarrowButtons = width < _kBpNarrow;
    final isDownloading = state.isDownloading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          videoInfo.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 18.4,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        // Meta tags
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _MetaTag(label: _t['videoFormatTag']!),
            _MetaTag(label: _t['audioFormatTag']!),
            if (videoInfo.id.isNotEmpty)
              _MetaTag(label: 'ID: ${videoInfo.id}'),
          ],
        ),
        const SizedBox(height: 20),
        // Download buttons
        isNarrowButtons
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildVideoDownloadButton(state),
                  const SizedBox(height: 12),
                  _buildAudioDownloadButton(state),
                ],
              )
            : Row(
                children: [
                  Expanded(child: _buildVideoDownloadButton(state)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildAudioDownloadButton(state)),
                ],
              ),
        // Processing notice
        if (isDownloading) ...[
          const SizedBox(height: 12),
          _buildProcessingNotice(state),
        ],
        // Success notice
        if (state.isCompleted && state.result != null) ...[
          const SizedBox(height: 12),
          _buildSuccessNotice(state),
        ],
      ],
    );
  }

  Widget _buildVideoDownloadButton(DownloadState state) {
    final isDownloadingVideo =
        state.isDownloading && state.activeFormat == 'video';
    final disabled = state.isDownloading || state.isFetchingInfo;

    return GradientButton.blue(
      onPressed: disabled ? null : () => _handleDownload(DownloadFormat.video),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: isDownloadingVideo
            ? [
                const SpinnerWidget(size: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(_t['processingVideo']!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ]
            : [
                const Icon(Icons.videocam_outlined,
                    color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(_t['downloadVideo']!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ],
      ),
    );
  }

  Widget _buildAudioDownloadButton(DownloadState state) {
    final isDownloadingAudio =
        state.isDownloading && state.activeFormat == 'audio';
    final disabled = state.isDownloading || state.isFetchingInfo;

    return GradientButton.emerald(
      onPressed: disabled ? null : () => _handleDownload(DownloadFormat.audio),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: isDownloadingAudio
            ? [
                const SpinnerWidget(size: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(_t['processingAudio']!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ]
            : [
                const Icon(Icons.music_note_outlined,
                    color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(_t['downloadAudio']!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ],
      ),
    );
  }

  Widget _buildProcessingNotice(DownloadState state) {
    return _PulseContainer(
      child: Row(
        children: [
          state.progress > 0
              ? DownloadProgressIndicator(
                  progress: state.progress,
                  size: 36,
                  color: const Color(0xFF93C5FD),
                )
              : const SpinnerWidget(
                  size: 16,
                  color: Color(0xFF93C5FD),
                  trackColor: Color(0x6693C5FD),
                ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _t['processingNotice']!,
              style: const TextStyle(
                fontSize: 13.6,
                color: Color(0xFF93C5FD),
              ),
            ),
          ),
          TextButton(
            onPressed: _handleCancel,
            child: Text(
              _t['cancelDownload']!,
              style: const TextStyle(
                  color: Color(0xFF93C5FD), fontSize: 12.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessNotice(DownloadState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x1A10B981),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x4010B981)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded,
              color: Color(0xFF6EE7B7), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${_t['downloadComplete']!} — ${state.result!.fileName}',
              style: const TextStyle(
                fontSize: 13.6,
                color: Color(0xFF6EE7B7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Features Grid ─────────────────────────────────────────────────────────

  Widget _buildFeaturesGrid(double width) {
    final singleColumn = width < _kBpNarrow;

    final features = [
      (
        Icons.star_outline_rounded,
        _t['feature1Title']!,
        _t['feature1Desc']!,
      ),
      (
        Icons.bolt_rounded,
        _t['feature2Title']!,
        _t['feature2Desc']!,
      ),
      (
        Icons.shield_outlined,
        _t['feature3Title']!,
        _t['feature3Desc']!,
      ),
    ];

    if (singleColumn) {
      return Column(
        children: features
            .map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _FeatureBox(icon: f.$1, title: f.$2, desc: f.$3),
                ))
            .toList(),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: features
          .map((f) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _FeatureBox(icon: f.$1, title: f.$2, desc: f.$3),
                ),
              ))
          .toList(),
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────

  Widget _buildFooter() {
    return Text(
      _t['footer']!,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 12.8,
        color: Color(0xFF64748B),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _formatDuration(int seconds) {
    final hrs = seconds ~/ 3600;
    final mins = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    if (hrs > 0) {
      return '$hrs:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

/// Collapsible toggle that shows raw yt-dlp error details for advanced users.
class _ErrorDetailsToggle extends StatefulWidget {
  final String label;
  final String details;

  const _ErrorDetailsToggle({
    required this.label,
    required this.details,
  });

  @override
  State<_ErrorDetailsToggle> createState() => _ErrorDetailsToggleState();
}

class _ErrorDetailsToggleState extends State<_ErrorDetailsToggle> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: const Color(0xFFFCA5A5),
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Color(0xFFFCA5A5),
                  fontSize: 12.0,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  decorationColor: Color(0xFFFCA5A5),
                ),
              ),
            ],
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0x1A000000),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0x26FFFFFF)),
            ),
            child: SelectableText(
              widget.details,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 11.2,
                fontFamily: 'monospace',
                height: 1.5,
              ),
            ),
          ),
        ],
      ],
    );
  }
}


class _IconActionButton extends StatefulWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  const _IconActionButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_IconActionButton> createState() => _IconActionButtonState();
}

class _IconActionButtonState extends State<_IconActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _hovered ? const Color(0x1AFFFFFF) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              widget.icon,
              size: 16,
              color: _hovered ? Colors.white : const Color(0xFF94A3B8),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaTag extends StatelessWidget {
  final String label;

  const _MetaTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0x0FFFFFFF),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12.0,
          fontWeight: FontWeight.w600,
          color: Color(0xFF94A3B8),
        ),
      ),
    );
  }
}

class _FeatureBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;

  const _FeatureBox({
    required this.icon,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0x80121A2B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0x0DFFFFFF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF60A5FA)),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15.2,
              fontWeight: FontWeight.w700,
              color: Color(0xFFF1F5F9),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.8,
              color: Color(0xFF94A3B8),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pulsing glow container replicating CSS `pulseGlow` animation.
class _PulseContainer extends StatefulWidget {
  final Widget child;

  const _PulseContainer({required this.child});

  @override
  State<_PulseContainer> createState() => _PulseContainerState();
}

class _PulseContainerState extends State<_PulseContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Color?> _border;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _opacity = Tween(begin: 0.9, end: 1.0).animate(_ctrl);
    _border = ColorTween(
      begin: const Color(0x333B82F6),
      end: const Color(0x733B82F6),
    ).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Opacity(
        opacity: _opacity.value,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0x143B82F6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _border.value!),
          ),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

// ─── Background Painter ───────────────────────────────────────────────────────

/// Replicates the CSS body `background-image` with 3 radial gradients.
class _BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    _drawRadial(
      canvas,
      size,
      cx: 0.15,
      cy: 0.15,
      color: const Color(0x14EF4444),
    );
    _drawRadial(
      canvas,
      size,
      cx: 0.85,
      cy: 0.25,
      color: const Color(0x143B82F6),
    );
    _drawRadial(
      canvas,
      size,
      cx: 0.50,
      cy: 0.85,
      color: const Color(0x0F8B5CF6),
    );
  }

  void _drawRadial(Canvas canvas, Size size,
      {required double cx,
      required double cy,
      required Color color}) {
    final rect = Rect.fromCenter(
      center: Offset(size.width * cx, size.height * cy),
      width: size.width * 0.8,
      height: size.height * 0.6,
    );
    final gradient = RadialGradient(
      colors: [color, Colors.transparent],
    );
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(_BackgroundPainter oldDelegate) => false;
}

// ─── Translation maps (inline — mirrors React TRANSLATIONS object) ────────────

const Map<String, String> _enTranslations = {
  'logo': 'bajatelo',
  'badge': 'Universal Downloader • Fast & Free',
  'heroTitle1': 'Universal Video &',
  'heroTitle2': 'Audio Downloader',
  'heroSubtitle':
      'Download videos and audio from YouTube, TikTok, Instagram, Twitter/X, Facebook, Twitch and 1,000+ platforms in highest quality MP4 or MP3.',
  'supportedPlatformsLabel': 'Supported platforms include:',
  'inputPlaceholder':
      'Paste link from YouTube, TikTok, Instagram, X/Twitter, Twitch...',
  'searchBtn': 'Search',
  'searchingBtn': 'Fetching...',
  'pasteTooltip': 'Paste from clipboard',
  'clearTooltip': 'Clear input',
  'downloadVideo': 'Download Video (MP4)',
  'downloadAudio': 'Download Audio (MP3)',
  'processingVideo': 'Processing Video...',
  'processingAudio': 'Processing Audio...',
  'processingNotice':
      'Converting and merging media. Your download will start automatically in a few moments.',
  'duration': 'Duration',
  'videoFormatTag': 'MP4 / Best Quality',
  'audioFormatTag': 'MP3 / 320kbps Audio',
  'feature1Title': '1,000+ Supported Sites',
  'feature1Desc':
      'Supports YouTube, TikTok, Instagram Reels/Posts, Twitter/X, Twitch, Facebook, SoundCloud, Reddit, and more.',
  'feature2Title': 'Ultra Fast Processing',
  'feature2Desc':
      'Powered by yt-dlp & FFmpeg pipeline for lossless format conversions and fast stream merging.',
  'feature3Title': '100% Free & Private',
  'feature3Desc':
      'No registration, no accounts required, no telemetry. Direct downloads straight to your device.',
  'footer': 'bajatelo • Fast, Private & Free Universal Media Downloader',
  'cancelDownload': 'Cancel',
  'downloadComplete': 'Download complete',
  'updateEngineBtn': 'Update Download Engine',
  'updatingEngine': 'Updating download engine… This may take a moment.',
  'showDetails': 'Show details',
};

const Map<String, String> _esTranslations = {
  'logo': 'bajatelo',
  'badge': 'Descargador Universal • Rápido y Gratis',
  'heroTitle1': 'Descargador de',
  'heroTitle2': 'Vídeo y Audio',
  'heroSubtitle':
      'Descarga vídeos y música de YouTube, TikTok, Instagram, Twitter/X, Facebook, Twitch y más de 1.000 plataformas en la máxima calidad MP4 o MP3.',
  'supportedPlatformsLabel': 'Plataformas compatibles:',
  'inputPlaceholder':
      'Pega el enlace de YouTube, TikTok, Instagram, X/Twitter, Twitch...',
  'searchBtn': 'Buscar',
  'searchingBtn': 'Buscando...',
  'pasteTooltip': 'Pegar del portapapeles',
  'clearTooltip': 'Limpiar enlace',
  'downloadVideo': 'Descargar Vídeo (MP4)',
  'downloadAudio': 'Descargar Audio (MP3)',
  'processingVideo': 'Procesando Vídeo...',
  'processingAudio': 'Procesando Audio...',
  'processingNotice':
      'Convirtiendo y unificando streams. La descarga comenzará automáticamente.',
  'duration': 'Duración',
  'videoFormatTag': 'Vídeo MP4 / Mejor Calidad',
  'audioFormatTag': 'Audio MP3 / 320kbps',
  'feature1Title': '+1.000 Sitios Compatibles',
  'feature1Desc':
      'Compatible con YouTube, TikTok, Instagram (Reels/Posts), Twitter/X, Twitch, Facebook, SoundCloud, Reddit y más.',
  'feature2Title': 'Ultra Rápido',
  'feature2Desc':
      'Potenciado por yt-dlp y FFmpeg con procesamiento eficiente y fusión de flujos de media.',
  'feature3Title': '100% Libre y Privado',
  'feature3Desc':
      'Sin registros, sin límites y con descargas directas a tu dispositivo sin intermediarios.',
  'footer':
      'bajatelo • Descargador Universal de Medios Rápido, Privado y Gratuito',
  'cancelDownload': 'Cancelar',
  'downloadComplete': 'Descarga completada',
  'updateEngineBtn': 'Actualizar Motor de Descarga',
  'updatingEngine': 'Actualizando motor de descarga… Esto puede tardar un momento.',
  'showDetails': 'Ver detalles',
};
