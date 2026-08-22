import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/episode.dart';
import 'mock_data.dart';

/// Accès aux épisodes.
abstract class EpisodeRepository {
  /// Épisodes publiés d'une série, triés par numéro.
  Future<List<Episode>> fetchForSeries(String seriesId);

  Future<Episode?> fetchById(String id);

  /// Plusieurs épisodes en un seul appel. Le rail « Reprendre » en a besoin :
  /// une requête par ligne d'historique rendait l'accueil inutilisable sur un
  /// réseau lent. L'ordre du résultat n'est pas garanti — l'appelant indexe.
  Future<List<Episode>> fetchByIds(List<String> ids);
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

  @override
  Future<List<Episode>> fetchByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final rows =
        await _client.from('episodes').select().inFilter('id', ids);
    return rows.map(Episode.fromJson).toList();
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

  @override
  Future<List<Episode>> fetchByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    await Future<void>.delayed(_latency);
    final wanted = ids.toSet();
    return [
      for (final episodes in mockEpisodes.values)
        for (final e in episodes)
          if (wanted.contains(e.id)) e
    ];
  }
}
