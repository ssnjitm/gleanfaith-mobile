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

/// Book Order Race — tap the five book tiles in canonical Bible order.
/// Endless rounds; auto-advances when a round is completed. Every open starts
/// a fresh random session so the book sets/order are never predictable.
///
/// Renders in the device language by default, overridable with the `EN | NP`
/// toggle in the `AppBar`. Tiles are compared by DB book name, so a Nepali
/// round is scored exactly like an English one.
class BookOrderPage extends ConsumerStatefulWidget {
  const BookOrderPage({super.key});

  @override
  ConsumerState<BookOrderPage> createState() => _BookOrderPageState();
}

class _BookOrderPageState extends ConsumerState<BookOrderPage>
    with BibleGameLanguageSync<BookOrderPage>, GameLivesGate<BookOrderPage> {
  static const int booksPerRound = 5;

  late BibleGameEngine _engine;
  GameSession? _session;

  List<BibleGameBook> _books = const [];
  BookOrderRound? _round;

  /// DB book names already tapped this round, in tap order. Identity, not
  /// labels — the chips render the localized name.
  final List<String> _picked = [];
  String? _wrongFlashName;
  bool _loading = true;
  bool _unavailable = false;

  /// The language the visible tile set was built with.
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
    _picked.clear();
    super.dispose();
  }

  Future<void> _startGame() async {
    final session = GameSession();
    setState(() {
      _session = session;
      _engine = BibleGameEngine(random: session.random);
      _books = const [];
      _round = null;
      _loading = true;
      _unavailable = false;
      _wrongFlashName = null;
    });
    _picked.clear();
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
    _nextRound();
  }

  void _nextRound() {
    final language = ref.read(bibleGameLanguageProvider);
    setState(() {
      _picked.clear();
      _wrongFlashName = null;
      _round = _engine.bookOrderRound(
        _books,
        numberOfBooks: booksPerRound,
        language: language,
      );
      _roundLanguage = language;
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
      _picked.clear();
      _wrongFlashName = null;
      _roundLanguage = language;
      _round = _engine.bookOrderRound(
        books,
        numberOfBooks: booksPerRound,
        language: language,
    );
    });
    noteNewRound();
  }

  void _tap(BibleGameBook book) {
    final round = _round;
    final session = _session;
    if (round == null || session == null) return;
    if (isLocked) return;
    if (_picked.length >= round.shuffledBooks.length) return;
    final expected = round.correctOrder[_picked.length].name;

    if (book.name == expected) {
      setState(() {
        _picked.add(book.name);
        session.registerResult(correct: true, points: 10, advanceRound: false);
      });
      if (_picked.length == round.shuffledBooks.length) {
        // The whole set is in canonical order: this round is over, so test it
        // for a perfect run before the next round resets the test.
        noteCorrectAnswer();
        noteRoundComplete();
        session.roundIndex += 1;
        Future.delayed(const Duration(milliseconds: 550), () {
          if (!mounted) return;
          _nextRound();
        });
      }
    } else {
      setState(() {
        _wrongFlashName = book.name;
        session.registerResult(correct: false, points: 0, advanceRound: false);
      });
      // A wrong tap here is recoverable — the book stays on the board — but it
      // still costs a life and disqualifies the round from a perfect refund.
      noteWrongTap();
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) setState(() => _wrongFlashName = null);
      });
    }
  }

  @override
  BibleGameKind get gameKind => BibleGameKind.bookOrder;

  @override
  GameSession? get livesSession => _session;

  /// The localized name for a DB book name that is part of this round.
  String _labelFor(BookOrderRound round, String bookName) {
    for (final book in round.shuffledBooks) {
      if (book.name == bookName) return book.label;
    }
    return bookName;
  }

  @override
  Widget build(BuildContext context) {
    final round = _round;
    final session = _session;
    final strings = ref.watch(bibleGameStringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final language = ref.watch(bibleGameLanguageProvider);
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

    if (livesState.hasValue && isLocked) {
      return AppScaffold(
        appBar: _buildAppBar(strings, language),
        body: GameCooldownOverlay(
          kind: gameKind,
          title: strings.bookOrderTitle,
        ),
      );
    }

    return AppScaffold(
      appBar: _buildAppBar(strings, language),
      body: _loading || round == null || session == null || !livesLoaded
          ? Center(child: AppLoading(message: strings.bookOrderLoading))
          : LifeLossShake(
              trigger: lifeLossTrigger,
              child: ListView(
              padding: const EdgeInsets.all(AppDimensions.paddingLg),
              children: [
                GameScoreHeader(
                  score: session.score,
                  streak: session.streak,
                  optional: strings.roundLabel(session.roundIndex + 1),
                ),
                const SizedBox(height: 10),
                buildLivesHeader(strings),
                const SizedBox(height: 10),
                GameRoundCard(
                  title: strings.bookOrderQuestion,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_picked.isEmpty)
                        Text(
                          strings.bookOrderStartWith(session.roundIndex + 1),
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : AppColors.textMuted,
                          ),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (var i = 0; i < _picked.length; i++)
                              _OrderChip(
                                index: i + 1,
                                name: _labelFor(round, _picked[i]),
                              ),
                          ],
                        ),
                      const SizedBox(height: 16),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 2.4,
                        children: [
                          for (final book in round.shuffledBooks)
                            if (!_picked.contains(book.name))
                              _OrderTile(
                                name: book.label,
                                isWrongFlash: book.name == _wrongFlashName,
                                onTap: () => _tap(book),
                              ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  strings.bookOrderFooter,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF94A3B8) : AppColors.textMuted,
                  ),
                ),
              ],
            ),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BibleGameStrings strings,
    BibleGameLanguage language,
  ) {
    return AppBar(
      title: Text(strings.bookOrderTitle),
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

class _OrderChip extends StatelessWidget {
  final int index;
  final String name;

  const _OrderChip({required this.index, required this.name});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : AppColors.successBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.success, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$index.',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            name,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final String name;
  final bool isWrongFlash;
  final VoidCallback onTap;

  const _OrderTile({
    required this.name,
    required this.isWrongFlash,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final background = isWrongFlash
        ? (isDark ? const Color(0xFF7F1D1D) : AppColors.errorBg)
        : (isDark ? const Color(0xFF1E293B) : AppColors.bgCard);
    final border =
        isWrongFlash ? AppColors.error : (isDark ? const Color(0xFF334155) : AppColors.borderLight);
    final foreground =
        isWrongFlash ? AppColors.error : AppColors.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: 1.4),
          ),
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ),
      ),
    );
  }
}