import 'package:flutter_test/flutter_test.dart';
import 'package:tama/models/series.dart';
import 'package:tama/services/bunny_service.dart';

Series _serie({String? coverUrl, String? coverVideoId}) => Series(
      id: 'serie',
      title: 'Le Prix du silence',
      coverUrl: coverUrl,
      coverVideoId: coverVideoId,
    );

void main() {
  final bunny = BunnyService();

  // Ces tests tournent sans --dart-define, donc `Env.hasBunny` est faux :
  // ils couvrent la règle de priorité et les replis, pas la fabrication de
  // l'URL de vignette, qui suppose une bibliothèque configurée.
  group('BunnyService.seriesCoverUrl — la cascade d\'affiches', () {
    test('l\'affiche déposée passe avant tout le reste', () {
      final url = bunny.seriesCoverUrl(
        _serie(
          coverUrl: 'https://exemple.test/affiche.jpg',
          coverVideoId: 'une-video',
        ),
      );
      expect(url, 'https://exemple.test/affiche.jpg');
    });

    test('une affiche vide ne compte pas pour une affiche', () {
      expect(bunny.seriesCoverUrl(_serie(coverUrl: '')), isNull);
    });

    test('sans affiche ni vidéo, on tombe sur l\'affiche typographique', () {
      expect(bunny.seriesCoverUrl(_serie()), isNull);
    });

    test('un identifiant de démonstration ne produit pas de vignette', () {
      expect(bunny.seriesCoverUrl(_serie(coverVideoId: 'demo')), isNull);
      expect(
        bunny.seriesCoverUrl(_serie(coverVideoId: 'BUNNY_ID_A_REMPLACER_1')),
        isNull,
      );
    });
  });
}
