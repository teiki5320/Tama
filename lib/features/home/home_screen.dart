import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/layout.dart';
import '../../core/theme.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/poster.dart';
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
        color: TamaColors.accent,
        backgroundColor: TamaColors.surface,
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
            // valueOrNull, et non value : sur un AsyncError, `value` relance
            // l'exception et le bloc devient un rectangle gris en release.
            final rails = ref.watch(genreRailsProvider).valueOrNull ??
                const <String, List<Series>>{};
            var rank = 0;
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: TamaSpacing.navBar),
              children: [
                Stagger(index: rank++, child: const _BrandHeader()),
                Stagger(
                  index: rank++,
                  child: _FeaturedBanner(series: seriesList.first),
                ),
                Stagger(index: rank++, child: const _ContinueRail()),
                for (final entry in rails.entries)
                  Stagger(
                    index: rank++,
                    child: _GenreRail(genre: entry.key, series: entry.value),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// En-tête de marque : le nom en enseigne et le point vermillon.
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('TAMA', style: TamaText.titleL.copyWith(fontSize: 26)),
          const SizedBox(width: TamaSpacing.xs),
          Container(
            width: 8,
            height: 8,
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

/// Bannière de la série mise en avant : une affiche pleine, qui respire.
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
      child: Semantics(
        button: true,
        label: 'À la une : ${series.title}',
        child: GestureDetector(
          onTap: () => context.push('/series/${series.id}'),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(TamaRadius.card),
            child: SizedBox(
              height: TamaLayout.bannerHeight(context),
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Le zoom lent est appliqué sous les voiles : le texte, lui,
                  // ne bouge pas.
                  Breathing(
                    child: SeriesCover(
                      series: series,
                      borderRadius: BorderRadius.zero,
                      showTitle: false,
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.3, 0.72, 1],
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
                    // Sur grand écran, le bloc de titre ne s'étire pas sur
                    // toute la largeur : il resterait illisible.
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: TamaLayout.readableWidth,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (series.genre != null)
                              GenreChip(genre: series.genre!),
                            const SizedBox(height: TamaSpacing.m),
                            Text(
                              series.title.toUpperCase(),
                              style: TamaText.poster.copyWith(
                                fontSize: TamaLayout.posterFontSize(context),
                              ),
                              maxLines: 3,
                            ),
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
                                  style: FilledButton.styleFrom(
                                    backgroundColor:
                                        TamaColors.forGenre(series.genre),
                                  ),
                                  onPressed: () =>
                                      startWatching(context, ref, series),
                                  icon: const Icon(Icons.play_arrow_rounded),
                                  label: const Text('REGARDER'),
                                ),
                                const SizedBox(width: TamaSpacing.m),
                                Text(
                                  '${series.totalEpisodes} ÉPISODES',
                                  style: TamaText.label,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
    // valueOrNull : si la progression ne peut pas être résolue, le rail
    // s'efface au lieu de faire tomber tout l'accueil.
    final entries = ref.watch(continueWatchingProvider).valueOrNull ??
        const <ContinueEntry>[];
    if (entries.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: TamaSpacing.l),
          child: SectionHeader('Reprendre'),
        ),
        SizedBox(
          height: TamaLayout.railHeight(context),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: TamaSpacing.l),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(width: TamaSpacing.s),
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
    final fraction = entry.progress.fractionOf(entry.episode.durationSeconds);
    final couleur = TamaColors.forGenre(entry.series.genre);
    return Semantics(
      button: true,
      label: 'Reprendre ${entry.series.title}, '
          'épisode ${entry.episode.episodeNumber}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => context.push('/watch/${entry.episode.id}'),
        child: SizedBox(
          width: TamaLayout.posterWidth(context),
          child: Stack(
            children: [
              Positioned.fill(child: SeriesCover(series: entry.series)),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: ProgressStroke(fraction: fraction, couleur: couleur),
              ),
            ],
          ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: TamaSpacing.l),
          child: SectionHeader(genre, couleur: TamaColors.forGenre(genre)),
        ),
        SizedBox(
          height: TamaLayout.railHeight(context),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: TamaSpacing.l),
            itemCount: series.length,
            separatorBuilder: (_, __) => const SizedBox(width: TamaSpacing.s),
            itemBuilder: (_, i) => SeriesCard(
              series: series[i],
              width: TamaLayout.posterWidth(context),
            ),
          ),
        ),
        const SizedBox(height: TamaSpacing.xl),
      ],
    );
  }
}
