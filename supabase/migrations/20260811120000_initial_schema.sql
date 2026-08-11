-- ============================================================================
-- TAMA — Migration initiale
-- Schéma complet : tables, contraintes, index, politiques RLS, triggers
-- et vue analytics `v_retention`.
--
-- Utilisation : coller ce script tel quel dans l'éditeur SQL de Supabase
-- (Dashboard > SQL Editor > New query > Run), ou l'appliquer via
-- `supabase db push` si le CLI est configuré.
-- ============================================================================

-- gen_random_uuid() est natif sur Postgres 13+, l'extension est là par sécurité.
create extension if not exists "pgcrypto";

-- ============================================================================
-- 1. TABLES
-- ============================================================================

-- ----------------------------------------------------------------------------
-- series : une série = un micro-drama complet
-- ----------------------------------------------------------------------------
create table public.series (
  id             uuid primary key default gen_random_uuid(),
  title          text not null,
  synopsis       text,
  cover_url      text,                                  -- visuel portrait 9:16
  genre          text,                                  -- romance, vengeance, thriller, comédie…
  language       text not null default 'fr',            -- fr, wo, en
  total_episodes int  not null default 0,
  status         text not null default 'ongoing'
                 check (status in ('ongoing', 'completed')),
  is_published   bool not null default false,
  sort_order     int  not null default 0,               -- classement manuel en accueil (plus bas = mis en avant)
  created_at     timestamptz not null default now()
);

-- ----------------------------------------------------------------------------
-- episodes : un épisode d'environ 1 minute, hébergé sur Bunny Stream
-- ----------------------------------------------------------------------------
create table public.episodes (
  id               uuid primary key default gen_random_uuid(),
  series_id        uuid not null references public.series (id) on delete cascade,
  episode_number   int  not null check (episode_number > 0),
  title            text,                                -- optionnel
  bunny_video_id   text not null,                       -- identifiant vidéo Bunny Stream
  thumbnail_url    text,
  duration_seconds int  not null default 0,
  is_published     bool not null default false,
  created_at       timestamptz not null default now(),

  -- Un seul épisode N par série
  unique (series_id, episode_number)
);

-- ----------------------------------------------------------------------------
-- profiles : profil applicatif lié 1:1 à auth.users
-- ----------------------------------------------------------------------------
create table public.profiles (
  id           uuid primary key references auth.users (id) on delete cascade,
  display_name text,
  avatar_url   text,
  created_at   timestamptz not null default now()
);

-- Création automatique du profil à l'inscription d'un utilisateur.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, new.raw_user_meta_data ->> 'display_name')
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ----------------------------------------------------------------------------
-- watch_progress : position de lecture par utilisateur et par épisode (upsert)
-- ----------------------------------------------------------------------------
create table public.watch_progress (
  user_id          uuid not null references auth.users (id) on delete cascade,
  episode_id       uuid not null references public.episodes (id) on delete cascade,
  position_seconds int  not null default 0 check (position_seconds >= 0),
  completed        bool not null default false,
  updated_at       timestamptz not null default now(),

  primary key (user_id, episode_id)
);

-- updated_at maintenu côté base, quel que soit le client.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger watch_progress_set_updated_at
  before update on public.watch_progress
  for each row execute function public.set_updated_at();

-- ----------------------------------------------------------------------------
-- favorites : séries mises en favori par un utilisateur
-- ----------------------------------------------------------------------------
create table public.favorites (
  user_id    uuid not null references auth.users (id) on delete cascade,
  series_id  uuid not null references public.series (id) on delete cascade,
  created_at timestamptz not null default now(),

  primary key (user_id, series_id)
);

