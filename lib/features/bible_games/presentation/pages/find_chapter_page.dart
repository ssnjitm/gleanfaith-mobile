import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/common/widgets/app_empty_state.dart';
import '../../../../core/common/widgets/app_loading.dart';
import '../../../../core/common/widgets/app_scaffold.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../domain/entities/bible_game_entities.dart';
import '../../domain/entities/bible_game_localization.dart';
import '../../domain/services/bible_game_engine.dart';
import '../../domain/services/bible_game_session.dart';
import '../providers/bible_game_language_provider.dart';
import '../providers/bible_games_provider.dart';
import '../widgets/bible_game_language_toggle.dart';
import '../widgets/bible_game_widgets.dart';
import 'bible_game_language_sync.dart';

/// Find the Chapter — a 60-second blitz. Tap the tile holding the target
/// "book chapter"; every hit fires a fresh round instantly. Every open starts
/// a fresh random session so the grid layout is never the same twice.
///
/// Renders in the device language by default, overridable with the `EN | NP`
/// toggle in the `AppBar`: tiles show the localized book name and Devanagari
/// chapter numbers, while the tap comparison runs against the DB identity
/// labels. Switching language rebuilds the grid in place and keeps the clock
/// running, so a mid-blitz switch neither costs nor grants time.
class FindChapterPage extends ConsumerStatefulWidget {
  const FindChapterPage({super.key});

  @override
  ConsumerState<FindChapterPage> createState() => _FindChapterPageState();
}

class _FindChapterPageState extends ConsumerState<FindChapterPage>
    with BibleGameLanguageSync<FindChapterPage> {
  static const int roundSeconds = 60;
  static const int gridSize = 16;

  late BibleGameEngine _engine;
  GameSession? _session;

  List<BibleGameBook> _books = const [];
  FindChapterRound? _round;
  String? _successLabel;
  String? _wrongFlashLabel;
  Timer? _timer;
  bool _loading = true;
  bool _finished = false;
  bool _unavailable = false;
  int _secondsLeft = roundSeconds;
  int _correctCount = 0;

  /// The language the visible grid was built with.
  BibleGameLanguage _roundLanguage = BibleGameLanguage.english;

  @override
  BibleGameLanguage get roundLanguage => _roundLanguage;

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _startGame() async {
    _timer?.cancel();
    final session = GameSession();
    setState(() {
      _session = session;
      _engine = BibleGameEngine(random: session.random);
      _books = const [];
      _round = null;
      _finished = false;
      _secondsLeft = roundSeconds;
      _correctCount = 0;
      _successLabel = null;
      _wrongFlashLabel = null;
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
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
    _nextRound();
  }

  void _onTick() {
    if (!mounted) return;
    if (_secondsLeft <= 1) {
      _timer?.cancel();
      setState(() {
        _secondsLeft = 0;
        _finished = true;
      });
      return;
    }
    setState(() => _secondsLeft -= 1);
  }

  void _nextRound() {
    final language = ref.read(bibleGameLanguageProvider);
    setState(() {
      _successLabel = null;
      _wrongFlashLabel = null;
      _round = _engine.findChapterRound(
        _books,
        gridSize: gridSize,
        language: language,
      );
      _roundLanguage = language;
      _loading = false;
    });
  }

  @override
  Future<void> applyBibleGameLanguage(BibleGameLanguage language) async {
    final books = await localizedBooks();
    if (!mounted) return;
    // A finished blitz keeps its result card — there is no grid to relabel.
    if (_finished) return;
    setState(() {
      _books = books;
      _successLabel = null;
      _wrongFlashLabel = null;
      _roundLanguage = language;
      _round = _engine.findChapterRound(
        books,
        gridSize: gridSize,
        language: language,
      );
    });
  }

  void _tap(String label) {
    final round = _round;
    final session = _session;
    if (round == null || session == null) return;
    if (_successLabel != null || _wrongFlashLabel != null) return;

    if (label == round.targetLabel) {
      setState(() {
        _successLabel = label;
        _correctCount += 1;
        session.registerResult(correct: true, points: 10);
      });
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _nextRound();
      });
    } else {
      setState(() {
        _wrongFlashLabel = label;
        session.registerResult(correct: false, points: 0);
      });
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) setState(() => _wrongFlashLabel = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final round = _round;
    final session = _session;
    final strings = ref.watch(bibleGameStringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final language = ref.watch(bibleGameLanguageProvider);
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

    if (_finished) {
      return AppScaffold(
        appBar: AppBar(
          title: Text(strings.findChapterTitle),
          actions: [
            BibleGameLanguageToggle(
              value: language,
              compact: true,
              onChanged: (value) => ref
                  .read(bibleGameLanguageProvider.notifier)
                  .setLanguage(value),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: GameResultCard(
          score: session?.score ?? 0,
          bestStreak: session?.bestStreak ?? 0,
          totalAnswered: _correctCount,
          title: strings.findChapterTitle,
          subtitle: strings.findChapterTimeUp(_correctCount),
          strings: strings,
          onReplay: _startGame,
        ),
      );
    }

    return AppScaffold(
      appBar: AppBar(
        title: Text(strings.findChapterTitle),
        actions: [
          BibleGameLanguageToggle(
            value: language,
            compact: true,
            onChanged: (value) => ref
                .read(bibleGameLanguageProvider.notifier)
                .setLanguage(value),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading || round == null || session == null
          ? Center(child: AppLoading(message: strings.findChapterLoading))
          : ListView(
              padding: const EdgeInsets.all(AppDimensions.paddingLg),
              children: [
                GameScoreHeader(
                  score: session.score,
                  streak: session.streak,
                  optional: strings.secondsLeft(_secondsLeft),
                ),
                const SizedBox(height: 16),
                GameRoundCard(
                  title: strings.findChapterTap(round.targetLabelText),
                  child: GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.05,
                    children: [
                      for (var i = 0; i < round.options.length; i++)
                        _ChapterTile(
                          label: round.optionLabels[i],
                          state: round.options[i] == _successLabel
                              ? GameOptionState.correct
                              : (round.options[i] == _wrongFlashLabel
                                  ? GameOptionState.wrong
                                  : GameOptionState.idle),
                          onTap: () => _tap(round.options[i]),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  strings.findChapterFooter(round.targetLabelText),
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF94A3B8) : AppColors.textMuted,
                  ),
                ),
              ],
            ),
    );
  }
}

class _ChapterTile extends StatelessWidget {
  final String label;
  final GameOptionState state;
  final VoidCallback onTap;

  const _ChapterTile({
    required this.label,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color background = isDark ? const Color(0xFF1E293B) : AppColors.bgCard;
    Color border = isDark ? const Color(0xFF334155) : AppColors.borderLight;
    Color foreground = isDark ? const Color(0xFFE2E8F0) : AppColors.textSecondary;

    switch (state) {
      case GameOptionState.correct:
        background = isDark
            ? const Color(0xFF064E3B)
            : AppColors.successBg;
        border = AppColors.success;
        foreground = AppColors.success;
        break;
      case GameOptionState.wrong:
        background = isDark ? const Color(0xFF7F1D1D) : AppColors.errorBg;
        border = AppColors.error;
        foreground = AppColors.error;
        break;
      case GameOptionState.idle:
      case GameOptionState.selected:
        break;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: state == GameOptionState.idle ? onTap : null,
        child: Container(
          padding: const EdgeInsets.all(4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border, width: 1.2),
          ),
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              height: 1.2,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ),
      ),
    );
  }
}