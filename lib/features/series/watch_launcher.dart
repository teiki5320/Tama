import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/series.dart';
import '../../providers/catalog_providers.dart';
import '../../providers/progress_providers.dart';

/// Ouvre le player sur le bon épisode d'une série : reprise de l'épisode en
/// cours s'il existe, sinon premier épisode jamais terminé, sinon le premier.
Future<void> startWatching(
  BuildContext context,
  WidgetRef ref,
  Series series,
) async {
  final episodes = await ref.read(episodesProvider(series.id).future);
  final progresses = await ref.read(progressListProvider.future);
  final target = resumeEpisodeFor(
    episodes,
    {for (final p in progresses) p.episodeId: p},
  );
  if (target == null || !context.mounted) return;
  context.push('/watch/${target.id}');
}
