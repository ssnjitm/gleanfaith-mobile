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

/// Fun Facts — trivia driven by real stats from the offline DB
/// (longest/shortest verse, biggest/smallest books). Rounds cycle endlessly,
/// with explanations shown after every answer. A fresh random session per open
/// shuffles the facts so they never repeat in the same order.
class FunFactsPage extends ConsumerStatefulWidget {
  const FunFactsPage({super.key});

  @override
  ConsumerState<FunFactsPage> createState() => _FunFactsPageState();
}

class _FunFactsPageState extends ConsumerState<FunFactsPage> {
  late BibleGameEngine _engine;
  GameSession? _session;

  List<FunFactRound> _rounds = const [];
  FunFactRound? _round;
  String? _selected;
  bool _loading = true;
  bool _unavailable = false;
  bool _answered = false;
  int _index = 0;

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
      _rounds = const [];
      _round = null;
      _selected = null;
      _answered = false;
      _index = 0;
      _loading = true;
      _unavailable = false;
    });
    final data = await ref.read(bibleGamesDataProvider.future);
    if (!mounted) return;
    if (data.isEmpty || data.extremes == null) {
      setState(() {
        _loading = false;
        _unavailable = true;
      });
      return;
    }
    setState(() {
      _rounds = _engine.funFactRounds(data.books, data.extremes!);
      _round = _rounds.isEmpty ? null : _rounds[_index];
      _loading = false;
    });
  }

  void _select(String answer) {
    final round = _round;
    final session = _session;
    if (_answered || _selected != null || round == null || session == null) {
      return;
    }
    final isCorrect = answer == round.correct;
    setState(() {
      _selected = answer;
      _answered = true;
      session.registerResult(correct: isCorrect, points: 10);
    });
  }

  void _advance() {
    setState(() {
      _index = (_index + 1) % _rounds.length;
      _selected = null;
      _answered = false;
      _round = _rounds[_index];
    });
  }

  GameOptionState _tileState(String option) {
    final round = _round;
    if (round == null || !_answered) return GameOptionState.idle;
    if (option == round.correct) return GameOptionState.correct;
    if (option == _selected) return GameOptionState.wrong;
    return GameOptionState.idle;
  }

  @override
  Widget build(BuildContext context) {
    if (_unavailable) {
      return const AppScaffold(
        appBar: null,
        body: AppEmptyState(
          icon: Icons.lightbulb_outline_rounded,
          title: 'Fun Facts unavailable',
          subtitle: 'Trivia needs the offline Bible database, which is not '
              'available in this build.',
        ),
      );
    }

    final round = _round;
    final session = _session;
    return AppScaffold(
      appBar: AppBar(title: const Text('Fun Facts')),
      body: _loading || round == null || session == null
          ? const Center(child: AppLoading(message: 'Digging up trivia…'))
          : ListView(
              padding: const EdgeInsets.all(AppDimensions.paddingLg),
              children: [
                GameScoreHeader(
                  score: session.score,
                  streak: session.streak,
                  optional: '${session.roundIndex} done',
                ),
                const SizedBox(height: 16),
                GameRoundCard(
                  title: round.prompt,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...round.options.map(
                        (option) => GameOptionTile(
                          label: option,
                          state: _tileState(option),
                          disabled: _answered,
                          onTap: () => _select(option),
                        ),
                      ),
                      if (_answered) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _selected == round.correct
                                ? AppColors.successBg
                                : AppColors.warningBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _selected == round.correct
                                ? 'Correct! ${round.explain}'
                                : 'Not quite — ${round.explain}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: AppButtonStyles.primaryGradientButton,
                            onPressed: _advance,
                            child: const Text('Next'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}