/// Constantes applicatives partagées.
abstract final class TamaConstants {
  static const String appName = 'Tama';

  /// Intervalle de sauvegarde de la progression pendant la lecture (debounce).
  static const Duration progressSaveInterval = Duration(seconds: 5);

  /// Intervalle d'envoi des lots d'événements analytics.
  static const Duration analyticsFlushInterval = Duration(seconds: 10);

  /// Délai avant masquage automatique de l'overlay du player.
  static const Duration overlayHideDelay = Duration(seconds: 2);

  /// Saut avant du double tap dans le player.
  static const Duration doubleTapSeek = Duration(seconds: 10);

  /// Paliers (en %) des événements `episode_progress`.
  static const List<int> progressMilestones = [25, 50, 75];

  /// Marge de fin : au-delà, l'épisode est considéré comme terminé.
  static const Duration completionEpsilon = Duration(milliseconds: 400);

  /// Délai au-delà duquel on renonce à ouvrir une vidéo.
  ///
  /// `VideoPlayerController.initialize()` peut ne jamais rendre la main —
  /// réseau qui ne répond plus, flux illisible par le décodeur — sans lever
  /// la moindre erreur. Sans ce plafond, l'écran reste en chargement
  /// indéfiniment : ni image, ni message, ni bouton. Généreux pour tenir en
  /// 3G, mais fini.
  static const Duration videoInitTimeout = Duration(seconds: 20);
}

/// Qualité vidéo choisie dans les réglages.
enum VideoQuality {
  auto,
  p480,
  p720;

  String get label => switch (this) {
        VideoQuality.auto => 'Auto',
        VideoQuality.p480 => '480p',
        VideoQuality.p720 => '720p',
      };
}

/// Langues de contenu proposées.
enum ContentLanguage {
  fr,
  wo,
  en;

  String get label => switch (this) {
        ContentLanguage.fr => 'Français',
        ContentLanguage.wo => 'Wolof',
        ContentLanguage.en => 'English',
      };
}
