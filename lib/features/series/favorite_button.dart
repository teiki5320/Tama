import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../providers/favorites_providers.dart';
import '../../providers/repositories_providers.dart';
import '../settings/auth_sheet.dart';

/// Bouton favori d'une série. C'est ICI que l'auth est demandée si besoin
/// (« zéro friction » : jamais avant).
class FavoriteButton extends ConsumerWidget {
  const FavoriteButton({super.key, required this.seriesId});

  final String seriesId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // valueOrNull : `value` relance l'erreur d'un AsyncError et le bouton
    // deviendrait un rectangle gris en release. Sans favoris connus, il
    // s'affiche simplement comme « pas en favori ».
    final favoriteIds =
        ref.watch(favoriteIdsProvider).valueOrNull ?? const <String>{};
    final isFavorite = favoriteIds.contains(seriesId);
    return IconButton(
      tooltip: isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
      onPressed: () {
        if (!ref.read(favoritesRepositoryProvider).canFavorite) {
          showAuthSheet(context);
          return;
        }
        toggleFavorite(ref, seriesId);
      },
      icon: Icon(
        isFavorite ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
        color: isFavorite ? TamaColors.accent : TamaColors.text,
      ),
    );
  }
}
