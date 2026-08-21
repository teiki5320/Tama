import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/series.dart';
import 'mock_data.dart';

/// Accès aux séries.
abstract class SeriesRepository {
  /// Séries publiées, triées par `sort_order` (la première est mise en avant).
  Future<List<Series>> fetchPublished();

  Future<Series?> fetchById(String id);
}

/// Implémentation Supabase (production). Le filtre `is_published` est aussi
/// garanti côté base par les policies RLS.
///
/// La lecture passe par la vue `v_series_cards` plutôt que par la table :
/// elle ajoute l'identifiant vidéo du premier épisode, qui sert d'affiche de
/// repli, sans requête supplémentaire depuis le téléphone.
class SupabaseSeriesRepository implements SeriesRepository {
  SupabaseSeriesRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Series>> fetchPublished() async {
    final rows = await _client
        .from('v_series_cards')
        .select()
        .eq('is_published', true)
        .order('sort_order', ascending: true);
    return rows.map(Series.fromJson).toList();
  }

  @override
  Future<Series?> fetchById(String id) async {
    final row = await _client
        .from('v_series_cards')
        .select()
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : Series.fromJson(row);
  }
}

/// Implémentation de démonstration (aucun backend requis).
class MockSeriesRepository implements SeriesRepository {
  /// Petit délai pour rendre les états de chargement visibles.
  static const _latency = Duration(milliseconds: 250);

  @override
  Future<List<Series>> fetchPublished() async {
    await Future<void>.delayed(_latency);
    return [...mockSeries]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  @override
  Future<Series?> fetchById(String id) async {
    await Future<void>.delayed(_latency);
    for (final s in mockSeries) {
      if (s.id == id) return s;
    }
    return null;
  }
}