-- ----------------------------------------------------------------------------
-- analytics_events : la raison d'être de ce MVP.
-- Insertion ouverte (y compris anonyme), lecture interdite côté client.
-- Pas de clés étrangères : on garde l'historique brut même si un épisode
-- ou une série est supprimé plus tard.
-- ----------------------------------------------------------------------------
create table public.analytics_events (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid,                                      -- null = utilisateur anonyme
  device_id  text not null,                             -- uuid local persistant, généré côté app
  event_name text not null,
  episode_id uuid,
  series_id  uuid,
  payload    jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

-- ============================================================================
-- 2. INDEX
-- ============================================================================

-- Rails et fiche série
create index idx_episodes_series          on public.episodes (series_id, episode_number);
create index idx_series_published_sort    on public.series (sort_order) where is_published;

-- Rail « Reprendre » : dernières progressions d'un utilisateur
create index idx_watch_progress_user_date on public.watch_progress (user_id, updated_at desc);
create index idx_favorites_user_date      on public.favorites (user_id, created_at desc);

-- Requêtes analytics (vue v_retention et exports)
create index idx_analytics_event_episode  on public.analytics_events (event_name, episode_id);
create index idx_analytics_series         on public.analytics_events (series_id);
create index idx_analytics_created        on public.analytics_events (created_at);

-- ============================================================================
-- 3. ROW LEVEL SECURITY
-- ============================================================================

alter table public.series           enable row level security;
alter table public.episodes         enable row level security;
alter table public.profiles         enable row level security;
alter table public.watch_progress   enable row level security;
alter table public.favorites        enable row level security;
alter table public.analytics_events enable row level security;

-- ----------------------------------------------------------------------------
-- series : lecture publique limitée au contenu publié.
-- Aucune policy d'écriture : la gestion du catalogue passe par le Dashboard
-- ou la service role key, jamais par l'app.
-- ----------------------------------------------------------------------------
create policy "Lecture publique des séries publiées"
  on public.series
  for select
  to anon, authenticated
  using (is_published = true);

-- ----------------------------------------------------------------------------
-- episodes : lecture publique si l'épisode ET sa série sont publiés.
-- ----------------------------------------------------------------------------
create policy "Lecture publique des épisodes publiés"
  on public.episodes
  for select
  to anon, authenticated
  using (
    is_published = true
    and exists (
      select 1 from public.series s
      where s.id = episodes.series_id
        and s.is_published = true
    )
  );

-- ----------------------------------------------------------------------------
-- profiles : chacun ne voit et ne modifie que son propre profil.
-- ----------------------------------------------------------------------------
create policy "Lecture de son propre profil"
  on public.profiles
  for select
  to authenticated
  using (auth.uid() = id);

create policy "Création de son propre profil"
  on public.profiles
  for insert
  to authenticated
  with check (auth.uid() = id);

create policy "Mise à jour de son propre profil"
  on public.profiles
  for update
  to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- ----------------------------------------------------------------------------
-- watch_progress : lecture/écriture réservées au propriétaire.
-- ----------------------------------------------------------------------------
create policy "Progression : accès complet à son propre historique"
  on public.watch_progress
  for all
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ----------------------------------------------------------------------------
-- favorites : lecture/écriture réservées au propriétaire.
-- ----------------------------------------------------------------------------
create policy "Favoris : accès complet à ses propres favoris"
  on public.favorites
  for all
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ----------------------------------------------------------------------------
-- analytics_events : insertion ouverte à tous, y compris anonyme.
-- Un utilisateur connecté ne peut pas se faire passer pour un autre
-- (user_id doit être null ou égal à auth.uid()).
-- AUCUNE policy SELECT : la lecture côté client est bloquée par RLS.
-- Côté app, faire un .insert() SANS .select() chaîné, sinon PostgREST
-- tentera une lecture qui sera refusée.
-- ----------------------------------------------------------------------------
create policy "Analytics : insertion ouverte (y compris anonyme)"
  on public.analytics_events
  for insert
  to anon, authenticated
  with check (user_id is null or user_id = auth.uid());

-- ============================================================================
-- 4. VUE ANALYTICS — v_retention
-- Par série et par numéro d'épisode :
--   - starts            : nombre de démarrages (episode_start)
--   - completions       : nombre de complétions (episode_complete)
--   - completion_rate   : taux de complétion en %
--   - median_dropoff_s  : seconde médiane de décrochage (episode_dropoff)
--
-- security_invoker = on : la vue s'exécute avec les droits de l'appelant.
-- Combiné à l'absence de policy SELECT sur analytics_events et au REVOKE
-- ci-dessous, elle n'est consultable que depuis le Dashboard / service role.
-- ============================================================================
create view public.v_retention
with (security_invoker = on)
as
select
  s.id                as series_id,
  s.title             as series_title,
  e.episode_number,
  count(*) filter (where ev.event_name = 'episode_start')    as starts,
  count(*) filter (where ev.event_name = 'episode_complete') as completions,
  round(
    count(*) filter (where ev.event_name = 'episode_complete')::numeric
      / nullif(count(*) filter (where ev.event_name = 'episode_start'), 0)
      * 100,
    1
  )                   as completion_rate_pct,
  percentile_cont(0.5) within group (
    order by (ev.payload ->> 'second')::numeric
  ) filter (
    where ev.event_name = 'episode_dropoff'
      and ev.payload ? 'second'
  )                   as median_dropoff_seconds
from public.analytics_events ev
join public.episodes e on e.id = ev.episode_id
join public.series   s on s.id = e.series_id
where ev.event_name in ('episode_start', 'episode_complete', 'episode_dropoff')
group by s.id, s.title, e.episode_number
order by s.title, e.episode_number;

-- La vue ne doit jamais être lisible depuis l'app.
revoke all on public.v_retention from anon, authenticated;
