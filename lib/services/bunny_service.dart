import '../core/constants.dart';
import '../core/env.dart';
import '../models/episode.dart';
import '../models/series.dart';

/// Construit les URLs de lecture et de vignettes Bunny Stream.
///
/// - Qualité « Auto » : playlist HLS adaptative (obligatoire sur 3G).
/// - Qualité forcée ou mode données réduites : rendition MP4 directe.
/// - Sans configuration Bunny (démo) : vidéo d'exemple publique.
class BunnyService {
  /// Surcharge de la vidéo de démo via --dart-define=DEMO_VIDEO_URL=…
  /// (utile pour les tests et les captures d'écran hors ligne).
  static const String _demoOverride = String.fromEnvironment('DEMO_VIDEO_URL');

  /// Vidéo de repli pour la démo, quand Bunny n'est pas configuré.
  static const String _demoDefault =
      'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4';

  static String get demoVideoUrl =>
      _demoOverride.isNotEmpty ? _demoOverride : _demoDefault;

  bool _isDemoVideo(Episode episode) =>
      !Env.hasBunny ||
      episode.bunnyVideoId == 'demo' ||
      episode.bunnyVideoId.startsWith('BUNNY_ID');

  /// Playlist HLS adaptative (le CDN choisit le bitrate selon le réseau).
  String hlsUrl(String videoId) =>
      'https://${Env.bunnyCdnHostname}/$videoId/playlist.m3u8';

  /// Rendition MP4 directe à une hauteur fixe (480 ou 720).
  String mp4Url(String videoId, int height) =>
      'https://${Env.bunnyCdnHostname}/$videoId/play_${height}p.mp4';

  /// URL de lecture d'un épisode selon les réglages de l'utilisateur.
  String playbackUrl(
    Episode episode, {
    required VideoQuality quality,
    required bool dataSaver,
  }) {
    if (_isDemoVideo(episode)) return demoVideoUrl;
    // Le mode données réduites force la rendition la plus légère.
    if (dataSaver) return mp4Url(episode.bunnyVideoId, 480);
    return switch (quality) {
      VideoQuality.auto => hlsUrl(episode.bunnyVideoId),
      VideoQuality.p480 => mp4Url(episode.bunnyVideoId, 480),
      VideoQuality.p720 => mp4Url(episode.bunnyVideoId, 720),
    };
  }

  /// Affiche d'une série, par ordre de préférence : l'affiche déposée si
  /// elle existe, sinon la vignette de son premier épisode. Bunny en génère
  /// une pour chaque vidéo, au format de la vidéo — donc verticale, donc
  /// utilisable telle quelle. Rien à préparer, rien à saisir.
  ///
  /// `null` déclenche l'affiche typographique, dernier recours.
  String? seriesCoverUrl(Series series) {
    final cover = series.coverUrl;
    if (cover != null && cover.isNotEmpty) return cover;
    final videoId = series.coverVideoId;
    if (!Env.hasBunny ||
        videoId == null ||
        videoId.isEmpty ||
        videoId == 'demo' ||
        videoId.startsWith('BUNNY_ID')) {
      return null;
    }
    return 'https://${Env.bunnyCdnHostname}/$videoId/thumbnail.jpg';
  }

  /// Vignette d'un épisode (celle stockée en base, sinon celle de Bunny).
  String? thumbnailUrl(Episode episode) {
    if (episode.thumbnailUrl != null && episode.thumbnailUrl!.isNotEmpty) {
      return episode.thumbnailUrl;
    }
    if (_isDemoVideo(episode)) return null;
    return 'https://${Env.bunnyCdnHostname}/${episode.bunnyVideoId}/thumbnail.jpg';
  }
}
