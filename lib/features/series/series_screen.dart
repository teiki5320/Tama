import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/series_card.dart';
import '../../models/episode.dart';
import '../../models/series.dart';
import '../../models/watch_progress.dart';
import '../../providers/catalog_providers.dart';
import '../../providers/progress_providers.dart';
import 'favorite_button.dart';

/// Fiche série : cover, métadonnées, bouton commencer/reprendre,
/// grille numérotée des épisodes (vus marqués), favori.
class SeriesScreen extends ConsumerWidget {
  const SeriesScreen({super.key, required this.seriesId});

  final String seriesId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seriesAsync = ref.watch(seriesByIdProvider(seriesId));
    return Scaffold(
      body: AsyncView<Series?>(
        value: seriesAsync,
        onRetry: () => ref.invalidate(seriesByIdProvider(seriesId)),
        builder: (series) {
          if (series == null) {
            return EmptyView(
              icon: Icons.search_off_rounded,
              title: 'Série introuvable',
              subtitle: 'Elle a peut-être été retirée du catalogue.',
              action: OutlinedButton(
                onPressed: () => context.pop(),
                child: const Text('Retour'),
              ),
            );
          }
          return _SeriesDetail(series: series);
        },
      ),
    );
  }
}

class _SeriesDetail extends ConsumerWidget {
  const _SeriesDetail({required this.series});

  final Series series;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final episodesAsync = ref.watch(episodesProvider(series.id));
    final progressMap = ref.watch(progressByEpisodeProvider).value ??
        const <String, WatchProgress>{};

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 340,
          pinned: true,
          backgroundColor: TamaColors.background,
          actions: [FavoriteButton(seriesId: series.id)],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                SeriesCover(
                  series: series,
                  borderRadius: BorderRadius.zero,
                  showTitle: false,
                ),
                // Fondu vers le fond de l'écran pour asseoir le contenu.
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.4, 1],
                      colors: [Colors.transparent, TamaColors.background],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(TamaSpacing.l),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: TamaSpacing.s,
                  runSpacing: TamaSpacing.s,
                  children: [
                    if (series.genre != null) _MetaChip(series.genre!),
                    _MetaChip(series.language.toUpperCase()),
                    _MetaChip(series.isCompleted ? 'Terminée' : 'En cours'),
                    _MetaChip('${series.totalEpisodes} épisodes'),
                  ],
                ),
                const SizedBox(height: TamaSpacing.m),
                Text(series.title, style: TamaText.titleXL),
                if (series.synopsis != null) ...[
                  const SizedBox(height: TamaSpacing.s),
                  Text(series.synopsis!, style: TamaText.body),
                ],
                const SizedBox(height: TamaSpacing.l),
                _StartButton(series: series),
                const SizedBox(height: TamaSpacing.s),
              ],
            ),
          ),
        ),
        episodesAsync.when(
          loading: () => const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(TamaSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (_, __) => SliverToBoxAdapter(
            child: ErrorView(
              message: 'Impossible de charger les épisodes.',
              onRetry: () => ref.invalidate(episodesProvider(series.id)),
            ),
          ),
          data: (episodes) => episodes.isEmpty
              ? const SliverToBoxAdapter(
                  child: EmptyView(
                    icon: Icons.video_library_outlined,
                    title: 'Aucun épisode publié',
                    subtitle: 'Les premiers épisodes arrivent bientôt.',
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    TamaSpacing.l,
                    0,
                    TamaSpacing.l,
                    TamaSpacing.xxl,
                  ),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      mainAxisSpacing: TamaSpacing.s,
                      crossAxisSpacing: TamaSpacing.s,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _EpisodeCell(
                        episode: episodes[i],
                        progress: progressMap[episodes[i].id],
                      ),
                      childCount: episodes.length,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

/// Bouton principal : « Commencer », « Reprendre à l'épisode N » ou
/// « Revoir depuis le début » selon l'historique.
class _StartButton extends ConsumerWidget {
  const _StartButton({required this.series});

  final Series series;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final episodes = ref.watch(episodesProvider(series.id)).value;
    final progressMap = ref.watch(progressByEpisodeProvider).value ??
        const <String, WatchProgress>{};
    final target =
        episodes == null ? null : resumeEpisodeFor(episodes, progressMap);

    final String label;
    if (episodes == null || target == null) {
      label = 'Commencer';
    } else {
      final hasHistory = episodes.any((e) => progressMap.containsKey(e.id));
      final allCompleted =
          episodes.every((e) => progressMap[e.id]?.completed ?? false);
      if (allCompleted) {
        label = 'Revoir depuis le début';
      } else if (hasHistory) {
        label = 'Reprendre à l\'épisode ${target.episodeNumber}';
      } else {
        label = 'Commencer';
      }
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: target == null
            ? null
            : () => context.push('/watch/${target.id}'),
        icon: const Icon(Icons.play_arrow_rounded),
        label: Text(label),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TamaSpacing.s,
        vertical: TamaSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: TamaColors.surface,
        borderRadius: BorderRadius.circular(TamaRadius.card),
      ),
      child: Text(text, style: TamaText.bodyMuted),
    );
  }
}

/// Cellule numérotée d'un épisode : vu (rempli + coche), en cours (bordure
/// dorée), jamais lu (surface neutre).
class _EpisodeCell extends StatelessWidget {
  const _EpisodeCell({required this.episode, this.progress});

  final Episode episode;
  final WatchProgress? progress;

  @override
  Widget build(BuildContext context) {
    final completed = progress?.completed ?? false;
    final inProgress = !completed && (progress?.positionSeconds ?? 0) > 0;
    return GestureDetector(
      onTap: () => context.push('/watch/${episode.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: completed ? TamaColors.accentSoft : TamaColors.surface,
          borderRadius: BorderRadius.circular(TamaRadius.card),
          border:
              inProgress ? Border.all(color: TamaColors.accent) : null,
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                '${episode.episodeNumber}',
                style: TamaText.titleM.copyWith(
                  color: completed ? TamaColors.accent : TamaColors.text,
                ),
              ),
            ),
            if (completed)
              const Positioned(
                top: TamaSpacing.xs,
                right: TamaSpacing.xs,
                child: Icon(
                  Icons.check_rounded,
                  size: 12,
                  color: TamaColors.accent,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
