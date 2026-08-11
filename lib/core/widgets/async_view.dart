import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme.dart';

/// Enveloppe systématique des trois états d'un écran : chargement, erreur,
/// contenu (avec cas « vide » optionnel). Règle du projet : pas d'écran blanc.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({
    super.key,
    required this.value,
    required this.builder,
    this.onRetry,
    this.isEmpty,
    this.empty,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final VoidCallback? onRetry;

  /// Prédicat « données vides » (ex. liste sans élément).
  final bool Function(T data)? isEmpty;

  /// Widget affiché quand [isEmpty] est vrai.
  final Widget? empty;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorView(onRetry: onRetry),
      data: (data) {
        if (isEmpty != null && isEmpty!(data)) {
          return empty ?? const SizedBox.shrink();
        }
        return builder(data);
      },
    );
  }
}

/// État d'erreur avec action de nouvelle tentative.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, this.message, this.onRetry});

  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TamaSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 40, color: TamaColors.textMuted),
            const SizedBox(height: TamaSpacing.m),
            Text(
              message ?? 'Une erreur est survenue.',
              style: TamaText.titleM,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: TamaSpacing.xs),
            Text(
              'Vérifie ta connexion puis réessaie.',
              style: TamaText.bodyMuted,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: TamaSpacing.l),
              OutlinedButton(onPressed: onRetry, child: const Text('Réessayer')),
            ],
          ],
        ),
      ),
    );
  }
}

/// État vide avec message et action optionnelle.
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TamaSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: TamaColors.textMuted),
            const SizedBox(height: TamaSpacing.m),
            Text(title, style: TamaText.titleM, textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: TamaSpacing.xs),
              Text(subtitle!,
                  style: TamaText.bodyMuted, textAlign: TextAlign.center),
            ],
            if (action != null) ...[
              const SizedBox(height: TamaSpacing.l),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
