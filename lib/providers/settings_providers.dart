import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import 'repositories_providers.dart';

/// Réglages utilisateur, persistés localement.
class AppSettings {
  const AppSettings({
    required this.dataSaver,
    required this.quality,
    required this.language,
  });

  /// Mode données réduites : force la qualité minimale et coupe le
  /// préchargement de l'épisode suivant.
  final bool dataSaver;
  final VideoQuality quality;

  /// Langue de contenu préférée (le catalogue retombe sur tout le contenu
  /// si aucune série n'existe dans cette langue).
  final ContentLanguage language;

  AppSettings copyWith({
    bool? dataSaver,
    VideoQuality? quality,
    ContentLanguage? language,
  }) =>
      AppSettings(
        dataSaver: dataSaver ?? this.dataSaver,
        quality: quality ?? this.quality,
        language: language ?? this.language,
      );
}

class SettingsNotifier extends Notifier<AppSettings> {
  static const _dataSaverKey = 'settings_data_saver';
  static const _qualityKey = 'settings_quality';
  static const _languageKey = 'settings_language';

  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return AppSettings(
      dataSaver: prefs.getBool(_dataSaverKey) ?? false,
      quality: VideoQuality.values.asNameMap()[prefs.getString(_qualityKey)] ??
          VideoQuality.auto,
      language:
          ContentLanguage.values.asNameMap()[prefs.getString(_languageKey)] ??
              ContentLanguage.fr,
    );
  }

  Future<void> setDataSaver(bool value) async {
    state = state.copyWith(dataSaver: value);
    await ref.read(sharedPreferencesProvider).setBool(_dataSaverKey, value);
  }

  Future<void> setQuality(VideoQuality value) async {
    state = state.copyWith(quality: value);
    await ref
        .read(sharedPreferencesProvider)
        .setString(_qualityKey, value.name);
  }

  Future<void> setLanguage(ContentLanguage value) async {
    state = state.copyWith(language: value);
    await ref
        .read(sharedPreferencesProvider)
        .setString(_languageKey, value.name);
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);
