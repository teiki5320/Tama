import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/series_card.dart';
import '../../models/series.dart';
import '../../providers/catalog_providers.dart';
import '../../providers/progress_providers.dart';
import '../series/watch_launcher.dart';

/// Accueil : bannière de la série mise en avant, rail « Reprendre »,
/// rails par genre. Pull-to-refresh.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider);
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(publishedSeriesProvider);
          ref.invalidate(progressVersionProvider);
          await ref.read(publishedSeriesProvider.future);
        },
        child: AsyncView<List<Series>>(
          value: catalog,
          onRetry: () => ref.invalidate(publishedSeriesProvider),
          isEmpty: (list) => list.isEmpty,
          empty: const EmptyView(
            icon: Icons.movie_outlined,
            title: 'Le catalogue arrive',
            subtitle: 'Les premières séries seront bientôt là. Reviens vite !',
          ),
          builder: (seriesList) {
            final rails = ref.watch(genreRailsProvider).value ??
                const <String, List<Series>>{};
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: TamaSpacing.xxl),
              children: [
                const _BrandHeader(),
                _FeaturedBanner(series: seriesList.first),
                const _ContinueRail(),
                for (final entry in rails.entries)
                  _GenreRail(genre: entry.key, series: entry.value),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// En-tête de marque, sobre : le nom et un point doré (état « en vie »).
class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TamaSpacing.l,
        TamaSpacing.m,
        TamaSpacing.l,
        TamaSpacing.l,
      ),
      child: Row(
        children: [
          const Text('Tama', style: TamaText.titleL),
          const SizedBox(width: TamaSpacing.xs),
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: TamaColors.accent,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bannière de la série mise en avant (sort_order le plus bas).
class _FeaturedBanner extends ConsumerWidget {
  const _FeaturedBanner({required this.series});

  final Series series;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TamaSpacing.l,
        0,
        TamaSpacing.l,
        TamaSpacing.xl,
      ),
      child: GestureDetector(
        onTap: () => context.push('/series/${series.id}'),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(TamaRadius.card),
          child: AspectRatio(
            aspectRatio: 3 / 4,
            child: Stack(
              fit: StackFit.expand,
              children: [
                SeriesCover(
                  series: series,
                  borderRadius: BorderRadius.zero,
                  showTitle: false,
                ),
                // Dégradé de lisibilité vers le bas de la bannière.
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.35, 0.7, 1],
                      colors: [
                        Colors.transparent,
                        TamaColors.scrim,
                        TamaColors.background,
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: TamaSpacing.l,
                  right: TamaSpacing.l,
                  bottom: TamaSpacing.l,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (series.genre != null)
                        Text(
                          series.genre!.toUpperCase(),
                          style: TamaText.label
                              .copyWith(color: TamaColors.accent),
                        ),
                      const SizedBox(height: TamaSpacing.xs),
                      Text(series.title, style: TamaText.titleXL),
                      if (series.synopsis != null) ...[
                        const SizedBox(height: TamaSpacing.s),
                        Text(
                          series.synopsis!,
                          style: TamaText.bodyMuted,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: TamaSpacing.l),
                      Row(
                        children: [
                          FilledButton.icon(
                            onPressed: () =>
                                startWatching(context, ref, series),
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text('Regarder'),
                          ),
                          const SizedBox(width: TamaSpacing.m),
                          Text(
                            '${series.totalEpisodes} épisodes',
                            style: TamaText.bodyMuted,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Rail « Reprendre » — se masque tout seul s'il n'y a rien à reprendre.
class _ContinueRail extends ConsumerWidget {
  const _ContinueRail();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries =
        ref.watch(continueWatchingProvider).value ?? const <ContinueEntry>[];
    if (entries.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader('Reprendre'),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: TamaSpacing.l),
            itemCount: entries.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: TamaSpacing.m),
            itemBuilder: (_, i) => _ContinueCard(entry: entries[i]),
          ),
        ),
        const SizedBox(height: TamaSpacing.xl),
      ],
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.entry});

  final ContinueEntry entry;

  @override
  Widget build(BuildContext context) {
    final fraction =
        entry.progress.fractionOf(entry.episode.durationSeconds);
    return GestureDetector(
      onTap: () => context.push('/watch/${entry.episode.id}'),
      child: SizedBox(
        width: 110,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 152,
              width: 110,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: SeriesCover(series: entry.series, showTitle: false),
                  ),
                  // Barre de progression posée sur le bas de la vignette.
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(TamaRadius.card),
                      ),
                      child: LinearProgressIndicator(
                        value: fraction,
                        minHeight: 3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: TamaSpacing.s),
            Text(
              'Ép. ${entry.episode.episodeNumber} · ${entry.series.title}',
              style: TamaText.bodyMuted,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Rail horizontal d'un genre.
class _GenreRail extends StatelessWidget {
  const _GenreRail({required this.genre, required this.series});

  final String genre;
  final List<Series> series;

  @override
  Widget build(BuildContext context) {
    final title = genre.isEmpty
        ? 'Autres'
        : '${genre[0].toUpperCase()}${genre.substring(1)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title),
        SizedBox(
          height: 248,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: TamaSpacing.l),
            itemCount: series.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: TamaSpacing.m),
            itemBuilder: (_, i) => SeriesCard(series: series[i], width: 110),
          ),
        ),
        const SizedBox(height: TamaSpacing.xl),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TamaSpacing.l,
        0,
        TamaSpacing.l,
        TamaSpacing.m,
      ),
      child: Text(title, style: TamaText.titleM),
    );
  }
}
