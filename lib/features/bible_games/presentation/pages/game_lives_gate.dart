import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/colors.dart';
import '../../domain/entities/bible_game_localization.dart';
import '../../domain/entities/game_lives.dart';
import '../../domain/services/bible_game_session.dart';
import '../providers/bible_game_language_provider.dart';
import '../providers/game_lives_provider.dart';
import '../widgets/game_lives_widgets.dart';

/// What a game page needs to enforce the lives + cooldown rules.
///
/// Lives are **per game** (see [BibleGameKind]), so a page only ever touches its
/// own pool. The three calls a page makes:
///
/// * [noteWrongTap] — inside the wrong-answer branch. Costs a life and fires the
///   shake.
/// * [noteNewRound] — when a round is generated. Resets the perfect-round test.
/// * [noteRoundComplete] — when a round is answered correctly. A round with zero
///   mistakes refunds one life (capped at 3).
///
/// The rule that matters: a mistake counts against the round **even if the
/// player is already on their last life**, and the last life starts the cooldown
/// at once. Walking out of the game does not pause it.
mixin GameLivesGate<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  /// The game this page owns. One pool, one cooldown.
  BibleGameKind get gameKind;

  /// The play session, for the perfect-round test.
  GameSession? get livesSession;

  /// Increments on every life lost; drives [LifeLossShake].
  int get lifeLossTrigger => _lifeLossTrigger;
  int _lifeLossTrigger = 0;

  /// Increments on every life refunded; drives the green pop.
  int get lifeHealTrigger => _lifeHealTrigger;
  int _lifeHealTrigger = 0;

  /// The most recent life event, localized, or null when there is nothing to
  /// report. Cleared automatically by [_bannerTimer].
  String? get lifeBanner => _lifeBanner;
  String? _lifeBanner;
  bool _lifeBannerPositive = false;
  int _lifeBannerTrigger = 0;
  Timer? _bannerTimer;

  /// Increments whenever [lifeBanner] changes, so the banner can animate.
  int get lifeBannerTrigger => _lifeBannerTrigger;

  @override
  void dispose() {
    _bannerTimer?.cancel();
    super.dispose();
  }

  /// Lives for this game. Defaults to a full pool while the stored state is
  /// still loading — but pages must gate on [livesLoaded] before showing the
  /// game, or a locked game would flash open.
  GameLives get lives {
    final map = ref.read(gameLivesProvider).value;
    return map?[gameKind] ?? const GameLives.full();
  }

  /// Whether the stored state has been read yet.
  bool get livesLoaded => ref.read(gameLivesProvider).hasValue;

  /// Whether this game is locked right now.
  bool get isLocked => lives.isCooldownActiveAt(DateTime.now());

  /// A wrong tap: one life, the shake, and the localized message.
  ///
  /// The message differs on the last life because the consequence differs —
  /// "Life lost!" is not enough to explain why the game just closed on you.
  void noteWrongTap() {
    final wasLast = lives.lives <= 1;
    ref.read(gameLivesProvider.notifier).registerMistake(gameKind);
    if (!mounted) return;
    final strings = ref.read(bibleGameStringsProvider);
    final language = ref.read(bibleGameLanguageProvider);
    setState(() {
      _lifeLossTrigger += 1;
      _lifeBannerPositive = false;
      _lifeBanner = wasLast
          ? strings.lastLifeLost(
              GameLives.formatDuration(
                GameLives.cooldownDuration,
                language,
              ),
            )
          : strings.lifeLost;
      _lifeBannerTrigger += 1;
    });
    _autoClearBanner();
  }

  /// A round is being generated: the perfect-round test starts over.
  void noteNewRound() {
    livesSession?.beginRound();
    ref.read(gameLivesProvider.notifier).beginRound(gameKind);
  }

  /// A round finished. A clean round refunds a life.
  ///
  /// Silent when nothing happens (lives already full, or the round had a
  /// mistake) so a long streak does not spam banners.
  void noteRoundComplete() {
    final session = livesSession;
    if (session == null) return;
    if (!session.roundIsPerfect) return;
    final before = lives.lives;
    ref.read(gameLivesProvider.notifier).rewardPerfectRound(gameKind);
    final after = ref.read(gameLivesProvider).value?[gameKind];
    if (!mounted) return;
    // Only celebrate an actual refund — the no-op case must stay quiet.
    if (after == null || after.lives <= before) return;
    final strings = ref.read(bibleGameStringsProvider);
    setState(() {
      _lifeHealTrigger += 1;
      _lifeBannerPositive = true;
      _lifeBanner = strings.perfectRound;
      _lifeBannerTrigger += 1;
    });
    _autoClearBanner();
  }

  void _autoClearBanner() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      setState(() => _lifeBanner = null);
    });
  }

  /// The hearts + the transient message, ready to drop into a page's header.
  ///
  /// [strings] is passed in rather than read so the caller controls the watch;
  /// reading it here would not subscribe this widget to language changes.
  Widget buildLivesHeader(BibleGameStrings strings) {
    final current = lives;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GameLivesRow(
              lives: current.lives,
              pulseHeal: _lifeHealTrigger,
              pulseLoss: _lifeLossTrigger,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                current.lives == GameLives.maxLives
                    ? strings.livesFull
                    : strings.livesRemaining(
                        current.lives,
                        GameLives.maxLives,
                      ),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: current.lives <= 1
                      ? AppColors.error
                      : (isDark
                          ? const Color(0xFF94A3B8)
                          : AppColors.textMuted),
                ),
              ),
            ),
          ],
        ),
        if (_lifeBanner != null)
          LifeToastBanner(
            message: _lifeBanner!,
            isPositive: _lifeBannerPositive,
            trigger: _lifeBannerTrigger,
          ),
      ],
    );
  }
}
