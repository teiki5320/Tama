import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../core/constants.dart';

/// Service de tracking — la raison d'être de ce MVP.
///
/// Les événements sont mis en file localement puis envoyés en batch toutes
/// les 10 s (`analytics_events` accepte l'insertion anonyme, la lecture est
/// bloquée par RLS). En cas d'échec réseau, le lot est remis en file et
/// retenté au tick suivant. En mode démo, les lots sont simplement journalisés.
class AnalyticsService {
  AnalyticsService(this._prefs, this._client);

  final SharedPreferences _prefs;

  /// Null en mode démo (Supabase non configuré).
  final SupabaseClient? _client;

  static const _deviceIdKey = 'device_id';
  static const _startedSeriesKey = 'started_series_v1';

  /// Taille maximale de la file en mémoire (protection contre une panne
  /// réseau prolongée : on préfère perdre des événements que la RAM).
  static const _queueLimit = 500;

  final List<Map<String, dynamic>> _queue = [];
  Timer? _timer;
  bool _flushing = false;

  /// Identifiant anonyme et persistant de l'appareil.
  late final String deviceId = _loadDeviceId();

  String _loadDeviceId() {
    var id = _prefs.getString(_deviceIdKey);
    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      _prefs.setString(_deviceIdKey, id);
    }
    return id;
  }

  /// Démarre le batching et trace l'ouverture de l'app.
  void start() {
    _timer ??= Timer.periodic(
      TamaConstants.analyticsFlushInterval,
      (_) => flush(),
    );
    track('app_open');
  }

  /// Empile un événement (envoi différé, jamais bloquant pour l'UI).
  void track(
    String eventName, {
    String? episodeId,
    String? seriesId,
    Map<String, dynamic> payload = const {},
  }) {
    if (_queue.length >= _queueLimit) {
      _queue.removeAt(0);
    }
    _queue.add({
      'device_id': deviceId,
      'user_id': _client?.auth.currentUser?.id,
      'event_name': eventName,
      'episode_id': episodeId,
      'series_id': seriesId,
      'payload': payload,
    });
  }

  /// `series_start` : envoyé une seule fois par série et par appareil.
  void trackSeriesStartIfFirst(String seriesId) {
    final started = _prefs.getStringList(_startedSeriesKey) ?? [];
    if (started.contains(seriesId)) return;
    started.add(seriesId);
    _prefs.setStringList(_startedSeriesKey, started);
    track('series_start', seriesId: seriesId);
  }

  /// Envoie le lot en attente. Appelé toutes les 10 s, à la mise en
  /// arrière-plan de l'app et à la fermeture.
  Future<void> flush() async {
    if (_flushing || _queue.isEmpty) return;
    _flushing = true;
    final batch = List<Map<String, dynamic>>.from(_queue);
    _queue.clear();
    try {
      if (_client == null) {
        debugPrint('[analytics démo] lot de ${batch.length} événement(s) : '
            '${batch.map((e) => e['event_name']).join(', ')}');
        return;
      }
      // .insert() SANS .select() : la lecture de la table est interdite
      // par RLS, PostgREST ne doit donc rien tenter de retourner.
      await _client.from('analytics_events').insert(batch);
    } catch (e) {
      // Un envoi qui échoue en silence rend toute panne de mesure
      // indiagnosticable : le 26/08/2026, des `episode_complete` ont
      // disparu sans laisser la moindre trace. L'erreur est donc écrite,
      // avec les événements du lot — PostgREST rejette le lot entier dès
      // qu'une seule ligne est invalide.
      debugPrint('[analytics] envoi échoué (${batch.length} événement(s) : '
          '${batch.map((m) => m['event_name']).join(', ')}) : $e');
      // Échec réseau : on remet le lot en tête de file pour le prochain tick.
      _queue.insertAll(0, batch.take(_queueLimit - _queue.length));
    } finally {
      _flushing = false;
    }
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    flush();
  }
}
