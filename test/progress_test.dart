import 'package:flutter_test/flutter_test.dart';
import 'package:tama/models/episode.dart';
import 'package:tama/models/watch_progress.dart';
import 'package:tama/providers/progress_providers.dart';

Episode _episode(int number) => Episode(
      id: 'ep$number',
      seriesId: 'serie',
      episodeNumber: number,
      bunnyVideoId: 'demo',
      durationSeconds: 60,
    );

WatchProgress _progress(
  String episodeId, {
  int seconds = 30,
  bool completed = false,
  int minutesAgo = 0,
}) =>
    WatchProgress(
      episodeId: episodeId,
      positionSeconds: seconds,
      completed: completed,
      updatedAt: DateTime(2026, 8, 22, 12).subtract(
        Duration(minutes: minutesAgo),
      ),
    );

void main() {
  group('WatchProgress.fractionOf', () {
    test('un épisode terminé est plein, quelle que soit la durée connue', () {
      // Cas réel : `duration_seconds` vaut 0 en base tant que personne ne
      // l'a saisie. La jauge doit quand même se remplir.
      expect(_progress('ep1', completed: true).fractionOf(0), 1);
      expect(_progress('ep1', completed: true).fractionOf(60), 1);
    });

    test('sans durée connue, la jauge reste vide plutôt que fausse', () {
      expect(_progress('ep1', seconds: 30).fractionOf(0), 0);
    });

    test('la fraction est bornée entre 0 et 1', () {
      expect(_progress('ep1', seconds: 30).fractionOf(60), 0.5);
      expect(_progress('ep1', seconds: 90).fractionOf(60), 1);
      expect(_progress('ep1', seconds: 0).fractionOf(60), 0);
    });
  });

  group('resumeEpisodeFor', () {
    final episodes = [_episode(1), _episode(2), _episode(3)];

    test('sans épisode, il n\'y a rien à reprendre', () {
      expect(resumeEpisodeFor(const [], const {}), isNull);
    });

    test('sans historique, on commence au premier épisode', () {
      expect(resumeEpisodeFor(episodes, const {})?.id, 'ep1');
    });

    test('un épisode entamé l\'emporte sur l\'ordre du catalogue', () {
      final progress = {'ep2': _progress('ep2', seconds: 20)};
      expect(resumeEpisodeFor(episodes, progress)?.id, 'ep2');
    });

    test('entre deux épisodes entamés, le plus récemment vu gagne', () {
      final progress = {
        'ep1': _progress('ep1', seconds: 10, minutesAgo: 60),
        'ep3': _progress('ep3', seconds: 10, minutesAgo: 5),
      };
      expect(resumeEpisodeFor(episodes, progress)?.id, 'ep3');
    });

    test('après un épisode terminé, on enchaîne sur le suivant', () {
      final progress = {'ep1': _progress('ep1', completed: true)};
      expect(resumeEpisodeFor(episodes, progress)?.id, 'ep2');
    });

    test('série entièrement vue : on repropose le premier épisode', () {
      final progress = {
        for (final e in episodes) e.id: _progress(e.id, completed: true),
      };
      expect(resumeEpisodeFor(episodes, progress)?.id, 'ep1');
    });

    test('une position à zéro ne compte pas comme un épisode entamé', () {
      // Sinon un simple passage sur l'épisode 3 détournerait le bouton
      // « Commencer » de l'épisode 1.
      final progress = {'ep3': _progress('ep3', seconds: 0)};
      expect(resumeEpisodeFor(episodes, progress)?.id, 'ep1');
    });
  });
}
