import 'package:flutter_test/flutter_test.dart';
import 'package:tama/features/player/playback_progress.dart';

const _episode = Duration(seconds: 75);

void main() {
  group('playbackPercent', () {
    test('rend la proportion lue', () {
      expect(playbackPercent(Duration.zero, _episode), 0);
      expect(
          playbackPercent(
              const Duration(seconds: 37, milliseconds: 500), _episode),
          50);
      expect(playbackPercent(_episode, _episode), 100);
    });

    test('ne dépasse jamais 100 même si la position déborde', () {
      expect(playbackPercent(const Duration(seconds: 200), _episode), 100);
    });

    test('rend 0 sur une durée inconnue plutôt que de diviser par zéro', () {
      // Le contrôleur annonce une durée vide entre l'initialisation et la
      // première image : ce cas arrive à chaque ouverture d'épisode.
      expect(playbackPercent(const Duration(seconds: 5), Duration.zero), 0);
      expect(playbackPercent(Duration.zero, const Duration(seconds: -1)), 0);
    });
  });

  group('milestonesToEmit', () {
    test('ne rend rien avant le premier palier', () {
      expect(milestonesToEmit(24, {}), isEmpty);
    });

    test('rend le palier atteint', () {
      expect(milestonesToEmit(25, {}), [25]);
    });

    test('rend tous les paliers franchis d\'un coup', () {
      // Cas réel : un spectateur qui saute en avant traverse plusieurs
      // paliers entre deux ticks. Aucun ne doit être perdu.
      expect(milestonesToEmit(80, {}), [25, 50, 75]);
    });

    test('n\'émet jamais deux fois le même palier', () {
      expect(milestonesToEmit(60, {25, 50}), isEmpty);
      expect(milestonesToEmit(75, {25, 50}), [75]);
    });

    test('ne consomme aucun palier : la fonction est sans effet de bord', () {
      final envoyes = <int>{};
      expect(milestonesToEmit(50, envoyes), [25, 50]);
      expect(envoyes, isEmpty,
          reason: 'un tick abandonné ne doit pas perdre de palier');
    });
  });

  group('isCompletedAt', () {
    test('un épisode regardé en entier compte comme terminé', () {
      expect(isCompletedAt(_episode, _episode), isTrue);
    });

    test('la marge rattrape un dernier tick légèrement court', () {
      // Sans elle, `v_completion` resterait vide : le contrôleur ne délivre
      // pas toujours un tick pile sur la durée.
      expect(
          isCompletedAt(
              const Duration(seconds: 74, milliseconds: 800), _episode),
          isTrue);
    });

    test('un épisode abandonné en route ne compte pas', () {
      expect(isCompletedAt(const Duration(seconds: 74), _episode), isFalse);
      expect(isCompletedAt(const Duration(seconds: 40), _episode), isFalse);
      expect(isCompletedAt(Duration.zero, _episode), isFalse);
    });

    test('une durée inconnue ne déclenche pas une fausse complétion', () {
      // Position et durée valent toutes deux zéro juste après l'ouverture :
      // sans garde, l'épisode serait déclaré terminé avant d'avoir commencé.
      expect(isCompletedAt(Duration.zero, Duration.zero), isFalse);
    });
  });
}
