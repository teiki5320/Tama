import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tama/services/analytics_service.dart';

/// Les tests tournent en mode démo (client Supabase null) : `flush` y
/// journalise le lot au lieu de l'envoyer, ce qui suffit à vérifier la mise
/// en file et le vidage sans réseau.
Future<AnalyticsService> _service(
    [Map<String, Object> initial = const {}]) async {
  SharedPreferences.setMockInitialValues(initial);
  return AnalyticsService(await SharedPreferences.getInstance(), null);
}

void main() {
  group('identifiant d\'appareil', () {
    test('est engendré au premier appel puis persisté', () async {
      final a = await _service();
      final id = a.deviceId;
      expect(id, isNotEmpty);
      // Une seconde instance sur les mêmes préférences doit retrouver le
      // même appareil, sinon chaque lancement compterait un visiteur neuf
      // et la rétention serait toujours nulle.
      final prefs = await SharedPreferences.getInstance();
      final b = AnalyticsService(prefs, null);
      expect(b.deviceId, id);
    });
  });

  group('file d\'attente', () {
    test('track empile sans envoyer', () async {
      final a = await _service();
      expect(a.pendingCount, 0);
      a.track('episode_start', episodeId: 'e1', seriesId: 's1');
      a.track('episode_complete', episodeId: 'e1', seriesId: 's1');
      expect(a.pendingCount, 2);
    });

    test('flush vide la file', () async {
      final a = await _service();
      a.track('app_open');
      await a.flush();
      expect(a.pendingCount, 0);
    });

    test('flush sur une file vide ne fait rien', () async {
      final a = await _service();
      await a.flush();
      expect(a.pendingCount, 0);
    });

    test('la file est bornée : une panne prolongée ne mange pas la RAM',
        () async {
      final a = await _service();
      for (var i = 0; i < 600; i++) {
        a.track('episode_progress', episodeId: 'e$i');
      }
      expect(a.pendingCount, lessThanOrEqualTo(500));
    });
  });

  group('series_start', () {
    test('n\'est émis qu\'une fois par série et par appareil', () async {
      final a = await _service();
      a.trackSeriesStartIfFirst('serie-1');
      a.trackSeriesStartIfFirst('serie-1');
      a.trackSeriesStartIfFirst('serie-1');
      expect(a.pendingCount, 1,
          reason: 'sinon le nombre de séries commencées serait surévalué');
    });

    test('compte chaque série distincte', () async {
      final a = await _service();
      a.trackSeriesStartIfFirst('serie-1');
      a.trackSeriesStartIfFirst('serie-2');
      expect(a.pendingCount, 2);
    });

    test('survit au redémarrage de l\'app', () async {
      final a = await _service();
      a.trackSeriesStartIfFirst('serie-1');
      await a.flush();
      // Nouvelle instance, mêmes préférences : la série reste « commencée ».
      final prefs = await SharedPreferences.getInstance();
      final b = AnalyticsService(prefs, null);
      b.trackSeriesStartIfFirst('serie-1');
      expect(b.pendingCount, 0);
    });
  });
}
