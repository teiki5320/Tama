# Tama

Application mobile de streaming de micro-dramas verticaux (~1 min/épisode),
spécialisée dans les dramas africains francophones. Le nom vient du tama,
le tambour parleur — celui qui raconte.

**Stack** : Flutter (iOS + Android) · Supabase (auth, Postgres, RLS, storage) ·
Bunny Stream (HLS adaptatif) · Riverpod.

Phase actuelle : MVP sans monétisation, centré sur la mesure de la rétention
et du taux de complétion.

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
