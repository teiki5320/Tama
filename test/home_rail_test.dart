import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tama/core/theme.dart';
import 'package:tama/features/home/home_screen.dart';
import 'package:tama/models/series.dart';
import 'package:tama/providers/catalog_providers.dart';
import 'package:tama/providers/progress_providers.dart';
import 'package:tama/providers/repositories_providers.dart';

/// Reproduit le catalogue réel du 24/08/2026 : une seule série publiée.
const _serie = Series(
  id: 'test-1',
  title: 'La femme aux poulets',
  synopsis: 'Awa vend ses poulets au marché.',
  genre: 'vengeance',
  totalEpisodes: 3,
  coverVideoId: '9d3d233a-13a0-4ef0-9967-5455e4e061d8',
);

void main() {
  testWidgets(
    'avec une seule série, l\'accueil affiche la bannière ET son rail de genre',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            publishedSeriesProvider.overrideWith((ref) async => [_serie]),
            continueWatchingProvider.overrideWith((ref) async => []),
          ],
          child: MaterialApp(
            theme: buildTamaTheme(),
            home: const Scaffold(body: HomeScreen()),
          ),
        ),
      );
      // Laisse passer le chargement des providers et la cascade d'entrée.
      // pumpAndSettle est exclu : l'accueil porte une animation continue.
      // On avance le temps à la main, assez pour que les Futures se
      // résolvent et que la cascade d'entrée se termine.
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Les titres sont rendus en capitales par le style « affiche ».
      expect(find.text('LA FEMME AUX POULETS'), findsWidgets,
          reason: 'la bannière doit afficher la série');
      expect(find.text('VENGEANCE'), findsWidgets,
          reason: 'le rail du genre « vengeance » doit être rendu');
    },
  );

  testWidgets(
    'une progression illisible efface le rail sans griser l\'accueil',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            publishedSeriesProvider.overrideWith((ref) async => [_serie]),
            // Reproduit le 24/08/2026 : des identifiants de démo restés en
            // local font échouer la requête Supabase du rail « Reprendre ».
            continueWatchingProvider.overrideWith(
              (ref) async => throw Exception('invalid input syntax for uuid'),
            ),
          ],
          child: MaterialApp(
            theme: buildTamaTheme(),
            home: const Scaffold(body: HomeScreen()),
          ),
        ),
      );
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // L'accueil doit rester debout : c'est le rail qui s'efface, pas l'écran.
      expect(find.text('LA FEMME AUX POULETS'), findsWidgets,
          reason: 'la bannière survit à une progression illisible');
      expect(find.text('VENGEANCE'), findsWidgets,
          reason: 'le rail de genre survit à une progression illisible');
      expect(find.text('REPRENDRE'), findsNothing,
          reason: 'le rail « Reprendre » s\'efface au lieu de griser');
    },
  );
}
