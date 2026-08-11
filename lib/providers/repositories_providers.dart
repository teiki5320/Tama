import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/env.dart';
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

/// Client Supabase, ou null en mode démo (Supabase non configuré).
final supabaseClientProvider = Provider<SupabaseClient?>(
  (ref) => Env.hasSupabase ? Supabase.instance.client : null,
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
