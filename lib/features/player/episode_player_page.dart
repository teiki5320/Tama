import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/episode.dart';
import '../../models/series.dart';
import '../../models/watch_progress.dart';
import '../../providers/progress_providers.dart';
import '../../providers/repositories_providers.dart';
import '../../providers/settings_providers.dart';
import '../../repositories/progress_repository.dart';
import '../../services/analytics_service.dart';
import '../series/favorite_button.dart';

/// Rôle d'une page du player.
enum PageRole {
  /// Page visible : en lecture.
  active,

  /// LE SEUL épisode suivant : initialisé en pause (préchargement).
  preload,

  /// Aucune ressource allouée.
  idle,
}

/// Une page du player : vidéo bord à bord, overlay auto-masqué, barre de
/// progression scrubbable, analytics et sauvegarde de progression.
///
/// Gestes : tap = lecture/pause · double tap = +10 s · swipe vertical géré
/// par le PageView parent.
class EpisodePlayerPage extends ConsumerStatefulWidget {
  const EpisodePlayerPage({
    super.key,
    required this.series,
    required this.episode,
    required this.role,
    required this.isLast,
    required this.onCompleted,
    required this.onReplaySeries,
  });

  final Series series;
  final Episode episode;
  final PageRole role;
  final bool isLast;

  /// Appelé à la fin de l'épisode (enchaînement automatique).
  final VoidCallback onCompleted;

  /// Depuis la carte de fin : revoir la série depuis le début.
  final VoidCallback onReplaySeries;

  @override
  ConsumerState<EpisodePlayerPage> createState() => _EpisodePlayerPageState();
}

class _EpisodePlayerPageState extends ConsumerState<EpisodePlayerPage> {
  VideoPlayerController? _controller;
  bool _initFailed = false;

  /// `episode_start` envoyé pour la session de lecture en cours.
  bool _started = false;

  /// `episode_complete` envoyé (fin réellement atteinte).
  bool _completed = false;

  final Set<int> _milestonesSent = {};
  Timer? _saveTimer;
  int _lastSavedSecond = -1;

  bool _overlayVisible = true;
  Timer? _overlayTimer;

  /// Carte de fin de série (dernier épisode terminé).
  bool _showEndCard = false;

  // Capturés en initState : utilisables sans `ref` jusque dans dispose().
  late final AnalyticsService _analytics;
  late final ProgressRepository _progressRepo;
  late final StateController<int> _progressVersion;

  @override
  void initState() {
    super.initState();
    _analytics = ref.read(analyticsServiceProvider);
    _progressRepo = ref.read(progressRepositoryProvider);
    _progressVersion = ref.read(progressVersionProvider.notifier);
    if (widget.role != PageRole.idle) {
      _initController();
    }
  }

