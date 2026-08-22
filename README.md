# Tama

Application mobile de streaming de micro-dramas verticaux (~1 min/épisode),
spécialisée dans les dramas africains francophones. Le nom vient du tama,
le tambour parleur — celui qui raconte.

**Stack** : Flutter (iOS + Android) · Supabase (auth, Postgres, RLS, storage) ·
Bunny Stream (HLS adaptatif) · Riverpod.

Phase actuelle : MVP sans monétisation, centré sur la mesure de la rétention
et du taux de complétion.

## Lancer l'app

```bash
flutter pub get

# Mode démo (aucun backend requis) : catalogue local de 6 séries,
# progression et favoris pré-remplis, vidéo de démonstration.
flutter run

# Mode production : Supabase + Bunny Stream
flutter run \
  --dart-define=SUPABASE_URL=https://xxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=... \
  --dart-define=BUNNY_STREAM_LIBRARY_ID=... \
  --dart-define=BUNNY_STREAM_CDN_HOSTNAME=vz-xxx.b-cdn.net
```

Sans `SUPABASE_URL`/`SUPABASE_ANON_KEY`, l'app bascule automatiquement en
mode démo — pratique pour valider l'UX avant de brancher le backend.

Distribution iOS : **Xcode Cloud**, voir [docs/TESTFLIGHT.md](docs/TESTFLIGHT.md).
Hébergement vidéo : **Bunny Stream**, voir [docs/BUNNY.md](docs/BUNNY.md).

### Structure

```
lib/
  main.dart
  core/          # theme.dart (jetons), layout.dart (paliers d'écran),
                 # widgets/ (affiches, trame, cascade), env, router
  models/        # series, episode, watch_progress
  repositories/  # accès données (impl. Supabase + impl. démo), une classe par table
  providers/     # riverpod (catalogue, progression, favoris, réglages, auth)
  features/
    home/        # accueil : bannière, rail « Reprendre », rails par genre
    series/      # fiche série : grille d'épisodes, reprise, favori
    player/      # player vertical : swipe, préchargement, enchaînement auto
    favorites/   # ma liste : favoris + historique
    settings/    # réglages : compte, données réduites, qualité, langue
  services/      # analytics (batch 10 s), bunny (URLs HLS/MP4), connectivité
```

### Choix techniques clés

- **Player** : `PageView` vertical ; seul l'épisode suivant est préchargé
  (jamais plus), coupé en mode données réduites. Enchaînement automatique
  en fin d'épisode, sauvegarde de progression toutes les 5 s et à la sortie.
- **Analytics** : événements en file locale, envoyés par lots toutes les
  10 s dans `analytics_events` (insertion anonyme autorisée, lecture
  interdite par RLS). `v_retention` agrège démarrages, complétions et
  décrochages par épisode.
- **Zéro friction** : lecture immédiate sans compte ; la progression
  anonyme vit en local et est synchronisée vers le compte à la connexion.
  L'auth n'est demandée qu'au premier favori.
- **Affiches sans travail préalable** : une série affiche l'affiche
  déposée si elle existe, sinon la vignette de son premier épisode — Bunny
  en génère une par vidéo, verticale comme la vidéo — sinon une affiche
  typographique dérivée du genre et du titre. La vue `v_series_cards`
  fournit l'identifiant vidéo nécessaire sans requête supplémentaire.
- **Mise en page adaptative** : trois paliers (téléphone, tablette, grand
  écran) centralisés dans `core/layout.dart` ; aucun écran ne fixe ses
  propres dimensions.
- **Réseau dégradé** : HLS adaptatif via Bunny (qualité « Auto »),
  renditions MP4 forcées en 480p/720p, polices embarquées (aucun
  téléchargement au runtime), CanvasKit servi localement sur le web.

## Base de données (Supabase)

Le schéma complet est dans [`supabase/migrations/20260811120000_initial_schema.sql`](supabase/migrations/20260811120000_initial_schema.sql).

### Appliquer la migration

1. Ouvrir le Dashboard Supabase → **SQL Editor** → **New query**.
2. Coller l'intégralité du fichier de migration et exécuter (**Run**).
3. Optionnel (dev uniquement) : exécuter [`supabase/seed.sql`](supabase/seed.sql)
   pour disposer de 2 séries et 5 épisodes de test. Remplacer les
   `bunny_video_id` placeholders par de vrais identifiants Bunny Stream
   pour que la lecture fonctionne.

Ou via le CLI Supabase : `supabase db push`.

### Contenu du schéma

| Table | Rôle | Accès client (RLS) |
|---|---|---|
| `series` | Catalogue des séries | Lecture publique si `is_published` |
| `episodes` | Épisodes (id vidéo Bunny) | Lecture publique si épisode **et** série publiés |
| `profiles` | Profil lié à `auth.users`, créé automatiquement à l'inscription | Propriétaire uniquement |
| `watch_progress` | Position de lecture, PK `(user_id, episode_id)`, upsert | Propriétaire uniquement |
| `favorites` | Séries favorites | Propriétaire uniquement |
| `analytics_events` | Événements de tracking | Insertion ouverte (anonyme inclus), **lecture interdite** |

La vue **`v_series_cards`** sert le catalogue à l'app : les colonnes de
`series`, plus l'identifiant vidéo du premier épisode publié, qui sert
d'affiche de repli. C'est elle que lit `SeriesRepository`, pas la table.

La vue **`v_retention`** expose, par série et par numéro d'épisode : démarrages,
complétions, taux de complétion (%) et seconde médiane de décrochage. Elle n'est
lisible que depuis le Dashboard / service role, jamais depuis l'app. C'est le
tableau de bord hebdomadaire du MVP :

```sql
select * from v_retention;
```

### Points d'implémentation côté app

- Les insertions dans `analytics_events` doivent se faire avec `.insert()`
  **sans** `.select()` chaîné : la lecture de la table est bloquée par RLS.
- `analytics_events.user_id` doit être `null` (anonyme) ou égal à
  `auth.uid()` — toute autre valeur est rejetée.
- L'écriture du catalogue (`series`, `episodes`) passe uniquement par le
  Dashboard ou la service role key, jamais par l'app.

## Variables d'environnement

```
SUPABASE_URL=<...>
SUPABASE_ANON_KEY=<...>
BUNNY_STREAM_LIBRARY_ID=<...>
BUNNY_STREAM_CDN_HOSTNAME=<...>
BUNDLE_ID=com.teiki.tama
APPLE_TEAM_ID=K597U7X3FZ
```
