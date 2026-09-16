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

/// Higher / Lower — endless streak round: tap the book with MORE chapters.
/// Each open starts a fresh random session so the pairs are never predictable.
class HigherLowerPage extends ConsumerStatefulWidget {
  const HigherLowerPage({super.key});

  @override
  ConsumerState<HigherLowerPage> createState() => _HigherLowerPageState();
}

class _HigherLowerPageState extends ConsumerState<HigherLowerPage> {
  static const int pointsPerRound = 10;

  late BibleGameEngine _engine;
  GameSession? _session;

  List<BibleGameBook> _books = const [];
  HigherLowerRound? _round;
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
    _nextRound();
  }

  void _nextRound() {
    setState(() {
      _answered = false;
      _selected = null;
      _round = _engine.higherLowerRound(_books);
      _loading = false;
    });
  }

  void _select(BibleGameBook tapped) {
    final round = _round;
    final session = _session;
    if (_answered || _selected != null || round == null || session == null) {
      return;
    }
    final isCorrect = tapped.name == round.higher.name;
    setState(() {
      _selected = tapped.name;
      _answered = true;
      session.registerResult(correct: isCorrect, points: pointsPerRound);
    });
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
        title: const Text('Higher / Lower'),
      ),
      body: _loading || round == null || session == null
          ? const Center(child: AppLoading(message: 'Scoring the books…'))
          : ListView(
              padding: const EdgeInsets.all(AppDimensions.paddingLg),
              children: [
                GameScoreHeader(
                  score: session.score,
                  streak: session.streak,
                  optional: 'Never-ending',
                ),
                const SizedBox(height: 16),
                GameRoundCard(
                  title: 'Which book has more chapters?',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _BookTapTile(
                        label: round.left.name,
                        chapterCount: _answered ? round.left.chapterCount : null,
                        state: _tileState(round.left.name),
                        onTap: () => _select(round.left),
                      ),
                      const SizedBox(height: 12),
                      _BookTapTile(
                        label: round.right.name,
                        chapterCount: _answered
                            ? round.right.chapterCount
                            : null,
                        state: _tileState(round.right.name),
                        onTap: () => _select(round.right),
                      ),
                      if (_answered) ...[
                        const SizedBox(height: 16),
                        Text(
                          _selected == round.higher.name
                              ? 'More chapters: ${round.higher.name} '
                                  '(${round.higher.chapterCount}).'
                              : 'Streak broken! ${round.higher.name} wins with '
                                  '${round.higher.chapterCount} chapters.',
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
                            child: const Text('Next Round'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Chapter counts are hidden until you pick. Keep your streak '
                  'alive — wrong picks reset it.',
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

class _BookTapTile extends StatelessWidget {
  final String label;
  final int? chapterCount;
  final GameOptionState state;
  final VoidCallback onTap;

  const _BookTapTile({
    required this.label,
    required this.chapterCount,
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
              if (chapterCount != null)
                Text(
                  '$chapterCount ch',
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