  @override
  void didUpdateWidget(covariant EpisodePlayerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.role == widget.role) return;
    // On quitte cette page : clôture de la session de lecture.
    if (oldWidget.role == PageRole.active) {
      _endSession();
    }
    switch (widget.role) {
      case PageRole.active:
        if (_controller == null) {
          _initController();
        } else {
          _activate();
        }
      case PageRole.preload:
        if (_controller == null) {
          _initController();
        } else {
          _controller!.pause();
        }
      case PageRole.idle:
        // Page éloignée : on libère la vidéo (contrainte data et mémoire).
        _disposeController();
    }
  }

  @override
  void dispose() {
    if (widget.role == PageRole.active) {
      _endSession();
    }
    _overlayTimer?.cancel();
    _disposeController();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Cycle de vie vidéo
  // ---------------------------------------------------------------------

  Future<void> _initController() async {
    if (_controller != null) return;
    final settings = ref.read(settingsProvider);
    final url = ref.read(bunnyServiceProvider).playbackUrl(
          widget.episode,
          quality: settings.quality,
          dataSaver: settings.dataSaver,
        );
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    _controller = controller;
    controller.addListener(_onTick);
    try {
      // Sur le web, l'autoplay n'est autorisé que muet (politique navigateur).
      // La cible produit est mobile : le son y reste actif.
      if (kIsWeb) await controller.setVolume(0);
      await controller.initialize();
      if (!mounted || _controller != controller) return;
      setState(() => _initFailed = false);
      if (widget.role == PageRole.active) {
        await _activate();
      }
    } catch (_) {
      if (mounted && _controller == controller) {
        setState(() => _initFailed = true);
      }
    }
  }

  /// La page devient visible : reprise éventuelle, lecture, analytics.
  Future<void> _activate() async {
    _showOverlayBriefly();
    setState(() => _showEndCard = false);
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    // Reprise : on repart de la position sauvegardée si elle est utile.
    final saved = await _progressRepo.forEpisode(widget.episode.id);
    if (!mounted || _controller != controller) return;
    if (saved != null &&
        !saved.completed &&
        saved.positionSeconds > 2 &&
        saved.positionSeconds < widget.episode.durationSeconds - 5) {
      await controller.seekTo(Duration(seconds: saved.positionSeconds));
    }
    await controller.play();
    _sendStartEvents();
    _startSaveTimer();
  }

  void _sendStartEvents() {
    if (_started) return;
    _started = true;
    _analytics.trackSeriesStartIfFirst(widget.series.id);
    _analytics.track(
      'episode_start',
      episodeId: widget.episode.id,
      seriesId: widget.series.id,
      payload: {
        'series_id': widget.series.id,
        'episode_number': widget.episode.episodeNumber,
      },
    );
  }

  /// Ticker vidéo : paliers de progression et détection de fin.
  void _onTick() {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        widget.role != PageRole.active) {
      return;
    }
    final duration = controller.value.duration;
    if (duration <= Duration.zero) return;
    final position = controller.value.position;
    final percent = (position.inMilliseconds / duration.inMilliseconds * 100)
        .clamp(0, 100)
        .round();

    for (final milestone in TamaConstants.progressMilestones) {
      if (percent >= milestone && _milestonesSent.add(milestone)) {
        _analytics.track(
          'episode_progress',
          episodeId: widget.episode.id,
          seriesId: widget.series.id,
          payload: {'percent': milestone},
        );
      }
    }

    if (!_completed &&
        position >= duration - TamaConstants.completionEpsilon) {
      _completed = true;
      _analytics.track(
        'episode_complete',
        episodeId: widget.episode.id,
        seriesId: widget.series.id,
      );
      _saveProgress(completed: true);
      if (widget.isLast) {
        setState(() => _showEndCard = true);
      } else {
        widget.onCompleted();
      }
    }
  }

  /// Clôture de la session de lecture : pause, dropoff si sortie avant la
  /// fin, sauvegarde. Appelé au swipe vers une autre page et à la sortie.
  void _endSession() {
    _saveTimer?.cancel();
    final controller = _controller;
    if (controller != null && controller.value.isInitialized) {
      controller.pause();
      if (_started && !_completed) {
        final durationMs = controller.value.duration.inMilliseconds;
        final percent = durationMs <= 0
            ? 0
            : (controller.value.position.inMilliseconds / durationMs * 100)
                .clamp(0, 100)
                .round();
        _analytics.track(
          'episode_dropoff',
          episodeId: widget.episode.id,
          seriesId: widget.series.id,
          payload: {
            'second': controller.value.position.inSeconds,
            'percent': percent,
          },
        );
        _saveProgress(completed: false);
      }
    }
    // Réarmé pour une éventuelle nouvelle session sur la même page.
    _started = false;
    _milestonesSent.clear();
  }

  void _disposeController() {
    _saveTimer?.cancel();
    final controller = _controller;
    _controller = null;
    controller?.removeListener(_onTick);
    controller?.dispose();
  }

  // ---------------------------------------------------------------------
  // Sauvegarde de progression
  // ---------------------------------------------------------------------

  /// Sauvegarde périodique (toutes les 5 s, uniquement si la position bouge).
  void _startSaveTimer() {
    _saveTimer?.cancel();
    _saveTimer = Timer.periodic(TamaConstants.progressSaveInterval, (_) {
      final controller = _controller;
      if (controller == null ||
          !controller.value.isInitialized ||
          !controller.value.isPlaying) {
        return;
      }
      final second = controller.value.position.inSeconds;
      if (second == _lastSavedSecond) return;
      _lastSavedSecond = second;
      _saveProgress(completed: _completed);
    });
  }

  void _saveProgress({required bool completed}) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    _progressRepo.save(
      WatchProgress(
        episodeId: widget.episode.id,
        positionSeconds: completed
            ? widget.episode.durationSeconds
            : controller.value.position.inSeconds,
        completed: completed,
        updatedAt: DateTime.now(),
      ),
    );
    _progressVersion.state++;
  }

  // ---------------------------------------------------------------------
  // Gestes et overlay
  // ---------------------------------------------------------------------

  void _togglePlayPause() {
    _showOverlayBriefly();
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isPlaying) {
      controller.pause();
    } else {
      controller.play();
    }
  }

  /// Double tap : avance de 10 s.
  void _seekForward() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final target = controller.value.position + TamaConstants.doubleTapSeek;
    controller.seekTo(
      target < controller.value.duration
          ? target
          : controller.value.duration - TamaConstants.completionEpsilon,
    );
    _showOverlayBriefly();
  }

  /// Affiche l'overlay puis le masque automatiquement après 2 s.
  void _showOverlayBriefly() {
    _overlayTimer?.cancel();
    if (!_overlayVisible) setState(() => _overlayVisible = true);
    _overlayTimer = Timer(TamaConstants.overlayHideDelay, () {
      if (mounted) setState(() => _overlayVisible = false);
    });
  }

  void _retry() {
    _disposeController();
    setState(() => _initFailed = false);
    _initController();
  }

  // ---------------------------------------------------------------------
  // Construction
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final videoReady = controller != null && controller.value.isInitialized;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _togglePlayPause,
      onDoubleTap: _seekForward,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Vidéo bord à bord — remplissage total, jamais de bande noire.
          if (videoReady)
            _CoverVideo(controller: controller)
          else
            _EpisodePlaceholder(
              series: widget.series,
              episode: widget.episode,
              failed: _initFailed,
              onRetry: _retry,
            ),

          // 2. Voiles haut/bas pour la lisibilité de l'overlay.
          const _EdgeScrims(),

          // 3. Icône pause (état arrêté), reconstruite au fil du contrôleur.
          if (videoReady && !_showEndCard)
            ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: controller,
              builder: (_, value, __) => value.isPlaying
                  ? const SizedBox.shrink()
                  : const Center(
                      child: Icon(
                        Icons.play_arrow_rounded,
                        size: 72,
                        color: TamaColors.text,
                      ),
                    ),
            ),

          // 4. Overlay minimal auto-masqué (jamais cliquable quand masqué).
          _PlayerOverlay(
            visible: _overlayVisible || !videoReady,
            series: widget.series,
            episode: widget.episode,
          ),

          // 5. Barre de progression fine, scrubbable.
          if (videoReady)
            Align(
              alignment: Alignment.bottomCenter,
              child: _ScrubBar(controller: controller),
            ),

          // 6. Carte de fin de série (dernier épisode).
          if (_showEndCard)
            _EndCard(
              series: widget.series,
              onReplay: widget.onReplaySeries,
            ),
        ],
      ),
    );
  }
}

