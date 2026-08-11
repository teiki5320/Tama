import '../models/episode.dart';
import '../models/series.dart';
import '../models/watch_progress.dart';

/// Données de démonstration, utilisées uniquement quand Supabase n'est pas
/// configuré (`Env.hasSupabase == false`). Elles permettent de parcourir
/// toute l'app — accueil, fiches, player, favoris — sans aucun backend.

const List<Series> mockSeries = [
  Series(
    id: 'demo-serie-1',
    title: 'Le Prix du silence',
    synopsis:
        'Aïcha découvre le secret qui a brisé sa famille. Pour le venger, '
        'elle devra se taire… ou tout perdre.',
    genre: 'vengeance',
    language: 'fr',
    totalEpisodes: 8,
    status: 'ongoing',
    sortOrder: 0,
  ),
  Series(
    id: 'demo-serie-2',
    title: 'Dakar Love',
    synopsis:
        'Entre deux mondes et deux promesses, Bineta doit choisir : '
        'le cœur ou le devoir.',
    genre: 'romance',
    language: 'fr',
    totalEpisodes: 6,
    status: 'ongoing',
    sortOrder: 1,
  ),
  Series(
    id: 'demo-serie-3',
    title: 'Abidjan la nuit',
    synopsis:
        'Un chauffeur de taxi devient le témoin gênant d\'une affaire '
        'qui remonte très haut.',
    genre: 'thriller',
    language: 'fr',
    totalEpisodes: 7,
    status: 'ongoing',
    sortOrder: 2,
  ),
  Series(
    id: 'demo-serie-4',
    title: 'La Dot',
    synopsis:
        'Pour épouser Aminata, Karim doit réunir une dot impossible — '
        'et sa belle-famille ne va rien lui épargner.',
    genre: 'comédie',
    language: 'fr',
    totalEpisodes: 6,
    status: 'completed',
    sortOrder: 3,
  ),
  Series(
    id: 'demo-serie-5',
    title: 'Trahison à Cocody',
    synopsis:
        'Le jour de son mariage, Adjoua apprend qui a réellement signé '
        'la ruine de son père.',
    genre: 'vengeance',
    language: 'fr',
    totalEpisodes: 8,
    status: 'ongoing',
    sortOrder: 4,
  ),
  Series(
    id: 'demo-serie-6',
    title: 'Cœur de Téranga',
    synopsis:
        'Un chef cuisinier de Saint-Louis remet en jeu son restaurant — '
        'et son premier amour.',
    genre: 'romance',
    language: 'wo',
    totalEpisodes: 5,
    status: 'ongoing',
    sortOrder: 5,
  ),
  Series(
    id: 'demo-serie-7',
    title: 'Le Pacte de minuit',
    synopsis:
        'Trois étudiants de Yaoundé concluent un pacte qui va les '
        'dépasser, une nuit de coupure générale.',
    genre: 'thriller',
    language: 'fr',
    totalEpisodes: 6,
    status: 'ongoing',
    sortOrder: 6,
  ),
  Series(
    id: 'demo-serie-8',
    title: 'Bienvenue au maquis',
    synopsis:
        'La petite gargote de Tantie Rosalie affronte l\'ouverture d\'un '
        'fast-food climatisé juste en face.',
    genre: 'comédie',
    language: 'fr',
    totalEpisodes: 5,
    status: 'ongoing',
    sortOrder: 7,
  ),
];

/// Titres des premiers épisodes de la série mise en avant (pour la démo).
const List<String> _serie1Titles = [
  'La lettre',
  'Le retour',
  'Face à face',
  'Le prix à payer',
];

/// Génère la liste d'épisodes d'une série de démo.
List<Episode> _makeEpisodes(String seriesId, int count,
    {List<String> titles = const []}) {
  return List.generate(count, (i) {
    final number = i + 1;
    return Episode(
      id: '$seriesId-ep$number',
      seriesId: seriesId,
      episodeNumber: number,
      title: i < titles.length ? titles[i] : null,
      bunnyVideoId: 'demo',
      durationSeconds: 52 + (number * 7) % 19,
    );
  });
}

final Map<String, List<Episode>> mockEpisodes = {
  for (final s in mockSeries)
    s.id: _makeEpisodes(
      s.id,
      s.totalEpisodes,
      titles: s.id == 'demo-serie-1' ? _serie1Titles : const [],
    ),
};

/// Progression pré-remplie en mode démo, pour que le rail « Reprendre »
/// et l'historique soient visibles dès le premier lancement.
List<WatchProgress> demoProgressSeed() {
  final now = DateTime.now();
  return [
    WatchProgress(
      episodeId: 'demo-serie-1-ep3',
      positionSeconds: 24,
      completed: false,
      updatedAt: now.subtract(const Duration(hours: 2)),
    ),
    WatchProgress(
      episodeId: 'demo-serie-1-ep2',
      positionSeconds: 0,
      completed: true,
      updatedAt: now.subtract(const Duration(hours: 3)),
    ),
    WatchProgress(
      episodeId: 'demo-serie-1-ep1',
      positionSeconds: 0,
      completed: true,
      updatedAt: now.subtract(const Duration(hours: 4)),
    ),
    WatchProgress(
      episodeId: 'demo-serie-3-ep1',
      positionSeconds: 41,
      completed: false,
      updatedAt: now.subtract(const Duration(days: 1)),
    ),
  ];
}

/// Favoris pré-remplis en mode démo.
const List<String> demoFavoriteSeed = ['demo-serie-2', 'demo-serie-4'];
