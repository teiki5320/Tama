# Tama — instructions projet pour Claude Code

Tama est une app mobile de streaming de micro-dramas verticaux (~1 min),
spécialisée dans les dramas africains francophones, produite par le studio
du propriétaire du repo. MVP sans monétisation : l'unique objectif est de
mesurer la rétention et le taux de complétion (vue SQL `v_retention`).

- Bundle ID : `com.teiki.tama` · Apple Team ID : `K597U7X3FZ`
- Branche principale : `main` (le travail validé finit toujours sur `main`)

## État actuel (ne pas refaire)

- **Base Supabase** : migration complète dans `supabase/migrations/`
  (6 tables, RLS testée, vue `v_retention`), seed de dev dans
  `supabase/seed.sql`. Testée sur Postgres 16.
- **App Flutter complète** : accueil (bannière, rail « Reprendre », rails
  par genre), fiche série, player vertical (swipe, préchargement du seul
  épisode suivant, enchaînement auto, reprise, sauvegarde 5 s), ma liste,
  réglages, auth Supabase, analytics en lots de 10 s.
- **Mode démo intégré** : sans `--dart-define` Supabase, l'app tourne sur
  des données locales (`lib/repositories/mock_data.dart`). Toute nouvelle
  fonctionnalité DOIT continuer à fonctionner en mode démo.
- **TestFlight via Xcode Cloud** (méthode du studio, aucun secret) :
  icônes, Team ID posé, schéma `Runner` partagé, script d'amorçage
  `ios/ci_scripts/ci_post_clone.sh` (doit rester exécutable), guide
  `docs/TESTFLIGHT.md`. Le workflow GitHub Actions `testflight.yml` n'est
  qu'un chemin de secours ; son option « essai à blanc » sert de
  vérification de build sans secrets.

## Distribution — la méthode du studio

**Xcode Cloud, toujours.** Configuration dans App Store Connect, aucun
secret dans le dépôt. Ne pas proposer d'alternative (GitHub Actions,
Codemagic, aperçu web, APK) : la question est tranchée.

## Stack et architecture

Flutter + Riverpod + go_router + Supabase + Bunny Stream (HLS).
Pas de backend custom. Structure : `lib/core` (thème, env, router),
`lib/models`, `lib/repositories` (une classe par table, impl. Supabase +
impl. démo), `lib/providers`, `lib/features/<écran>`, `lib/services`
(analytics, bunny, connectivité).

## Règles non négociables

1. **Aucune couleur, rayon ou taille de police en dur** : tout passe par
   les jetons de `lib/core/theme.dart` (`TamaColors`, `TamaText`,
   `TamaSpacing`, `TamaRadius`). Accent doré = actions et états actifs
   uniquement, jamais en aplat.
2. **Trois états par écran** (chargement / vide / erreur) via
   `lib/core/widgets/async_view.dart`. Pas d'écran blanc, pas d'objet
   invisible mais cliquable.
3. **Réseau dégradé d'abord** : l'app doit rester utilisable en 3G.
   Jamais plus d'un épisode préchargé ; le mode données réduites coupe
   tout préchargement.
4. **Analytics d'abord** : tout nouveau comportement de lecture doit
   émettre les événements adéquats via `AnalyticsService` (batch 10 s,
   `.insert()` sans `.select()` — la lecture de `analytics_events` est
   bloquée par RLS).
5. **Zéro friction** : rien ne doit exiger un compte avant le premier
   favori. La progression anonyme vit en local et se synchronise à la
   connexion.
6. **Commentaires en français**, identifiants en anglais.

## Vérifications avant livraison

```bash
flutter analyze          # doit être à zéro
flutter test             # doit être vert
```

Pour une vérification visuelle : `flutter build web --release`
(CanvasKit est servi localement via `web/flutter_bootstrap.js`), servir
`build/web` et capturer les écrans (390×844). La vidéo de démo se force
avec `--dart-define=DEMO_VIDEO_URL=...`.

## Variables d'environnement (--dart-define)

`SUPABASE_URL`, `SUPABASE_ANON_KEY`, `BUNNY_STREAM_LIBRARY_ID`,
`BUNNY_STREAM_CDN_HOSTNAME` — sans les deux premières : mode démo.

## Backlog connu (phase suivante, sur demande uniquement)

- Brancher le vrai backend (exécuter la migration dans Supabase, charger
  covers 9:16 WebP et identifiants vidéo Bunny réels).
- Icônes adaptatives Android, splash iOS avec logo.
- Phase 2 (seulement si les métriques tiennent) : monétisation.
