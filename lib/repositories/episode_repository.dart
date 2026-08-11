import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/episode.dart';
import 'mock_data.dart';

/// Accès aux épisodes.
abstract class EpisodeRepository {
  /// Épisodes publiés d'une série, triés par numéro.
  Future<List<Episode>> fetchForSeries(String seriesId);

  Future<Episode?> fetchById(String id);
}

/// Implémentation Supabase (production).
class SupabaseEpisodeRepository implements EpisodeRepository {
  SupabaseEpisodeRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Episode>> fetchForSeries(String seriesId) async {
    final rows = await _client
        .from('episodes')
        .select()
        .eq('series_id', seriesId)
        .eq('is_published', true)
        .order('episode_number', ascending: true);
    return rows.map(Episode.fromJson).toList();
  }

  @override
  Future<Episode?> fetchById(String id) async {
    final row =
        await _client.from('episodes').select().eq('id', id).maybeSingle();
    return row == null ? null : Episode.fromJson(row);
  }
}

/// Implémentation de démonstration (aucun backend requis).
class MockEpisodeRepository implements EpisodeRepository {
  static const _latency = Duration(milliseconds: 200);

  @override
  Future<List<Episode>> fetchForSeries(String seriesId) async {
    await Future<void>.delayed(_latency);
    return mockEpisodes[seriesId] ?? const [];
  }

  @override
  Future<Episode?> fetchById(String id) async {
    await Future<void>.delayed(_latency);
    for (final episodes in mockEpisodes.values) {
      for (final e in episodes) {
        if (e.id == id) return e;
      }
    }
    return null;
  }
}
