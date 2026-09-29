class AssetPaths {
  AssetPaths._();

  static const String images = 'assets/images';
  static const String icons = 'assets/icons';
  static const String lottie = 'assets/lottie';
  static const String audios = 'assets/audios';

  static const String logo = '$images/logo.png';
  static const String logoWhite = '$images/logo_white.png';
  static const String placeholder = '$images/placeholder.png';

  static const String correctSound = '$audios/correct_sound.mp3';
  static const String incorrectSound = '$audios/incorrect_sound.mp3';
  static const String timerSound = '$audios/timer_tick.mp3';
  static const String endingSound = '$audios/ending_sound.mp3';
}

/// Short sound effects bundled with the app.
///
/// Every surface that plays feedback audio (quizzes, Bible games) speaks this
/// enum rather than a raw asset path, so a file can be swapped without touching
/// call sites.
enum SfxSound {
  correct(AssetPaths.correctSound),
  incorrect(AssetPaths.incorrectSound),
  timer(AssetPaths.timerSound),
  ending(AssetPaths.endingSound);

  const SfxSound(this.assetPath);

  /// Bundled asset path for this sound.
  final String assetPath;
}
