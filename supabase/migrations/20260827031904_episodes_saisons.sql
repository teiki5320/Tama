-- ============================================================================
-- TAMA — Saisons
--
-- Décision du 27/08/2026 : une saison 2 arrive entière et s'ajoute À LA
-- SUITE de la première, dans la même série — façon Netflix : même fiche,
-- mêmes favoris, même historique, et un sélecteur de saison sur la fiche.
--
-- La numérotation des épisodes repart à 1 à chaque saison (« S2 E1 »),
-- comme partout ailleurs : l'unicité passe donc de (série, numéro) à
-- (série, saison, numéro).
-- ============================================================================

alter table public.episodes
  add column season int not null default 1 check (season > 0);

alter table public.episodes
  drop constraint episodes_series_id_episode_number_key;

alter table public.episodes
  add constraint episodes_series_season_number_key
  unique (series_id, season, episode_number);

-- L'affiche de repli reste la vignette du tout premier épisode publié —
-- désormais « saison 1, épisode 1 » et non plus le plus petit numéro
-- toutes saisons confondues.
create or replace view public.v_series_cards
with (security_invoker = on)
as
select
  s.*,
  (
    select e.bunny_video_id
    from public.episodes e
    where e.series_id = s.id
      and e.is_published
    order by e.season, e.episode_number
    limit 1
  ) as cover_video_id
from public.series s;
