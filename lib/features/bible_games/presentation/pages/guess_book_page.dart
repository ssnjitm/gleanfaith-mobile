import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/common/widgets/app_empty_state.dart';
import '../../../../core/common/widgets/app_loading.dart';
import '../../../../core/common/widgets/app_scaffold.dart';
import '../../../../core/services/database_service.dart';
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

/// Guess the Book — read the opening words of a random verse and tap the book
/// it comes from. Endless rounds, 10 points per correct answer, streak
/// tracking. A fresh random session is created on every open, so the verse
/// order is never the same twice. The verse reference stays hidden until you
/// answer so it can't give the book away.
///
/// Renders in the device language by default, overridable with the `EN | NP`
/// toggle in the `AppBar`. The offline DB supplies the KJV verse, but in Nepali
/// mode the inline catalog's translation is used when it holds one for that
/// exact book/chapter/verse; otherwise the KJV text is shown together with a
/// visible "no translation" note rather than passing for Nepali.
class GuessBookPage extends ConsumerStatefulWidget {
  const GuessBookPage({super.key});

  @override
  ConsumerState<GuessBookPage> createState() => _GuessBookPageState();
}

class _GuessBookPageState extends ConsumerState<GuessBookPage>
    with BibleGameLanguageSync<GuessBookPage> {
  late BibleGameEngine _engine;
  GameSession? _session;

  List<BibleGameBook> _books = const [];
  GuessBookRound? _round;
  String? _selected;
  bool _loading = true;
  bool _answered = false;
  bool _unavailable = false;

  /// The language the visible verse and options were built with.
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
    await _nextRound();
  }

  Future<void> _nextRound() async {
    final session = _session;
    if (session == null) return;
    setState(() {
      _loading = true;
      _answered = false;
      _selected = null;
    });
    final rows = await DatabaseService.instance.getRandomVerses(
      count: 1,
      seed: session.seedForRound(session.roundIndex),
    );
    if (!mounted) return;
    final language = ref.read(bibleGameLanguageProvider);
    final verses = [
      for (final row in rows) BibleGameVerse.fromDbRow(row).localized(language),
    ];
    setState(() {
      _round = _engine.guessBookRound(
        books: _books,
        verses: verses,
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
    setState(() {
      _books = books;
      _roundLanguage = language;
      _answered = false;
      _selected = null;
      _loading = true;
    });
    await _nextRound();
  }

  void _select(String book) {
    final round = _round;
    final session = _session;
    if (_answered || _selected != null || round == null || session == null) {
      return;
    }
    final isCorrect = book == round.correctBook;
    setState(() {
      _selected = book;
      _answered = true;
      session.registerResult(correct: isCorrect, points: 10);
    });
  }

  void _advance() => _nextRound();

  GameOptionState _tileState(String option) {
    final round = _round;
    if (round == null || !_answered) return GameOptionState.idle;
    if (option == round.correctBook) return GameOptionState.correct;
    if (option == _selected) return GameOptionState.wrong;
    return GameOptionState.idle;
  }

  @override
  Widget build(BuildContext context) {
    final round = _round;
    final session = _session;
    final strings = ref.watch(bibleGameStringsProvider);
    final language = ref.watch(bibleGameLanguageProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
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

    // Rendered labels fall back to the DB names until a round exists.
    final labels = (round?.displayOptions.isNotEmpty ?? false)
        ? round!.displayOptions
        : round?.options ?? const <String>[];

    return AppScaffold(
      appBar: AppBar(
        title: Text(strings.guessBookTitle),
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
          ? Center(child: AppLoading(message: strings.guessBookLoading))
          : ListView(
              padding: const EdgeInsets.all(AppDimensions.paddingLg),
              children: [
                GameScoreHeader(
                  score: session.score,
                  streak: session.streak,
                  optional: strings.roundLabel(session.roundIndex + 1),
                ),
                const SizedBox(height: 16),
                GameRoundCard(
                  title: strings.guessBookQuestion,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0F172A)
                              : AppColors.bgGray,
                          borderRadius: BorderRadius.circular(12),
                          border: const Border(
                            left: BorderSide(
                              color: AppColors.primaryAmber,
                              width: 4,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '"${round.fullText}"',
                              style: const TextStyle(
                                fontSize: 17,
                                fontStyle: FontStyle.italic,
                                height: 1.5,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            // Nepali mode with no catalog entry: say so
                            // instead of letting English pass for Nepali.
                            if (language == BibleGameLanguage.nepali &&
                                !round.hasTranslation) ...[
                              const SizedBox(height: 8),
                              Text(
                                strings.noNepaliVerse,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : AppColors.textMuted,
                                ),
                              ),
                            ],
                            if (_answered) ...[
                              const SizedBox(height: 10),
                              Text(
                                '- ${round.referenceLabel}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : AppColors.textMuted,
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.lightbulb_outline_rounded,
                                  size: 18,
                                  color: isDark
                                      ? const Color(0xFFFBBF24)
                                      : AppColors.primaryAmber,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    strings.guessBookHint(round.hint),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? const Color(0xFFE2E8F0)
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  _answered
                      ? strings.guessBookAnswer(
                          round.correctBookLabel,
                          round.referenceLabel,
                        )
                      : strings.guessBookChoose,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                for (var i = 0; i < round.options.length; i++)
                  GameOptionTile(
                    label: labels[i],
                    state: _tileState(round.options[i]),
                    disabled: _answered,
                    onTap: () => _select(round.options[i]),
                  ),
                if (_answered) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: AppButtonStyles.primaryGradientButton,
                      onPressed: _advance,
                      child: Text(strings.guessBookNext),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
