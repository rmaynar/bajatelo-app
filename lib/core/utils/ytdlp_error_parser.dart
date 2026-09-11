/// Parses raw yt-dlp error output into user-friendly messages.
///
/// Maps known error patterns (HTTP 400, DRM, geo-blocks, etc.) to clean,
/// categorized messages and flags whether an engine update would help.
class YtdlpErrorParser {
  /// Result of parsing a raw yt-dlp error string.
  static ParsedError parse(String rawError) {
    final lower = rawError.toLowerCase();

    // ── Engine outdated / API breakage ────────────────────────────────────
    if (_matchesAny(lower, [
      'precondition check failed',
      'http error 400',
      'http error 403',
      'unable to extract',
      'confirm you are on the latest version',
      'please report this issue',
    ])) {
      return ParsedError(
        friendlyMessage:
            'The download engine is outdated. Please update it to fix this issue.',
        friendlyMessageEs:
            'El motor de descarga está desactualizado. Actualízalo para solucionar este problema.',
        needsEngineUpdate: true,
        rawDetails: rawError,
      );
    }

    // ── Private / removed content ─────────────────────────────────────────
    if (_matchesAny(lower, [
      'private video',
      'video unavailable',
      'this video has been removed',
      'video is unavailable',
    ])) {
      return ParsedError(
        friendlyMessage:
            'This video is private, deleted, or unavailable.',
        friendlyMessageEs:
            'Este vídeo es privado, ha sido eliminado o no está disponible.',
        rawDetails: rawError,
      );
    }

    // ── Age-restricted ────────────────────────────────────────────────────
    if (_matchesAny(lower, [
      'sign in to confirm your age',
      'age-restricted',
      'age restricted',
    ])) {
      return ParsedError(
        friendlyMessage:
            'This video is age-restricted and cannot be downloaded.',
        friendlyMessageEs:
            'Este vídeo tiene restricción de edad y no se puede descargar.',
        rawDetails: rawError,
      );
    }

    // ── Geo-blocked ───────────────────────────────────────────────────────
    if (_matchesAny(lower, [
      'not made this video available in your country',
      'georestricted',
      'geo restricted',
      'blocked in your country',
    ])) {
      return ParsedError(
        friendlyMessage:
            'This video is blocked in your geographic region.',
        friendlyMessageEs:
            'Este vídeo está bloqueado en tu región geográfica.',
        rawDetails: rawError,
      );
    }

    // ── DRM protected ─────────────────────────────────────────────────────
    if (_matchesAny(lower, [
      'drm protected',
      'drm-protected',
    ])) {
      return ParsedError(
        friendlyMessage:
            'This video is DRM-protected and cannot be downloaded.',
        friendlyMessageEs:
            'Este vídeo está protegido por DRM y no se puede descargar.',
        rawDetails: rawError,
      );
    }

    // ── Network / connectivity ────────────────────────────────────────────
    if (_matchesAny(lower, [
      'timed out',
      'network is unreachable',
      'connection refused',
      'unable to download webpage',
      'no internet',
      'name or service not known',
    ])) {
      return ParsedError(
        friendlyMessage:
            'Unable to connect. Please check your internet connection.',
        friendlyMessageEs:
            'No se pudo conectar. Comprueba tu conexión a internet.',
        rawDetails: rawError,
      );
    }

    // ── Invalid URL / unsupported ─────────────────────────────────────────
    if (_matchesAny(lower, [
      'unsupported url',
      'is not a valid url',
      'no video could be found',
    ])) {
      return ParsedError(
        friendlyMessage:
            'The link is invalid or from an unsupported platform.',
        friendlyMessageEs:
            'El enlace no es válido o pertenece a una plataforma no soportada.',
        rawDetails: rawError,
      );
    }

    // ── Fallback: extract last ERROR: line ─────────────────────────────────
    final lastError = _extractLastErrorLine(rawError);
    return ParsedError(
      friendlyMessage: lastError ?? 'An unexpected error occurred. Please try again.',
      friendlyMessageEs: lastError ?? 'Ocurrió un error inesperado. Inténtalo de nuevo.',
      rawDetails: rawError,
    );
  }

  static bool _matchesAny(String text, List<String> patterns) {
    return patterns.any((p) => text.contains(p));
  }

  /// Extracts the last `ERROR:` line from yt-dlp output, stripping the
  /// `ERROR: ` prefix and any `[extractor]` tag.
  static String? _extractLastErrorLine(String raw) {
    final lines = raw.split('\n').reversed;
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('ERROR:')) {
        // Strip "ERROR: [youtube] keqvmRPqius: " → "Unable to extract..."
        var msg = trimmed.substring('ERROR:'.length).trim();
        // Remove extractor tag like "[youtube]"
        final tagEnd = msg.indexOf(']');
        if (msg.startsWith('[') && tagEnd != -1) {
          msg = msg.substring(tagEnd + 1).trim();
          // Remove video ID prefix like "keqvmRPqius: "
          final colonIndex = msg.indexOf(':');
          if (colonIndex != -1 && colonIndex < 20) {
            msg = msg.substring(colonIndex + 1).trim();
          }
        }
        if (msg.isNotEmpty) return msg;
      }
    }
    return null;
  }
}

/// The result of parsing a raw yt-dlp error.
class ParsedError {
  /// Clean, user-facing error message (English).
  final String friendlyMessage;

  /// Clean, user-facing error message (Spanish).
  final String friendlyMessageEs;

  /// Whether the error can likely be resolved by updating the yt-dlp engine.
  final bool needsEngineUpdate;

  /// The original raw error output for technical details.
  final String rawDetails;

  const ParsedError({
    required this.friendlyMessage,
    required this.friendlyMessageEs,
    this.needsEngineUpdate = false,
    required this.rawDetails,
  });
}
