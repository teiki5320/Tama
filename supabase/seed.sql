-- ============================================================================
-- TAMA — Données de test (OPTIONNEL)
-- À exécuter APRÈS la migration initiale, uniquement sur un projet de dev.
-- Permet de valider l'app avant que le vrai catalogue soit chargé.
-- Les bunny_video_id sont des placeholders à remplacer par de vrais
-- identifiants Bunny Stream pour que la lecture fonctionne.
-- ============================================================================

insert into public.series (id, title, synopsis, cover_url, genre, language, total_episodes, status, is_published, sort_order)
values
  (
    '11111111-1111-1111-1111-111111111111',
    'Le Prix du silence',
    'Aïcha découvre le secret qui a brisé sa famille. Pour le venger, elle devra se taire… ou tout perdre.',
    null,
    'vengeance',
    'fr',
    3,
    'ongoing',
    true,
    0
  ),
  (
    '22222222-2222-2222-2222-222222222222',
    'Dakar Love',
    'Entre deux mondes et deux promesses, Bineta doit choisir : le cœur ou le devoir.',
    null,
    'romance',
    'fr',
    2,
    'ongoing',
    true,
    1
  );

insert into public.episodes (series_id, episode_number, title, bunny_video_id, duration_seconds, is_published)
values
  ('11111111-1111-1111-1111-111111111111', 1, 'La lettre',      'BUNNY_ID_A_REMPLACER_1', 62, true),
  ('11111111-1111-1111-1111-111111111111', 2, 'Le retour',      'BUNNY_ID_A_REMPLACER_2', 58, true),
  ('11111111-1111-1111-1111-111111111111', 3, 'Face à face',    'BUNNY_ID_A_REMPLACER_3', 65, true),
  ('22222222-2222-2222-2222-222222222222', 1, 'La rencontre',   'BUNNY_ID_A_REMPLACER_4', 60, true),
  ('22222222-2222-2222-2222-222222222222', 2, 'La promesse',    'BUNNY_ID_A_REMPLACER_5', 63, true);
