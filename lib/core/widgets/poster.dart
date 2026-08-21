import 'package:flutter/material.dart';

import '../theme.dart';

/// Trame de sérigraphie : de fines hachures diagonales posées sur les aplats.
/// La couleur d'une affiche peinte n'est jamais parfaitement plate — c'est ce
/// grain qui distingue le parti pris d'un simple dégradé.
class ScreenPrint extends StatelessWidget {
  const ScreenPrint({super.key, this.opacity = 0.055});

  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _HatchPainter(opacity),
        size: Size.infinite,
      ),
    );
  }
}

class _HatchPainter extends CustomPainter {
  const _HatchPainter(this.opacity);

  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = TamaColors.text.withValues(alpha: opacity)
      ..strokeWidth = 1;
    // Diagonales à 45° : un pas de 4 px suffit à casser l'aplat sans
    // devenir un motif visible.
    const step = 4.0;
    for (double x = -size.height; x < size.width; x += step) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_HatchPainter old) => old.opacity != opacity;
}

/// Entrée en cascade : un bloc arrive en montant légèrement, décalé selon son
/// rang. Uniquement de l'opacité et une translation — aucun coût en données,
/// et rien à recomposer côté réseau.
class Stagger extends StatefulWidget {
  const Stagger({super.key, required this.index, required this.child});

  /// Rang du bloc dans la cascade.
  final int index;
  final Widget child;

  @override
  State<Stagger> createState() => _StaggerState();
}

class _StaggerState extends State<Stagger> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _courbe;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: TamaMotion.enter);
    _courbe = CurvedAnimation(parent: _controller, curve: TamaMotion.easeOut);
    // Le décalage est plafonné : au-delà de six blocs, l'attente deviendrait
    // perceptible et desservirait la vitesse ressentie.
    final delay = TamaMotion.stagger * widget.index.clamp(0, 6);
    Future<void>.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _courbe,
      builder: (context, child) => Opacity(
        opacity: _courbe.value,
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - _courbe.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// Respiration lente d'une affiche : un très léger zoom, en boucle. Donne
/// vie à la bannière sans rien télécharger.
class Breathing extends StatefulWidget {
  const Breathing({super.key, required this.child});

  final Widget child;

  @override
  State<Breathing> createState() => _BreathingState();
}

class _BreathingState extends State<Breathing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Démarrer la boucle ici, et non dans l'initialiseur du champ : celui-ci
    // s'exécute pendant le premier build, et lancer une animation à ce
    // moment-là empêche la frame de se composer.
    _controller = AnimationController(vsync: this, duration: TamaMotion.breathe)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Transform.scale(
        scale: 1 + 0.09 * _controller.value,
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// Titre de rubrique suivi d'une barre pleine à la couleur du genre — le
/// filet d'une affiche, qui sépare les blocs sans les encadrer.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.couleur});

  final String title;

  /// Couleur de la barre. Vermillon par défaut.
  final Color? couleur;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TamaSpacing.m),
      child: Row(
        children: [
          Text(title.toUpperCase(), style: TamaText.titleL),
          const SizedBox(width: TamaSpacing.s),
          Expanded(
            child: Container(height: 3, color: couleur ?? TamaColors.accent),
          ),
        ],
      ),
    );
  }
}

/// Jauge de progression : un trait de peinture épais et plat, jamais un
/// filet arrondi.
class ProgressStroke extends StatelessWidget {
  const ProgressStroke({
    super.key,
    required this.fraction,
    required this.couleur,
    this.height = 5,
  });

  final double fraction;
  final Color couleur;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: TamaColors.scrim,
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: fraction.clamp(0.0, 1.0),
        child: ColoredBox(color: couleur),
      ),
    );
  }
}

/// Pastille de genre : un aplat de couleur légèrement de travers, comme une
/// étiquette collée à la main sur une affiche.
class GenreChip extends StatelessWidget {
  const GenreChip({super.key, required this.genre});

  final String genre;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.024,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: TamaSpacing.s,
          vertical: 3,
        ),
        color: TamaColors.forGenre(genre),
        child: Text(
          genre.toUpperCase(),
          style: TamaText.label.copyWith(color: TamaColors.background),
        ),
      ),
    );
  }
}
