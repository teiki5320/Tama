import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_client.dart';
import '../repositories/episode_repository.dart';
import '../repositories/favorites_repository.dart';
import '../repositories/progress_repository.dart';
import '../repositories/series_repository.dart';
import '../services/analytics_service.dart';
import '../services/bunny_service.dart';

/// Instance de SharedPreferences, surchargée dans main().
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Surchargé dans main()'),
);

/// Client Supabase, ou null quand l'app tourne sur ses données locales —
/// soit qu'aucune clé n'ait été fournie, soit que l'initialisation ait
/// échoué. Dans les deux cas les dépôts de démonstration prennent le relais
/// et l'app reste utilisable.
final supabaseClientProvider = Provider<SupabaseClient?>(
  (ref) => supabaseStatus == SupabaseStatus.ready
      ? Supabase.instance.client
      : null,
);

final seriesRepositoryProvider = Provider<SeriesRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null
      ? MockSeriesRepository()
      : SupabaseSeriesRepository(client);
});

final episodeRepositoryProvider = Provider<EpisodeRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null
      ? MockEpisodeRepository()
      : SupabaseEpisodeRepository(client);
});

final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => ProgressRepository(
    ref.watch(sharedPreferencesProvider),
    ref.watch(supabaseClientProvider),
  ),
);

final favoritesRepositoryProvider = Provider<FavoritesRepository>(
  (ref) => FavoritesRepository(
    ref.watch(sharedPreferencesProvider),
    ref.watch(supabaseClientProvider),
  ),
);

final bunnyServiceProvider = Provider<BunnyService>((ref) => BunnyService());

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final service = AnalyticsService(
    ref.watch(sharedPreferencesProvider),
    ref.watch(supabaseClientProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});
