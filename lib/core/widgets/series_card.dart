import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/series.dart';
import '../../providers/repositories_providers.dart';
import '../theme.dart';
import 'poster.dart';

/// Visuel d'une série, en trois temps :
///
/// 1. l'affiche déposée, si le catalogue en porte une ;
/// 2. sinon la vignette du premier épisode — Bunny en génère une par vidéo,
///    au format de la vidéo, donc verticale et directement utilisable ;
/// 3. sinon une **affiche typographique** : aplat dérivé de la couleur du
///    genre, trame de sérigraphie, titre en Anton.
///
/// Le troisième cas n'est pas un trou : c'est un repli assumé, qui tient
/// debout tant qu'une série n'a ni affiche ni vidéo en ligne.
class SeriesCover extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final radius = borderRadius ?? BorderRadius.circular(TamaRadius.card);
    // Affiche déposée si elle existe, sinon la vignette de la première vidéo.
    final url = ref.read(bunnyServiceProvider).seriesCoverUrl(series);
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
