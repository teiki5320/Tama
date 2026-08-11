import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/series.dart';
import '../theme.dart';

/// Visuel d'une série : cover réseau si disponible, sinon dégradé de repli
/// généré depuis le titre (stable d'un lancement à l'autre).
class SeriesCover extends StatelessWidget {
  const SeriesCover({
    super.key,
    required this.series,
    this.borderRadius,
    this.showTitle = true,
  });

  final Series series;
  final BorderRadius? borderRadius;

  /// Affiche le titre sur le dégradé de repli (inutile si le titre est
  /// déjà écrit sous la vignette).
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final radius =
        borderRadius ?? BorderRadius.circular(TamaRadius.card);
    final url = series.coverUrl;
    return ClipRRect(
      borderRadius: radius,
      child: url == null || url.isEmpty
          ? _FallbackCover(series: series, showTitle: showTitle)
          : CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              placeholder: (_, __) =>
                  _FallbackCover(series: series, showTitle: false),
              errorWidget: (_, __, ___) =>
                  _FallbackCover(series: series, showTitle: showTitle),
            ),
    );
  }
}

class _FallbackCover extends StatelessWidget {
  const _FallbackCover({required this.series, required this.showTitle});

  final Series series;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final palette = TamaColors.coverPalette[
        series.title.hashCode.abs() % TamaColors.coverPalette.length];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette,
        ),
      ),
      child: showTitle
          ? Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.all(TamaSpacing.m),
                child: Text(
                  series.title,
                  style: TamaText.titleM,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
          : null,
    );
  }
}

/// Vignette portrait 9:16 d'une série, pour les rails et les grilles.
class SeriesCard extends StatelessWidget {
  const SeriesCard({super.key, required this.series, this.width});

  final Series series;

  /// Largeur fixe pour les rails horizontaux (null dans une grille).
  final double? width;

  @override
  Widget build(BuildContext context) {
    final card = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: 9 / 16,
          child: SeriesCover(series: series, showTitle: false),
        ),
        const SizedBox(height: TamaSpacing.s),
        Text(
          series.title,
          style: TamaText.bodyMuted,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
    return GestureDetector(
      onTap: () => context.push('/series/${series.id}'),
      child: width == null ? card : SizedBox(width: width, child: card),
    );
  }
}
