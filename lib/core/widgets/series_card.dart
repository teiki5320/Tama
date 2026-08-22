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
          : Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      _Poster(series: series, showTitle: false),
                  errorWidget: (_, __, ___) => _Poster(
                    series: series,
                    showTitle: showTitle,
                    titleStyle: titleStyle,
                  ),
                ),
                // La trame passe aussi sur les images : c'est elle qui tient
                // ensemble une vignette extraite d'une vidéo et une affiche
                // typographique voisine dans le même rail.
                const ScreenPrint(),
                if (showTitle) ...[
                  // Voile indispensable : sans lui, un titre crème posé sur
                  // une vignette claire devient illisible. Il descend assez
                  // bas pour couvrir trois lignes de titre.
                  //
                  // En haut, et non en bas comme sur l'affiche typographique :
                  // les sous-titres des épisodes sont incrustés dans l'image,
                  // en bas, exactement là où le titre se posait. Deux textes
                  // superposés, illisibles tous les deux. Le haut est libre —
                  // seul le filigrane de la source y figure, que ce voile
                  // atténue au passage.
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0, 0.22, 0.6],
                        colors: [
                          TamaColors.posterVeil,
                          TamaColors.scrim,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  _PosterTitle(
                    series: series,
                    style: titleStyle,
                    // Sur une image, la lettre est détourée : elle tient même
                    // si un aplat clair remonte sous le voile.
                    onImage: true,
                  ),
                ],
              ],
            ),
    );
  }
}

/// Le titre de la série, posé sur l'affiche.
///
/// En bas de l'affiche typographique, dont on maîtrise l'aplat ; en haut sur
/// une vignette de vidéo, dont le bas porte les sous-titres incrustés.
class _PosterTitle extends StatelessWidget {
  const _PosterTitle({
    required this.series,
    this.style,
    this.onImage = false,
  });

  final Series series;
  final TextStyle? style;

  /// Sur une image, le titre monte en haut de l'affiche et reçoit une ombre
  /// portée ; sur l'aplat typographique, il reste en bas et l'ombre serait
  /// inutile — elle salirait la lettre.
  final bool onImage;

  @override
  Widget build(BuildContext context) {
    final base = style ?? TamaText.titleM;
    return Align(
      alignment: onImage ? Alignment.topLeft : Alignment.bottomLeft,
      child: Padding(
        padding: const EdgeInsets.all(TamaSpacing.s),
        child: Text(
          series.title.toUpperCase(),
          style: onImage
              ? base.copyWith(
                  shadows: const [
                    Shadow(blurRadius: 10, color: TamaColors.background),
                    Shadow(blurRadius: 3, color: TamaColors.background),
                  ],
                )
              : base,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
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
        if (showTitle) _PosterTitle(series: series, style: titleStyle),
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
