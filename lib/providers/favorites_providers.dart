import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/series.dart';
import 'auth_providers.dart';
import 'catalog_providers.dart';
import 'repositories_providers.dart';

/// Identifiants des séries favorites.
final favoriteIdsProvider = FutureProvider<Set<String>>((ref) {
  ref.watch(currentUserProvider); // se recharge à la connexion/déconnexion
  return ref.watch(favoritesRepositoryProvider).fetchSeriesIds();
});

/// Séries favorites complètes (croisement favoris × catalogue publié).
final favoriteSeriesProvider = Provider<AsyncValue<List<Series>>>((ref) {
  final ids = ref.watch(favoriteIdsProvider);
  final catalog = ref.watch(publishedSeriesProvider);
  if (ids.isLoading || catalog.isLoading) return const AsyncValue.loading();
  if (ids.hasError) return AsyncValue.error(ids.error!, ids.stackTrace!);
  if (catalog.hasError) {
    return AsyncValue.error(catalog.error!, catalog.stackTrace!);
  }
  final idSet = ids.value ?? const <String>{};
  return AsyncValue.data(
    [
      for (final s in catalog.value ?? const <Series>[])
        if (idSet.contains(s.id)) s
    ],
  );
});

/// Bascule le favori d'une série puis rafraîchit la liste.
Future<void> toggleFavorite(WidgetRef ref, String seriesId) async {
  final repo = ref.read(favoritesRepositoryProvider);
  final current = await ref.read(favoriteIdsProvider.future);
  if (current.contains(seriesId)) {
    await repo.remove(seriesId);
  } else {
    await repo.add(seriesId);
  }
  ref.invalidate(favoriteIdsProvider);
}
