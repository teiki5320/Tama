import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/layout.dart';
import '../../core/theme.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/poster.dart';
import '../../core/widgets/series_card.dart';
import '../../providers/auth_providers.dart';
import '../../providers/favorites_providers.dart';
import '../../providers/progress_providers.dart';
import '../../providers/repositories_providers.dart';
import '../settings/auth_sheet.dart';

/// « Ma liste » : grille des séries favorites + historique de visionnage.
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Observé pour reconstruire la carte de connexion à l'auth/déconnexion.
    ref.watch(currentUserProvider);
    final canFavorite = ref.watch(favoritesRepositoryProvider).canFavorite;
    final favorites = ref.watch(favoriteSeriesProvider);
    final history = ref.watch(watchHistoryProvider);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          TamaSpacing.l,
          TamaSpacing.m,
          TamaSpacing.l,
          TamaSpacing.navBar,
        ),
        children: [
          const Text('MA LISTE', style: TamaText.titleXL),
          const SizedBox(height: TamaSpacing.xl),
          if (!canFavorite) const _SignInCard(),
          const SectionHeader('Mes séries'),
          favorites.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(TamaSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => ErrorView(
              message: 'Impossible de charger tes favoris.',
              onRetry: () => ref.invalidate(favoriteIdsProvider),
            ),
            data: (list) => list.isEmpty
                ? const EmptyView(
                    icon: Icons.bookmark_outline_rounded,
                    title: 'Aucune série favorite',
                    subtitle:
                        'Ajoute une série avec l\'icône signet sur sa fiche.',
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: TamaLayout.favoriteColumns(context),
                      mainAxisSpacing: TamaSpacing.l,
                      crossAxisSpacing: TamaSpacing.m,
                      childAspectRatio: 9 / 14,
                    ),
                    itemCount: list.length,
                    itemBuilder: (_, i) => SeriesCard(series: list[i]),
                  ),
          ),
          const SizedBox(height: TamaSpacing.xl),
          const SectionHeader('Historique', couleur: TamaColors.textFaint),
          history.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(TamaSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => ErrorView(
              message: 'Impossible de charger l\'historique.',
              onRetry: () => ref.invalidate(progressVersionProvider),
            ),
            data: (entries) => entries.isEmpty
                ? const EmptyView(
                    icon: Icons.history_rounded,
                    title: 'Aucun épisode vu',
                    subtitle: 'Ton historique de visionnage apparaîtra ici.',
                  )
                // Une ligne d'historique est un texte suivi d'une commande :
                // étirée sur une tablette, l'œil perd le lien entre les deux.
                : Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: TamaLayout.readableWidth,
                      ),
                      child: Column(
                        children: [
                          for (final entry in entries)
                            _HistoryRow(entry: entry),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Invitation à se connecter (Supabase configuré mais utilisateur anonyme).
class _SignInCard extends StatelessWidget {
  const _SignInCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: TamaSpacing.xl),
      padding: const EdgeInsets.all(TamaSpacing.l),
      decoration: BoxDecoration(
        color: TamaColors.surface,
        borderRadius: BorderRadius.circular(TamaRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Garde ta liste avec toi', style: TamaText.titleM),
          const SizedBox(height: TamaSpacing.xs),
          const Text(
            'Connecte-toi pour sauvegarder tes favoris et retrouver ta '
            'progression sur tous tes appareils.',
            style: TamaText.bodyMuted,
          ),
          const SizedBox(height: TamaSpacing.m),
          FilledButton(
            onPressed: () => showAuthSheet(context),
            child: const Text('Se connecter'),
          ),
        ],
      ),
    );
  }
}

/// Ligne d'historique : vignette, série, épisode, progression.
class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry});

  final ContinueEntry entry;

  @override
  Widget build(BuildContext context) {
    final completed = entry.progress.completed;
    final fraction = entry.progress.fractionOf(entry.episode.durationSeconds);
    final couleur = TamaColors.forGenre(entry.series.genre);
    return InkWell(
      onTap: () => context.push('/watch/${entry.episode.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: TamaSpacing.s),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              height: 85,
              child: SeriesCover(series: entry.series, showTitle: false),
            ),
            const SizedBox(width: TamaSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.series.title,
                    style: TamaText.titleM,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: TamaSpacing.xs),
                  Text(
                    entry.episode.displayTitle,
                    style: TamaText.bodyMuted,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: TamaSpacing.s),
                  if (completed)
                    Text(
                      'TERMINÉ',
                      style: TamaText.label.copyWith(color: couleur),
                    )
                  else
                    SizedBox(
                      width: 120,
                      child: ProgressStroke(
                        fraction: fraction,
                        couleur: couleur,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(
              Icons.play_circle_outline_rounded,
              color: TamaColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
