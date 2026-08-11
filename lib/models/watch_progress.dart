/// Progression de lecture d'un épisode (clé logique : épisode).
class WatchProgress {
  const WatchProgress({
    required this.episodeId,
    required this.positionSeconds,
    required this.completed,
    required this.updatedAt,
  });

  final String episodeId;
  final int positionSeconds;
  final bool completed;
  final DateTime updatedAt;

  /// Fraction de progression (0..1) pour un épisode d'une durée donnée.
  double fractionOf(int durationSeconds) {
    if (completed) return 1;
    if (durationSeconds <= 0) return 0;
    return (positionSeconds / durationSeconds).clamp(0.0, 1.0);
  }

  factory WatchProgress.fromJson(Map<String, dynamic> json) => WatchProgress(
        episodeId: json['episode_id'] as String,
        positionSeconds: (json['position_seconds'] as num?)?.toInt() ?? 0,
        completed: json['completed'] as bool? ?? false,
        updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'episode_id': episodeId,
        'position_seconds': positionSeconds,
        'completed': completed,
        'updated_at': updatedAt.toIso8601String(),
      };
}
