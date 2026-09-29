import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/common/widgets/app_empty_state.dart';
import '../../../../core/common/widgets/app_loading.dart';
import '../../../../core/common/widgets/app_scaffold.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../domain/entities/bible_game_entities.dart';
import '../../domain/entities/bible_game_localization.dart';
import '../../domain/entities/game_lives.dart';
import '../../domain/services/bible_game_engine.dart';
import '../../domain/services/bible_game_session.dart';
import '../providers/bible_game_language_provider.dart';
import '../providers/bible_games_provider.dart';
import '../providers/game_lives_provider.dart';
import '../widgets/bible_game_language_toggle.dart';
import '../widgets/bible_game_widgets.dart';
import '../widgets/game_cooldown_overlay.dart';
import '../widgets/game_lives_widgets.dart';
import 'bible_game_language_sync.dart';
import 'game_lives_gate.dart';

/// Higher / Lower — endless streak round: tap the book with MORE chapters.
/// Each open starts a fresh random session so the pairs are never predictable.
///
/// Renders in the device language by default, overridable with the `EN | NP`
/// toggle in the `AppBar` (see `bibleGameLanguageProvider`): the book names, the
/// chapter counts and every line of copy all come from the inline localization
/// data. Identity comparisons still use the DB book names, so a Nepali round
/// scores exactly like an English one.
class HigherLowerPage extends ConsumerStatefulWidget {
  const HigherLowerPage({super.key});

  @override
  ConsumerState<HigherLowerPage> createState() => _HigherLowerPageState();
}