/// Vidéo en remplissage total (BoxFit.cover) : cadrée, jamais letterboxée.
class _CoverVideo extends StatelessWidget {
  const _CoverVideo({required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    final size = controller.value.size;
    final width = size.width <= 0 ? 9.0 : size.width;
    final height = size.height <= 0 ? 16.0 : size.height;
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: width,
          height: height,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }
}

/// États non-vidéo de la page : chargement ou erreur, sur un fond dégradé
/// cohérent avec l'identité de la série. Pas d'écran noir brut.
class _EpisodePlaceholder extends StatelessWidget {
  const _EpisodePlaceholder({
    required this.series,
    required this.episode,
    required this.failed,
    required this.onRetry,
  });

  final Series series;
  final Episode episode;
  final bool failed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = TamaColors.coverPalette[
        series.title.hashCode.abs() % TamaColors.coverPalette.length];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: palette,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(TamaSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                series.title,
                style: TamaText.titleL,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: TamaSpacing.xs),
              Text(episode.displayTitle, style: TamaText.bodyMuted),
              const SizedBox(height: TamaSpacing.xl),
              if (failed) ...[
                const Text(
                  'Impossible de lire la vidéo.',
                  style: TamaText.body,
                ),
                const SizedBox(height: TamaSpacing.m),
                OutlinedButton(
                  onPressed: onRetry,
                  child: const Text('Réessayer'),
                ),
              ] else
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Voiles discrets en haut et en bas de l'écran (lisibilité de l'overlay).
class _EdgeScrims extends StatelessWidget {
  const _EdgeScrims();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0, 0.18, 0.8, 1],
            colors: [
              TamaColors.scrim,
              Colors.transparent,
              Colors.transparent,
              TamaColors.scrim,
            ],
          ),
        ),
      ),
    );
  }
}

