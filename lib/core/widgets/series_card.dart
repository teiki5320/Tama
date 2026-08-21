import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/series.dart';
import '../theme.dart';
import 'poster.dart';

/// Visuel d'une série. Sans cover, la vignette devient une **affiche
/// typographique** : aplat dérivé de la couleur du genre, trame de
/// sérigraphie, titre en Anton. L'absence de visuel devient un parti pris,
/// et le jour où les vraies covers 9:16 arrivent elles prennent la place
/// sans rien changer d'autre.
class SeriesCover extends StatelessWidget {
  const SeriesCover({
    super.key,
    required this.series,
    this.borderRadius,
    this.showTitle = true,
    this.titleStyle,
  });

  final Series series;
  final BorderRadius? borderRadius;

  /// Affiche le titre sur l'affiche de repli (inutile si le titre est déjà
  /// écrit sous la vignette).
  final bool showTitle;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(TamaRadius.card);
    final url = series.coverUrl;
    return ClipRRect(
      borderRadius: radius,
      child: url == null || url.isEmpty
          ? _Poster(
              series: series,
              showTitle: showTitle,
              titleStyle: titleStyle,
            )
          : CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              placeholder: (_, __) => _Poster(series: series, showTitle: false),
              errorWidget: (_, __, ___) => _Poster(
                series: series,
                showTitle: showTitle,
                titleStyle: titleStyle,
              ),
            ),
    );
  }
}

class _Poster extends StatelessWidget {
  const _Poster({
    required this.series,
    required this.showTitle,
    this.titleStyle,
  });

  final Series series;
  final bool showTitle;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: TamaColors.posterGradient(series.genre, series.title),
            ),
          ),
        ),
        const ScreenPrint(),
        if (showTitle)
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(TamaSpacing.s),
              child: Text(
                series.title.toUpperCase(),
                style: titleStyle ?? TamaText.titleM,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
      ],
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
    // Le titre vit sur l'affiche, pas sous la vignette : c'est tout le
    // principe de cette direction, et ça évite de le lire deux fois.
    final card = AspectRatio(
      aspectRatio: 9 / 14,
      child: SeriesCover(series: series),
    );
    return GestureDetector(
      onTap: () => context.push('/series/${series.id}'),
      child: width == null ? card : SizedBox(width: width, child: card),
    );
  }
}
