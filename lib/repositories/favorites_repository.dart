import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'mock_data.dart';

/// Accès aux favoris.
///
/// - Supabase configuré + connecté : table `favorites`.
/// - Supabase configuré + anonyme : indisponible — l'UI propose la connexion
///   (c'est LE moment où l'auth est demandée, cf. « zéro friction »).
/// - Mode démo (pas de Supabase) : stockage local, pour la démonstration.
class FavoritesRepository {
  FavoritesRepository(this._prefs, this._client);

  final SharedPreferences _prefs;
  final SupabaseClient? _client;

  static const _localKey = 'demo_favorites_v1';

  bool get _isDemo => _client == null;

  /// Vrai si l'utilisateur peut mettre en favori sans se connecter.
  bool get canFavorite => _isDemo || _client!.auth.currentUser != null;

  Future<Set<String>> fetchSeriesIds() async {
    if (_isDemo) {
      if (!_prefs.containsKey(_localKey)) {
        // Premier lancement démo : quelques favoris pré-remplis.
        await _prefs.setStringList(_localKey, demoFavoriteSeed);
      }
      return (_prefs.getStringList(_localKey) ?? const []).toSet();
    }
    if (_client!.auth.currentUser == null) return {};
    final rows = await _client.from('favorites').select('series_id');
    return {for (final r in rows) r['series_id'] as String};
  }

  Future<void> add(String seriesId) async {
    if (_isDemo) {
      final list = (_prefs.getStringList(_localKey) ?? [])..add(seriesId);
      await _prefs.setStringList(_localKey, list.toSet().toList());
      return;
    }
    final user = _client!.auth.currentUser;
    if (user == null) return;
    await _client.from('favorites').upsert({
      'user_id': user.id,
      'series_id': seriesId,
    });
  }

  Future<void> remove(String seriesId) async {
    if (_isDemo) {
      final list = (_prefs.getStringList(_localKey) ?? [])..remove(seriesId);
      await _prefs.setStringList(_localKey, list);
      return;
    }
    final user = _client!.auth.currentUser;
    if (user == null) return;
    await _client
        .from('favorites')
        .delete()
        .eq('user_id', user.id)
        .eq('series_id', seriesId);
  }
}