/// Overlay minimal : retour, titre de la série, numéro d'épisode, favori,
/// partage. Auto-masqué après 2 s — et alors réellement inerte
/// (IgnorePointer) : jamais d'objet invisible mais cliquable.
class _PlayerOverlay extends ConsumerWidget {
  const _PlayerOverlay({
    required this.visible,
    required this.series,
    required this.episode,
  });

  final bool visible;
  final Series series;
  final Episode episode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: TamaSpacing.s),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  tooltip: 'Retour',
                  onPressed: () => context.pop(),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: TamaColors.text,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: TamaSpacing.s),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          series.title,
                          style: TamaText.titleM,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Épisode ${episode.episodeNumber}',
                          style: TamaText.bodyMuted,
                        ),
                      ],
                    ),
                  ),
                ),
                FavoriteButton(seriesId: series.id),
                IconButton(
                  tooltip: 'Partager',
                  onPressed: () => Share.share(
                    '${series.title} — Épisode ${episode.episodeNumber}, '
                    'à voir sur ${TamaConstants.appName}.',
                  ),
                  icon: const Icon(
                    Icons.share_rounded,
                    color: TamaColors.text,
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

/// Barre de progression fine en bas de l'écran, scrubbable au doigt.
class _ScrubBar extends StatefulWidget {
  const _ScrubBar({required this.controller});

  final VideoPlayerController controller;

  @override
  State<_ScrubBar> createState() => _ScrubBarState();
}

class _ScrubBarState extends State<_ScrubBar> {
  /// Fraction en cours de drag (null hors interaction).
  double? _dragFraction;

  void _seekToFraction(double fraction) {
    final duration = widget.controller.value.duration;
    widget.controller.seekTo(duration * fraction.clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        double fractionFromDx(double dx) => (dx / width).clamp(0.0, 1.0);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => _seekToFraction(fractionFromDx(d.localPosition.dx)),
          onHorizontalDragStart: (d) => setState(
            () => _dragFraction = fractionFromDx(d.localPosition.dx),
          ),
          onHorizontalDragUpdate: (d) => setState(
            () => _dragFraction = fractionFromDx(d.localPosition.dx),
          ),
          onHorizontalDragEnd: (_) {
            if (_dragFraction != null) _seekToFraction(_dragFraction!);
            setState(() => _dragFraction = null);
          },
          // Zone de toucher confortable pour une barre visuellement fine.
          child: SizedBox(
            height: 32 + bottomInset,
            child: Padding(
              padding: EdgeInsets.only(
                left: TamaSpacing.l,
                right: TamaSpacing.l,
                bottom: bottomInset + TamaSpacing.m,
              ),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ValueListenableBuilder<VideoPlayerValue>(
                  valueListenable: widget.controller,
                  builder: (_, value, __) {
                    final durationMs = value.duration.inMilliseconds;
                    final fraction = _dragFraction ??
                        (durationMs <= 0
                            ? 0.0
                            : (value.position.inMilliseconds / durationMs)
                                .clamp(0.0, 1.0));
                    return Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        // Piste.
                        Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: TamaColors.track,
                            borderRadius:
                                BorderRadius.circular(TamaRadius.card),
                          ),
                        ),
                        // Progression.
                        FractionallySizedBox(
                          widthFactor: fraction,
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              color: TamaColors.accent,
                              borderRadius:
                                  BorderRadius.circular(TamaRadius.card),
                            ),
                          ),
                        ),
                        // Poignée visible pendant le drag.
                        if (_dragFraction != null)
                          Align(
                            alignment: Alignment(
                              fraction * 2 - 1,
                              0,
                            ),
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: TamaColors.accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Carte de fin de série : affichée uniquement après le dernier épisode.
class _EndCard extends StatelessWidget {
  const _EndCard({required this.series, required this.onReplay});

  final Series series;
  final VoidCallback onReplay;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: TamaColors.scrim,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(TamaSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                series.isCompleted
                    ? 'C\'est déjà la fin.'
                    : 'À suivre…',
                style: TamaText.titleXL,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: TamaSpacing.s),
              Text(
                series.isCompleted
                    ? 'Tu as terminé « ${series.title} ».'
                    : 'Tu es à jour sur « ${series.title} ». '
                        'La suite arrive bientôt.',
                style: TamaText.bodyMuted,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: TamaSpacing.xl),
              FilledButton(
                onPressed: () => context.pop(),
                child: const Text('Retour à la fiche'),
              ),
              const SizedBox(height: TamaSpacing.s),
              OutlinedButton(
                onPressed: onReplay,
                child: const Text('Revoir depuis le début'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
