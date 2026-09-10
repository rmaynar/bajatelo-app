// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get logo => 'bajatelo';

  @override
  String get badge => 'Descargador Universal • Rápido y Gratis';

  @override
  String get heroTitle1 => 'Descargador de';

  @override
  String get heroTitle2 => 'Vídeo y Audio';

  @override
  String get heroSubtitle =>
      'Descarga vídeos y música de YouTube, TikTok, Instagram, Twitter/X, Facebook, Twitch y más de 1.000 plataformas en la máxima calidad MP4 o MP3.';

  @override
  String get supportedPlatformsLabel => 'Plataformas compatibles:';

  @override
  String get inputPlaceholder =>
      'Pega el enlace de YouTube, TikTok, Instagram, X/Twitter, Twitch...';

  @override
  String get searchBtn => 'Buscar';

  @override
  String get searchingBtn => 'Buscando...';

  @override
  String get pasteTooltip => 'Pegar del portapapeles';

  @override
  String get clearTooltip => 'Limpiar enlace';

  @override
  String get downloadVideo => 'Descargar Vídeo (MP4)';

  @override
  String get downloadAudio => 'Descargar Audio (MP3)';

  @override
  String get processingVideo => 'Procesando Vídeo...';

  @override
  String get processingAudio => 'Procesando Audio...';

  @override
  String get processingNotice =>
      'Convirtiendo y unificando streams. La descarga comenzará automáticamente en unos momentos.';

  @override
  String get duration => 'Duración';

  @override
  String get videoFormatTag => 'Vídeo MP4 / Mejor Calidad';

  @override
  String get audioFormatTag => 'Audio MP3 / 320kbps';

  @override
  String get feature1Title => '+1.000 Sitios Compatibles';

  @override
  String get feature1Desc =>
      'Compatible con YouTube, TikTok, Instagram (Reels/Posts), Twitter/X, Twitch, Facebook, SoundCloud, Reddit y más.';

  @override
  String get feature2Title => 'Ultra Rápido';

  @override
  String get feature2Desc =>
      'Potenciado por yt-dlp y FFmpeg con procesamiento eficiente y fusión de flujos de media.';

  @override
  String get feature3Title => '100% Libre y Privado';

  @override
  String get feature3Desc =>
      'Sin registros, sin límites y con descargas directas a tu dispositivo sin intermediarios.';

  @override
  String get footer =>
      'bajatelo • Descargador Universal de Medios Rápido, Privado y Gratuito';

  @override
  String get clipboardError =>
      'No se pudo leer el portapapeles. Pega el enlace manualmente.';

  @override
  String get defaultError =>
      'Error al obtener información del vídeo. Comprueba la URL e inténtalo de nuevo.';

  @override
  String get cancelDownload => 'Cancelar';

  @override
  String get downloadComplete => 'Descarga completada';

  @override
  String get downloadCompleteDesc =>
      'Archivo guardado en la carpeta de Descargas.';

  @override
  String get switchToEnglish => 'Cambiar a inglés';

  @override
  String get switchToSpanish => 'Cambiar a español';
}
