import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/widgets/async_view.dart';
import '../../models/episode.dart';
import '../../models/series.dart';
import '../../providers/repositories_providers.dart';
import '../../providers/settings_providers.dart';
import 'episode_player_page.dart';

/// Contexte de lecture : la série, ses épisodes triés et l'index de départ.
class PlayerContext {
  const PlayerContext({
    required this.series,
    required this.episodes,
    required this.initialIndex,
  });

  final Series series;
  final List<Episode> episodes;
  final int initialIndex;
}

final playerContextProvider =
    FutureProvider.autoDispose.family<PlayerContext?, String>(
        (ref, episodeId) async {
  final episodeRepo = ref.watch(episodeRepositoryProvider);
  final seriesRepo = ref.watch(seriesRepositoryProvider);
  final episode = await episodeRepo.fetchById(episodeId);
  if (episode == null) return null;
  final series = await seriesRepo.fetchById(episode.seriesId);
  if (series == null) return null;
  final episodes = await episodeRepo.fetchForSeries(episode.seriesId);
  if (episodes.isEmpty) return null;
  final index = episodes.indexWhere((e) => e.id == episodeId);
  return PlayerContext(
    series: series,
    episodes: episodes,
    initialIndex: index < 0 ? 0 : index,
  );
});

/// Écran de lecture plein écran, bord à bord.
/// Swipe vertical : haut = épisode suivant, bas = précédent.
class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key, required this.episodeId});

  final String episodeId;

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  @override
  void initState() {
    super.initState();
    // Plein écran immersif pendant la lecture.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contextAsync = ref.watch(playerContextProvider(widget.episodeId));
    return Scaffold(
      backgroundColor: TamaColors.background,
      body: AsyncView<PlayerContext?>(
        value: contextAsync,
        onRetry: () =>
            ref.invalidate(playerContextProvider(widget.episodeId)),
        builder: (playerContext) {
          if (playerContext == null) {
            return EmptyView(
              icon: Icons.videocam_off_rounded,
              title: 'Épisode introuvable',
              subtitle: 'Il a peut-être été retiré du catalogue.',
              action: OutlinedButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Retour'),
              ),
            );
          }
          return _PlayerPager(playerContext: playerContext);
        },
      ),
    );
  }
}

/// PageView vertical pilotant les rôles de chaque page :
/// - active : la page visible, en lecture ;
/// - preload : LE SEUL épisode suivant, initialisé en pause (contrainte data) ;
/// - idle : aucune ressource allouée.
class _PlayerPager extends ConsumerStatefulWidget {
  const _PlayerPager({required this.playerContext});

  final PlayerContext playerContext;

  @override
  ConsumerState<_PlayerPager> createState() => _PlayerPagerState();
}

class _PlayerPagerState extends ConsumerState<_PlayerPager> {
  late final PageController _pageController =
      PageController(initialPage: widget.playerContext.initialIndex);
  late int _currentIndex = widget.playerContext.initialIndex;

  /// Vrai pendant un enchaînement automatique (pour `manual: false`).
  bool _autoAdvancing = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    if (index > _currentIndex) {
      final from = widget.playerContext.episodes[_currentIndex];
      ref.read(analyticsServiceProvider).track(
        'swipe_next',
        episodeId: from.id,
        seriesId: widget.playerContext.series.id,
        payload: {
          'from_episode': from.episodeNumber,
          'manual': !_autoAdvancing,
        },
      );
    }
    _autoAdvancing = false;
    setState(() => _currentIndex = index);
  }

  /// Enchaînement automatique à la fin d'un épisode, sans écran intermédiaire.
  void _advanceToNext() {
    if (_currentIndex >= widget.playerContext.episodes.length - 1) return;
    _autoAdvancing = true;
    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  /// Depuis la carte de fin : revoir la série depuis le premier épisode.
  void _replayFromStart() {
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final episodes = widget.playerContext.episodes;
    // Le mode données réduites coupe le préchargement de l'épisode suivant.
    final preloadEnabled = !ref.watch(settingsProvider).dataSaver;

    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      onPageChanged: _onPageChanged,
      itemCount: episodes.length,
      itemBuilder: (context, index) {
        final PageRole role;
        if (index == _currentIndex) {
          role = PageRole.active;
        } else if (index == _currentIndex + 1 && preloadEnabled) {
          role = PageRole.preload;
        } else {
          role = PageRole.idle;
        }
        return EpisodePlayerPage(
          key: ValueKey(episodes[index].id),
          series: widget.playerContext.series,
          episode: episodes[index],
          role: role,
          isLast: index == episodes.length - 1,
          onCompleted: _advanceToNext,
          onReplaySeries: _replayFromStart,
        );
      },
    );
  }
}
