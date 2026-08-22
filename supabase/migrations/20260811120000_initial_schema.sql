-- ============================================================================
-- TAMA — Migration initiale
-- Schéma complet : tables, contraintes, index, politiques RLS, triggers
-- et vues analytiques `v_completion` et `v_retention`.
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
  genre          text,                                  -- romance, vengeance, thriller, drame…
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

-- total_episodes est affiché tel quel sur la fiche série. Personne ne pense
-- à le corriger en publiant un épisode de plus : la base le tient elle-même.
-- Le compte ne retient que les épisodes publiés, comme l'app.
create or replace function public.refresh_total_episodes()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  cibles uuid[];
begin
  -- Les branches sont explicites plutôt que condensées dans un CASE :
  -- PL/pgSQL résout les variables référencées avant d'exécuter l'expression,
  -- si bien qu'un `old.series_id` protégé par un CASE serait quand même lu
  -- sur un INSERT — où OLD n'existe pas.
  if tg_op = 'INSERT' then
    cibles := array[new.series_id];
  elsif tg_op = 'DELETE' then
    cibles := array[old.series_id];
  else
    -- Un UPDATE peut déplacer un épisode d'une série à l'autre : les deux
    -- compteurs sont alors à refaire.
    cibles := array[old.series_id, new.series_id];
  end if;

  update public.series s
  set total_episodes = (
    select count(*)
    from public.episodes e
    where e.series_id = s.id
      and e.is_published
  )
  where s.id = any (cibles);
  return null;
end;
$$;

create trigger episodes_refresh_total_episodes
  after insert or update or delete on public.episodes
  for each row execute function public.refresh_total_episodes();

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

-- Requêtes analytiques (vues v_completion / v_retention et exports)
create index idx_analytics_event_episode  on public.analytics_events (event_name, episode_id);
create index idx_analytics_series         on public.analytics_events (series_id);
create index idx_analytics_created        on public.analytics_events (created_at);
-- v_retention balaie les `app_open` par appareil et par jour.
create index idx_analytics_open_device    on public.analytics_events (device_id, created_at)
                                          where event_name = 'app_open';

-- ============================================================================
-- 3. VUE DU CATALOGUE
-- ============================================================================
-- v_series_cards : les séries telles que l'app les affiche, augmentées de
-- l'identifiant vidéo de leur premier épisode publié.
--
-- Pourquoi : sans affiche déposée, l'app se rabat sur la vignette que Bunny
-- génère pour chaque vidéo. Comme les épisodes sont verticaux, cette vignette
-- est déjà au format d'une affiche. Personne n'a d'image à préparer ni
-- d'adresse à recopier — la mise en ligne de la vidéo suffit.
--
-- La vue évite une requête par série depuis le téléphone : l'accueil charge
-- son catalogue en un seul appel, ce qui compte sur un réseau lent.
--
-- security_invoker = on : les policies RLS de `series` et `episodes`
-- s'appliquent normalement, la vue n'ouvre aucun accès supplémentaire.
-- ----------------------------------------------------------------------------
create view public.v_series_cards
with (security_invoker = on)
as
select
  s.*,
  (
    select e.bunny_video_id
    from public.episodes e
    where e.series_id = s.id
      and e.is_published
    order by e.episode_number
    limit 1
  ) as cover_video_id
from public.series s;

grant select on public.v_series_cards to anon, authenticated;

-- ============================================================================
-- 4. ROW LEVEL SECURITY
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
-- 5. VUES ANALYTIQUES
--
-- Le MVP mesure deux choses, et ce sont deux questions différentes :
--   - `v_completion` : est-ce qu'on regarde un épisode jusqu'au bout ?
--   - `v_retention`  : est-ce qu'on revient le lendemain ?
--
-- security_invoker = on sur les deux : elles s'exécutent avec les droits de
-- l'appelant. Combiné à l'absence de policy SELECT sur analytics_events et
-- aux REVOKE ci-dessous, elles ne sont consultables que depuis le Dashboard
-- ou avec la service role key.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- v_completion — par série et par numéro d'épisode :
--   - starts               : nombre de démarrages (episode_start)
--   - completions          : nombre de complétions (episode_complete)
--   - completion_rate_pct  : taux de complétion en %
--   - median_dropoff_secs  : seconde médiane de décrochage (episode_dropoff)
-- ----------------------------------------------------------------------------
create view public.v_completion
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

-- ----------------------------------------------------------------------------
-- v_retention — la vraie rétention, par cohorte de premier jour.
--
-- Un appareil (`device_id`, anonyme et persistant) compte une fois par jour,
-- quel que soit le nombre d'ouvertures. Sa cohorte est le jour de sa
-- première ouverture ; on regarde ensuite s'il est revenu à J+1 et à J+7.
--
-- `jours_ecoules` évite le contresens classique : une cohorte née hier
-- affiche forcément 0 % à J+7, faute de temps — pas faute d'intérêt. Tant
-- que `jours_ecoules` est inférieur à 7, la colonne J+7 ne veut rien dire.
-- ----------------------------------------------------------------------------
create view public.v_retention
with (security_invoker = on)
as
with jours as (
  select distinct
    device_id,
    (created_at at time zone 'UTC')::date as jour
  from public.analytics_events
  where event_name = 'app_open'
),
cohortes as (
  select device_id, min(jour) as cohorte
  from jours
  group by device_id
)
select
  c.cohorte,
  current_date - c.cohorte          as jours_ecoules,
  count(*)                          as nouveaux,
  count(j1.device_id)               as revenus_j1,
  count(j7.device_id)               as revenus_j7,
  round(count(j1.device_id)::numeric / nullif(count(*), 0) * 100, 1)
                                    as retention_j1_pct,
  round(count(j7.device_id)::numeric / nullif(count(*), 0) * 100, 1)
                                    as retention_j7_pct
from cohortes c
-- `jours` ne contient qu'une ligne par appareil et par date : ces deux
-- jointures ne peuvent pas démultiplier les lignes, un appareil reste un
-- appareil dans le décompte.
left join jours j1
  on j1.device_id = c.device_id and j1.jour = c.cohorte + 1
left join jours j7
  on j7.device_id = c.device_id and j7.jour = c.cohorte + 7
group by c.cohorte
order by c.cohorte desc;

-- Ces vues ne doivent jamais être lisibles depuis l'app.
revoke all on public.v_completion from anon, authenticated;
revoke all on public.v_retention  from anon, authenticated;
