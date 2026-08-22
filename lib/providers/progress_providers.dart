import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/episode.dart';
import '../models/series.dart';
import '../models/watch_progress.dart';
import 'auth_providers.dart';
import 'repositories_providers.dart';

/// Compteur de version : incrémenté après chaque sauvegarde de progression
/// pour que l'accueil et les fiches se rafraîchissent en revenant du player.
final progressVersionProvider = StateProvider<int>((ref) => 0);

/// Toute la progression, la plus récente d'abord.
final progressListProvider = FutureProvider<List<WatchProgress>>((ref) {
  ref.watch(progressVersionProvider);
  ref.watch(currentUserProvider); // se recharge à la connexion/déconnexion
  return ref.watch(progressRepositoryProvider).fetchAll();
});

/// Progression indexée par épisode.
final progressByEpisodeProvider =
    Provider<AsyncValue<Map<String, WatchProgress>>>((ref) {
  return ref.watch(progressListProvider).whenData(
        (list) => {for (final p in list) p.episodeId: p},
      );
});

/// Une entrée du rail « Reprendre » / de l'historique.
class ContinueEntry {
  const ContinueEntry({
    required this.series,
    required this.episode,
    required this.progress,
  });

  final Series series;
  final Episode episode;
  final WatchProgress progress;
}

/// Rail « Reprendre » : le dernier épisode non terminé de chaque série.
final continueWatchingProvider = FutureProvider<List<ContinueEntry>>(
  (ref) => _buildEntries(ref, includeCompleted: false, maxPerSeries: 1),
);

/// Historique de visionnage (écran « Ma liste ») : terminés inclus.
final watchHistoryProvider = FutureProvider<List<ContinueEntry>>(
  (ref) => _buildEntries(ref, includeCompleted: true, maxPerSeries: 3),
);

/// Nombre maximal de lignes affichées.
const _maxEntries = 20;

/// Nombre de progressions examinées. La liste locale peut en contenir 200 ;
/// elle est triée du plus récent au plus ancien, et il en faut largement
/// moins que ça pour remplir [_maxEntries] lignes. Ce plafond borne la
/// taille des deux requêtes ci-dessous.
const _lookupLimit = 60;

Future<List<ContinueEntry>> _buildEntries(
  Ref ref, {
  required bool includeCompleted,
  required int maxPerSeries,
}) async {
  final progresses = await ref.watch(progressListProvider.future);
  final episodeRepo = ref.watch(episodeRepositoryProvider);
  final seriesRepo = ref.watch(seriesRepositoryProvider);

  final candidats = [
    for (final p in progresses)
      if (includeCompleted || !p.completed) p
  ].take(_lookupLimit).toList();
  if (candidats.isEmpty) return const [];

  // Deux requêtes en tout, quelle que soit la longueur de l'historique.
  // Une par ligne — ce que faisait cette fonction — rendait l'accueil
  // inutilisable en 3G dès que le catalogue grossissait.
  final episodes = await episodeRepo.fetchByIds(
    [for (final p in candidats) p.episodeId],
  );
  final episodeById = {for (final e in episodes) e.id: e};

  final seriesList = await seriesRepo.fetchByIds(
    {for (final e in episodes) e.seriesId}.toList(),
  );
  final seriesById = {for (final s in seriesList) s.id: s};

  final entries = <ContinueEntry>[];
  final perSeries = <String, int>{};

  // L'ordre des progressions fait foi : la plus récente d'abord.
  for (final p in candidats) {
    final episode = episodeById[p.episodeId];
    if (episode == null) continue;
    final count = perSeries[episode.seriesId] ?? 0;
    if (count >= maxPerSeries) continue;
    final series = seriesById[episode.seriesId];
    if (series == null) continue;
    perSeries[episode.seriesId] = count + 1;
    entries.add(
      ContinueEntry(series: series, episode: episode, progress: p),
    );
    if (entries.length >= _maxEntries) break;
  }
  return entries;
}

/// Épisode cible pour « Commencer » / « Reprendre à l'épisode N » :
/// 1. l'épisode en cours le plus récent (progression non terminée) ;
/// 2. sinon le premier épisode jamais terminé ;
/// 3. sinon (tout est vu) le premier épisode.
Episode? resumeEpisodeFor(
  List<Episode> episodes,
  Map<String, WatchProgress> progressByEpisode,
) {
  if (episodes.isEmpty) return null;

  Episode? mostRecentPartial;
  DateTime? mostRecentDate;
  for (final e in episodes) {
    final p = progressByEpisode[e.id];
    if (p != null && !p.completed && p.positionSeconds > 0) {
      if (mostRecentDate == null || p.updatedAt.isAfter(mostRecentDate)) {
        mostRecentDate = p.updatedAt;
        mostRecentPartial = e;
      }
    }
  }
  if (mostRecentPartial != null) return mostRecentPartial;

  for (final e in episodes) {
    final p = progressByEpisode[e.id];
    if (p == null || !p.completed) return e;
  }
  return episodes.first;
}
