import '../../core/constants.dart';

/// Règles de progression de lecture, isolées du widget.
///
/// Elles vivaient dans le `State` du player, mêlées au contrôleur vidéo :
/// invérifiables sans lancer l'app sur un appareil. Or ce sont elles qui
/// décident de tout ce que mesure le MVP — à quel moment un `episode_progress`
/// part, et à partir de quand un épisode compte comme terminé.

/// Pourcentage de lecture, borné à [0, 100].
///
/// Une durée nulle ou négative rend 0 : le contrôleur vidéo annonce
/// brièvement une durée vide entre l'initialisation et la première image.
int playbackPercent(Duration position, Duration duration) {
  if (duration <= Duration.zero) return 0;
  return (position.inMilliseconds / duration.inMilliseconds * 100)
      .clamp(0, 100)
      .round();
}

/// Paliers franchis à [percent] et pas encore émis, dans l'ordre.
///
/// Rendre la liste plutôt que de marquer les paliers au passage laisse
/// l'appelant maître de son état : un tick qui n'aboutit pas ne consomme
/// aucun palier.
List<int> milestonesToEmit(int percent, Set<int> alreadySent) => [
      for (final milestone in TamaConstants.progressMilestones)
        if (percent >= milestone && !alreadySent.contains(milestone)) milestone
    ];

/// Vrai quand la lecture a atteint la fin, à la marge près.
///
/// La marge existe parce que le contrôleur ne délivre pas toujours un dernier
/// tick pile sur la durée : sans elle, un épisode regardé en entier ne
/// compterait jamais comme terminé et `v_completion` resterait vide.
bool isCompletedAt(Duration position, Duration duration) {
  if (duration <= Duration.zero) return false;
  return position >= duration - TamaConstants.completionEpsilon;
}
