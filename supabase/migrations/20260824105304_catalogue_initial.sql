-- ============================================================================
-- TAMA — Premier catalogue : « La femme aux poulets »
--
-- Les trois identifiants vidéo viennent de `docs/BUNNY.md` et ont été
-- vérifiés le 22/08/2026 : vignette, HLS et MP4 répondent tous 200.
--
-- Le genre reste une valeur simple (`vengeance`) : l'accueil groupe ses
-- rails sur ce champ exact, et `TamaColors.forGenre` y lit la couleur de
-- la série. La romance et le drame se jouent dans le synopsis.
-- ============================================================================

-- L'insertion des épisodes est chaînée à celle de la série : pas d'UUID à
-- recopier à la main, et pas d'épisode orphelin si quelque chose échoue.
--
-- `total_episodes` n'est pas renseigné ici : le trigger
-- `episodes_refresh_total_episodes` le calcule à partir des épisodes publiés.
with nouvelle_serie as (
  insert into public.series
    (title, synopsis, genre, language, status, is_published, sort_order)
  values (
    'La femme aux poulets',
    'Awa vend ses poulets au marché pour payer les études de sa fille. '
      || 'Le jour où elle retrouve dans une poubelle le collier qu''elle '
      || 'croyait perdu, tout remonte : la chambre 307, l''homme qui lui a '
      || 'menti, et ce qu''on lui a pris. Elle ne criera pas. Elle rendra '
      || 'coup pour coup.',
    'vengeance',
    'fr',
    'ongoing',
    true,     -- publiée : sans ça, RLS la rend invisible depuis l'app
    0         -- plus bas = mis en avant ; 0 la place en bannière
  )
  returning id
)
insert into public.episodes
  (series_id, episode_number, title, bunny_video_id, duration_seconds,
   is_published)
select
  nouvelle_serie.id, e.numero, e.titre, e.video_id, e.duree, true
from nouvelle_serie,
  (values
    (1, 'Chambre 307',
        '9d3d233a-13a0-4ef0-9967-5455e4e061d8', 75),
    (2, 'Achète mes poulets',
        '799d7c29-fabf-44f3-bf2e-cc9fc7a17d41', 75),
    (3, 'Le collier dans la poubelle',
        '7fb57eda-368e-4063-b3fe-e9c21e3f7796', 75)
  ) as e(numero, titre, video_id, duree);
