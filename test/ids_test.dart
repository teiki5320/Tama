import 'package:flutter_test/flutter_test.dart';
import 'package:tama/core/ids.dart';

void main() {
  group('isUuid — ce que Postgres accepte dans une colonne uuid', () {
    test('un identifiant Supabase réel passe', () {
      expect(isUuid('9d3d233a-13a0-4ef0-9967-5455e4e061d8'), isTrue);
    });

    test('un identifiant hérité du mode démo est écarté', () {
      expect(isUuid('demo-serie-1-ep3'), isFalse);
      expect(isUuid('demo-serie-1'), isFalse);
    });

    test('une chaîne vide ou tronquée est écartée', () {
      expect(isUuid(''), isFalse);
      expect(isUuid('9d3d233a-13a0-4ef0-9967'), isFalse);
    });
  });
}
