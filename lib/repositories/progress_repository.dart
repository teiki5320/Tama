import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/watch_progress.dart';
import 'mock_data.dart';

/// Accès à la progression de lecture.
///
/// Principe « zéro friction » : la progression est TOUJOURS écrite en local
/// d'abord (elle ne dépend jamais du réseau ni d'un compte). Si l'utilisateur
/// est connecté, elle est aussi poussée vers Supabase (upsert), et la copie
/// distante devient la source de vérité en lecture.
class ProgressRepository {
  ProgressRepository(this._prefs, this._client);

  final SharedPreferences _prefs;

  /// Null en mode démo (Supabase non configuré).
  final SupabaseClient? _client;

  static const _localKey = 'watch_progress_v1';

  /// Nombre maximal d'entrées conservées en local.
  static const _localLimit = 200;

  bool get _isLoggedIn => _client?.auth.currentUser != null;

  /// Toute la progression, triée de la plus récente à la plus ancienne.
  Future<List<WatchProgress>> fetchAll() async {
    if (_isLoggedIn) {
      try {
        final rows = await _client!
            .from('watch_progress')
            .select()
            .order('updated_at', ascending: false);
        return rows.map(WatchProgress.fromJson).toList();
      } catch (_) {
        // Réseau dégradé : on retombe sur la copie locale.
        return _readLocal();
      }
    }
    return _readLocal();
  }

  /// Progression d'un épisode donné (null si jamais lu).
  Future<WatchProgress?> forEpisode(String episodeId) async {
    final all = await fetchAll();
    for (final p in all) {
      if (p.episodeId == episodeId) return p;
    }
    return null;
  }

  /// Sauvegarde (upsert) la progression d'un épisode.
  Future<void> save(WatchProgress progress) async {
    // 1. Local d'abord, toujours.
    final local = _readLocal()
      ..removeWhere((p) => p.episodeId == progress.episodeId)
      ..insert(0, progress);
    await _writeLocal(local);

    // 2. Distant si connecté (best effort : le local suffit en cas d'échec).
    if (_isLoggedIn) {
      try {
        await _client!.from('watch_progress').upsert({
          'user_id': _client.auth.currentUser!.id,
          'episode_id': progress.episodeId,
          'position_seconds': progress.positionSeconds,
          'completed': progress.completed,
        });
      } catch (_) {
        // On resynchronisera plus tard.
      }
    }
  }

  /// Pousse la progression locale vers Supabase — appelé à la connexion,
  /// pour que l'historique anonyme suive l'utilisateur sur son compte.
  Future<void> syncLocalToRemote() async {
    if (!_isLoggedIn) return;
    final userId = _client!.auth.currentUser!.id;
    final local = _readLocal();
    if (local.isEmpty) return;
    try {
      await _client.from('watch_progress').upsert([
        for (final p in local)
          {
            'user_id': userId,
            'episode_id': p.episodeId,
            'position_seconds': p.positionSeconds,
            'completed': p.completed,
          }
      ]);
    } catch (_) {
      // Best effort : la copie locale reste disponible.
    }
  }

  List<WatchProgress> _readLocal() {
    final raw = _prefs.getString(_localKey);
    if (raw != null) {
      try {
        final list = (jsonDecode(raw) as List)
            .map((e) => WatchProgress.fromJson(e as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        return list;
      } catch (_) {
        // Donnée corrompue : on repart de zéro plutôt que de planter.
        return [];
      }
    }
    // Premier lancement en mode démo : progression pré-remplie pour que
    // le rail « Reprendre » soit visible immédiatement.
    if (_client == null) {
      final seed = demoProgressSeed();
      _writeLocal(seed);
      return seed;
    }
    return [];
  }

  Future<void> _writeLocal(List<WatchProgress> list) => _prefs.setString(
        _localKey,
        jsonEncode([for (final p in list.take(_localLimit)) p.toJson()]),
      );
}
