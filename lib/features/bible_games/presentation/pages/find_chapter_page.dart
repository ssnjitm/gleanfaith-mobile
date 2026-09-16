import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/common/widgets/app_empty_state.dart';
import '../../../../core/common/widgets/app_loading.dart';
import '../../../../core/common/widgets/app_scaffold.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../domain/entities/bible_game_entities.dart';
import '../../domain/services/bible_game_engine.dart';
import '../../domain/services/bible_game_session.dart';
import '../providers/bible_games_provider.dart';
import '../widgets/bible_game_widgets.dart';

/// Find the Chapter — a 60-second blitz. Tap the tile holding the target
/// "book chapter"; every hit fires a fresh round instantly. Every open starts
/// a fresh random session so the grid layout is never the same twice.
class FindChapterPage extends ConsumerStatefulWidget {
  const FindChapterPage({super.key});

  @override
  ConsumerState<FindChapterPage> createState() => _FindChapterPageState();
}

class _FindChapterPageState extends ConsumerState<FindChapterPage> {
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
    setState(() {
      _successLabel = null;
      _wrongFlashLabel = null;
      _round = _engine.findChapterRound(_books, gridSize: gridSize);
      _loading = false;
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

    if (_finished) {
      return AppScaffold(
        body: GameResultCard(
          score: session?.score ?? 0,
          bestStreak: session?.bestStreak ?? 0,
          totalAnswered: _correctCount,
          title: 'Find the Chapter',
          subtitle: 'Time is up — you found $_correctCount chapters!',
          onReplay: _startGame,
        ),
      );
    }

    return AppScaffold(
      appBar: AppBar(title: const Text('Find the Chapter')),
      body: _loading || round == null || session == null
          ? const Center(child: AppLoading(message: 'Laying out the grid…'))
          : ListView(
              padding: const EdgeInsets.all(AppDimensions.paddingLg),
              children: [
                GameScoreHeader(
                  score: session.score,
                  streak: session.streak,
                  optional: '${_secondsLeft}s left',
                ),
                const SizedBox(height: 16),
                GameRoundCard(
                  title: 'Tap “${round.targetLabel}”',
                  child: GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.05,
                    children: [
                      for (final option in round.options)
                        _ChapterTile(
                          label: option,
                          state: option == _successLabel
                              ? GameOptionState.correct
                              : (option == _wrongFlashLabel
                                  ? GameOptionState.wrong
                                  : GameOptionState.idle),
                          onTap: () => _tap(option),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Find “${round.targetLabel}” fast — each hit scores 10 and a '
                  'new grid appears. Wrong taps cost your streak.',
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