/// Une série : un micro-drama complet, découpé en épisodes d'environ 1 minute.
class Series {
  const Series({
    required this.id,
    required this.title,
    this.synopsis,
    this.coverUrl,
    this.genre,
    this.language = 'fr',
    this.totalEpisodes = 0,
    this.status = 'ongoing',
    this.sortOrder = 0,
  });

  final String id;
  final String title;
  final String? synopsis;

  /// Visuel portrait 9:16.
  final String? coverUrl;
  final String? genre;
  final String language;
  final int totalEpisodes;

  /// `ongoing` ou `completed`.
  final String status;

  /// Classement manuel en accueil (plus bas = mis en avant).
  final int sortOrder;

  bool get isCompleted => status == 'completed';

  factory Series.fromJson(Map<String, dynamic> json) => Series(
        id: json['id'] as String,
        title: json['title'] as String,
        synopsis: json['synopsis'] as String?,
        coverUrl: json['cover_url'] as String?,
        genre: json['genre'] as String?,
        language: json['language'] as String? ?? 'fr',
        totalEpisodes: (json['total_episodes'] as num?)?.toInt() ?? 0,
        status: json['status'] as String? ?? 'ongoing',
        sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      );
}
