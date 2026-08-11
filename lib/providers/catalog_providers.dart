import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/episode.dart';
import '../models/series.dart';
import 'repositories_providers.dart';
import 'settings_providers.dart';

/// Séries publiées (triées par sort_order, la première est mise en avant).
final publishedSeriesProvider = FutureProvider<List<Series>>(
  (ref) => ref.watch(seriesRepositoryProvider).fetchPublished(),
);

/// Catalogue affiché : filtré par langue préférée, avec repli sur tout le
/// catalogue si aucune série n'existe dans cette langue (jamais d'écran vide
/// à cause d'un réglage).
final catalogProvider = Provider<AsyncValue<List<Series>>>((ref) {
  final language = ref.watch(settingsProvider).language;
  return ref.watch(publishedSeriesProvider).whenData((all) {
    final filtered = all.where((s) => s.language == language.name).toList();
    return filtered.isEmpty ? all : filtered;
  });
});

/// Rails de l'accueil groupés par genre (ordre d'apparition conservé —
/// les littéraux Map de Dart préservent l'ordre d'insertion).
final genreRailsProvider =
    Provider<AsyncValue<Map<String, List<Series>>>>((ref) {
  return ref.watch(catalogProvider).whenData((series) {
    final rails = <String, List<Series>>{};
    for (final s in series) {
      final genre = (s.genre == null || s.genre!.isEmpty) ? 'autres' : s.genre!;
      rails.putIfAbsent(genre, () => []).add(s);
    }
    return rails;
  });
});

final seriesByIdProvider = FutureProvider.family<Series?, String>(
  (ref, id) => ref.watch(seriesRepositoryProvider).fetchById(id),
);

/// Épisodes publiés d'une série, triés par numéro.
final episodesProvider = FutureProvider.family<List<Episode>, String>(
  (ref, seriesId) =>
      ref.watch(episodeRepositoryProvider).fetchForSeries(seriesId),
);
