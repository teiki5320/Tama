/// Un épisode d'une série, hébergé sur Bunny Stream.
class Episode {
  const Episode({
    required this.id,
    required this.seriesId,
    this.season = 1,
    required this.episodeNumber,
    this.title,
    required this.bunnyVideoId,
    this.thumbnailUrl,
    this.durationSeconds = 0,
  });

  final String id;
  final String seriesId;

  /// Saison, à partir de 1. La numérotation des épisodes repart à 1 à
  /// chaque saison, comme sur Netflix.
  final int season;
  final int episodeNumber;

  /// Titre optionnel de l'épisode.
  final String? title;

  /// Identifiant vidéo Bunny Stream.
  final String bunnyVideoId;
  final String? thumbnailUrl;
  final int durationSeconds;

  /// Titre affiché : le titre s'il existe, sinon « Épisode N ».
  String get displayTitle =>
      (title != null && title!.isNotEmpty) ? title! : 'Épisode $episodeNumber';

  factory Episode.fromJson(Map<String, dynamic> json) => Episode(
        id: json['id'] as String,
        seriesId: json['series_id'] as String,
        season: (json['season'] as num?)?.toInt() ?? 1,
        episodeNumber: (json['episode_number'] as num).toInt(),
        title: json['title'] as String?,
        bunnyVideoId: json['bunny_video_id'] as String,
        thumbnailUrl: json['thumbnail_url'] as String?,
        durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 0,
      );
}
