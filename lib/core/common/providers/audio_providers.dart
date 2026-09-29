import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/settings/presentation/providers/settings_provider.dart';
import '../../services/audio_service.dart';

/// The app-wide sound effect player.
///
/// Created once and kept alive for the whole session, so the decoded assets and
/// the current volume survive navigation. Settings are pushed into it eagerly:
/// the service starts at "on, full volume" and is corrected the moment the
/// stored [UserSettings] arrive, which matters because quiz audio can fire
/// before the settings page has ever been opened.
final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();

  // Apply whatever is already known synchronously (e.g. Settings was read by an
  // earlier page in the same frame).
  final initial = ref.read(settingsProvider).valueOrNull;
  if (initial != null) {
    service
      ..setEnabled(initial.audioEnabled)
      ..setVolume(initial.soundVolume);
  }

  // ...and keep following it, including the async loading -> data transition.
  ref.listen(settingsProvider, (previous, next) {
    final settings = next.valueOrNull;
    if (settings == null) return;
    service
      ..setEnabled(settings.audioEnabled)
      ..setVolume(settings.soundVolume);
  });

  if (initial?.audioEnabled ?? true) {
    service.preload();
  }

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});