class _HigherLowerPageState extends ConsumerState<HigherLowerPage>
    with BibleGameLanguageSync<HigherLowerPage>, GameLivesGate<HigherLowerPage> {
  static const int pointsPerRound = 10;

  late BibleGameEngine _engine;
  GameSession? _session;

  List<BibleGameBook> _books = const [];
  HigherLowerRound? _round;
  String? _selected;
  bool _loading = true;
  bool _answered = false;
  bool _unavailable = false;

  /// The language the current pair was built with, so the sync mixin can tell a
  /// real switch apart from a rebuild.
  BibleGameLanguage _roundLanguage = BibleGameLanguage.english;

  @override
  BibleGameLanguage get roundLanguage => _roundLanguage;

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  Future<void> _startGame() async {
    final session = GameSession();
    setState(() {
      _session = session;
      _engine = BibleGameEngine(random: session.random);
      _books = const [];
      _round = null;
      _selected = null;
      _answered = false;
      _loading = true;
      _unavailable = false;
    });
    final data = await ref.read(localizedBibleGamesDataProvider.future);
    if (!mounted) return;
    if (data.isEmpty) {
      setState(() {
        _loading = false;
        _unavailable = true;
      });
      return;
    }
    setState(() => _books = data.books);
    _roundLanguage = ref.read(bibleGameLanguageProvider);
    _nextRound();
  }

  void _nextRound() {
    setState(() {
      _answered = false;
      _selected = null;
      _round = _engine.higherLowerRound(
        _books,
        language: ref.read(bibleGameLanguageProvider),
      );
      _roundLanguage = ref.read(bibleGameLanguageProvider);
      _loading = false;
    });
    noteNewRound();
  }

  @override
  Future<void> applyBibleGameLanguage(BibleGameLanguage language) async {
    final books = await localizedBooks();
    if (!mounted) return;
    setState(() {
      _books = books;
      _roundLanguage = language;
      _answered = false;
      _selected = null;
      _round = _engine.higherLowerRound(books, language: language);
    });
  }

  @override
  BibleGameKind get gameKind => BibleGameKind.higherLower;

  @override
  GameSession? get livesSession => _session;

  void _select(BibleGameBook tapped) {
    final round = _round;
    final session = _session;
    if (_answered || _selected != null || round == null || session == null) {
      return;
    }
    if (isLocked) return;
    final isCorrect = tapped.name == round.higher.name;
    setState(() {
      _selected = tapped.name;
      _answered = true;
      session.registerResult(correct: isCorrect, points: pointsPerRound);
    });
    if (isCorrect) {
      noteRoundComplete();
    } else {
      noteWrongTap();
    }
  }

  GameOptionState _tileState(String bookName) {
    final round = _round;
    if (round == null || !_answered) return GameOptionState.idle;
    if (bookName == round.higher.name) return GameOptionState.correct;
    if (bookName == _selected) return GameOptionState.wrong;
    return GameOptionState.idle;
  }

  @override
  Widget build(BuildContext context) {
    final round = _round;
    final session = _session;
    final strings = ref.watch(bibleGameStringsProvider);
    final language = ref.watch(bibleGameLanguageProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Subscribe to lives so a life lost in the overlay or the hub lands here.
    final livesState = ref.watch(gameLivesProvider);
    watchBibleGameLanguage();

    if (_unavailable) {
      return AppScaffold(
        body: AppEmptyState(
          icon: Icons.menu_book_outlined,
          title: strings.dataUnavailableTitle,
          subtitle: strings.dataUnavailableBody,
        ),
      );
    }

    // Cooldown outranks everything: a locked game never shows a playable board.
    if (livesState.hasValue && isLocked) {
      return AppScaffold(
        appBar: _buildAppBar(strings, language),
        body: GameCooldownOverlay(
          kind: gameKind,
          title: strings.higherLowerTitle,
        ),
      );
    }

    return AppScaffold(
      appBar: _buildAppBar(strings, language),
      body: _loading || round == null || session == null || !livesLoaded
          ? Center(child: AppLoading(message: strings.higherLowerLoading))
          : LifeLossShake(
              trigger: lifeLossTrigger,
              child: ListView(
              padding: const EdgeInsets.all(AppDimensions.paddingLg),
              children: [
                GameScoreHeader(
                  score: session.score,
                  streak: session.streak,
                  optional: strings.neverEnding,
                ),
                const SizedBox(height: 10),
                buildLivesHeader(strings),
                GameRoundCard(
                  title: strings.higherLowerQuestion,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _BookTapTile(
                        label: round.left.label,
                        chapterLabel: _answered
                            ? strings.chaptersSuffix(round.left.chapterCount)
                            : null,
                        state: _tileState(round.left.name),
                        onTap: () => _select(round.left),
                      ),
                      const SizedBox(height: 12),
                      _BookTapTile(
                        label: round.right.label,
                        chapterLabel: _answered
                            ? strings.chaptersSuffix(round.right.chapterCount)
                            : null,
                        state: _tileState(round.right.name),
                        onTap: () => _select(round.right),
                      ),
                      if (_answered) ...[
                        const SizedBox(height: 16),
                        Text(
                          _selected == round.higher.name
                              ? strings.higherLowerCorrect(
                                  round.higher.label,
                                  round.higher.chapterCount,
                                )
                              : strings.higherLowerWrong(
                                  round.higher.label,
                                  round.higher.chapterCount,
                                ),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: AppButtonStyles.primaryGradientButton,
                            onPressed: _nextRound,
                            child: Text(strings.nextRound),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  strings.higherLowerFooter,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar(BibleGameStrings strings, BibleGameLanguage language) {
    return AppBar(
      title: Text(strings.higherLowerTitle),
      actions: [
        BibleGameLanguageToggle(
          value: language,
          compact: true,
          onChanged: (value) =>
              ref.read(bibleGameLanguageProvider.notifier).setLanguage(value),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

class _BookTapTile extends StatelessWidget {
  /// The book name to render, already localized by the engine.
  final String label;

  /// Shown only after answering; already formatted for the active language
  /// (e.g. `50 ch` or `५० अध्याय`).
  final String? chapterLabel;

  final GameOptionState state;
  final VoidCallback onTap;

  const _BookTapTile({
    required this.label,
    required this.chapterLabel,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color background = isDark ? const Color(0xFF1E293B) : AppColors.bgCard;
    Color border = isDark ? const Color(0xFF334155) : AppColors.borderLight;
    IconData? icon;
    Color? iconColor;

    switch (state) {
      case GameOptionState.correct:
        background = isDark
            ? const Color(0xFF064E3B)
            : AppColors.successBg;
        border = AppColors.success;
        icon = Icons.check_circle_rounded;
        iconColor = AppColors.success;
        break;
      case GameOptionState.wrong:
        background = isDark ? const Color(0xFF7F1D1D) : AppColors.errorBg;
        border = AppColors.error;
        icon = Icons.cancel_rounded;
        iconColor = AppColors.error;
        break;
      case GameOptionState.idle:
      case GameOptionState.selected:
        break;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: state == GameOptionState.idle ? onTap : null,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: 1.4),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: AppColors.textWhite,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (chapterLabel != null)
                Text(
                  chapterLabel!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
              if (icon != null) ...[
                const SizedBox(width: 8),
                Icon(icon, color: iconColor, size: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }
}