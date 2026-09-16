import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/common/widgets/app_empty_state.dart';
import '../../../../core/common/widgets/app_loading.dart';
import '../../../../core/common/widgets/app_scaffold.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../domain/entities/bible_game_entities.dart';
import '../../domain/services/bible_game_engine.dart';
import '../../domain/services/bible_game_session.dart';
import '../providers/bible_games_provider.dart';
import '../widgets/bible_game_widgets.dart';

/// Guess the Book — read the opening words of a random verse and tap the book
/// it comes from. Endless rounds, 10 points per correct answer, streak
/// tracking. A fresh random session is created on every open, so the verse
/// order is never the same twice. The verse reference stays hidden until you
/// answer so it can't give the book away.
class GuessBookPage extends ConsumerStatefulWidget {
  const GuessBookPage({super.key});

  @override
  ConsumerState<GuessBookPage> createState() => _GuessBookPageState();
}

class _GuessBookPageState extends ConsumerState<GuessBookPage> {
  late BibleGameEngine _engine;
  GameSession? _session;

  List<BibleGameBook> _books = const [];
  GuessBookRound? _round;
  String? _selected;
  bool _loading = true;
  bool _answered = false;
  bool _unavailable = false;

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
    final data = await ref.read(bibleGamesDataProvider.future);
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
    final verses = rows.map(BibleGameVerse.fromDbRow).toList();
    setState(() {
      _round = _engine.guessBookRound(books: _books, verses: verses);
      _loading = false;
    });
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_unavailable) {
      return const AppScaffold(
        body: AppEmptyState(
          icon: Icons.menu_book_outlined,
          title: 'Bible data unavailable',
          subtitle: 'This game needs the offline Bible database, which is not '
              'available in this build.',
        ),
      );
    }

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Guess the Book'),
      ),
      body: _loading || round == null || session == null
          ? const Center(child: AppLoading(message: 'Finding a verse…'))
          : ListView(
              padding: const EdgeInsets.all(AppDimensions.paddingLg),
              children: [
                GameScoreHeader(
                  score: session.score,
                  streak: session.streak,
                  optional: 'Round ${session.roundIndex + 1}',
                ),
                const SizedBox(height: 16),
                GameRoundCard(
                  title: 'Which book is this?',
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
                              '“${round.fullText}”',
                              style: const TextStyle(
                                fontSize: 17,
                                fontStyle: FontStyle.italic,
                                height: 1.5,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (_answered) ...[
                              const SizedBox(height: 10),
                              Text(
                                '— ${round.reference}',
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
                                    'Hint: ${round.hint}',
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
                      ? 'Answer: ${round.correctBook} — ${round.reference}'
                      : 'Choose the book',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                ...round.options.map(
                  (option) => GameOptionTile(
                    label: option,
                    state: _tileState(option),
                    disabled: _answered,
                    onTap: () => _select(option),
                  ),
                ),
                if (_answered) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: AppButtonStyles.primaryGradientButton,
                      onPressed: _advance,
                      child: const Text('Next Verse'),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}