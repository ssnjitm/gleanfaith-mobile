import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../../../core/router/route_names.dart';
import '../../domain/entities/crosspuzzle_entities.dart';
import '../models/crossword_board.dart';
import '../providers/crosspuzzle_provider.dart';
import '../widgets/crossword_grid.dart';

class CrossPuzzlePlayPage extends ConsumerStatefulWidget {
  final String puzzleId;
  final String title;

  const CrossPuzzlePlayPage({
    super.key,
    required this.puzzleId,
    required this.title,
  });

  @override
  ConsumerState<CrossPuzzlePlayPage> createState() => _CrossPuzzlePlayPageState();
}

class _CrossPuzzlePlayPageState extends ConsumerState<CrossPuzzlePlayPage> {
  CrosswordBoard? _board;
  CrossPuzzleDetail? _detail;
  bool _loading = true;
  String? _error;

  int _mistakes = 0;
  int _hintsUsed = 0;
  int _timeSpentSeconds = 0;

  Timer? _ticker;
  Timer? _autosaveTimer;
  bool _autosaveInFlight = false;
  int _lastSavedFilled = -1;
  bool _saving = false;

  String _activeSheet = 'across';
  String? _lastActiveClueKey;

  final FocusNode _keyboardFocusNode = FocusNode();
  final FocusNode _hiddenInputFocusNode = FocusNode();
  final TextEditingController _hiddenInputController =
      TextEditingController(text: ' ');
  final ScrollController _clueListController = ScrollController();

  static const double _clueItemExtent = 46;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await ref
        .read(getPuzzleDetailUseCaseProvider)(widget.puzzleId)
        .run();
    if (!mounted) return;

    final detail = result.fold(
      (failure) {
        setState(() {
          _loading = false;
          _error = failure.message;
        });
        return null;
      },
      (detail) => detail,
    );
    if (detail == null) return;

    try {
      final board = CrosswordBoard.fromPuzzle(detail.puzzle);
      board.restore(
        detail.progress?.gridState,
        detail.progress?.revealedCells,
      );
      // Surface any incorrect letters saved from an earlier session
      // immediately, otherwise submit would stay locked with no visual cue.
      board.markIncorrectCells();
      if (detail.progress != null) {
        _mistakes = detail.progress!.mistakes;
        _hintsUsed = detail.progress!.hintsUsed;
        _timeSpentSeconds = detail.progress!.timeSpentSeconds;
      }
      _lastActiveClueKey = _clueKey(board);

      setState(() {
        _detail = detail;
        _board = board;
        _loading = false;
      });
      _syncActiveSheet(board);

      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _timeSpentSeconds += 1);
        _scheduleAutosave();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load puzzle: $e';
      });
    }
  }

  void _scheduleAutosave() {
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(const Duration(seconds: 2), _autosave);
  }

  Future<void> _autosave() async {
    final board = _board;
    final detail = _detail;
    if (board == null || detail == null || _autosaveInFlight) return;

    final filled = board.filledCellCount;
    if (filled == _lastSavedFilled && _timeSpentSeconds % 15 != 0) return;

    _autosaveInFlight = true;
    _lastSavedFilled = filled;
    final snapshotTime = _timeSpentSeconds;
    await ref
        .read(saveProgressUseCaseProvider)
        .call(
          puzzleId: widget.puzzleId,
          gridState: board.toGridState(),
          revealedCells: board.toRevealedCells(),
          mistakes: _mistakes,
          hintsUsed: _hintsUsed,
          timeSpentSeconds: snapshotTime,
        )
        .run();
    _autosaveInFlight = false;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _autosaveTimer?.cancel();
    _keyboardFocusNode.dispose();
    _hiddenInputFocusNode.dispose();
    _hiddenInputController.dispose();
    _clueListController.dispose();
    if (_board != null && _detail != null) {
      ref.read(saveProgressUseCaseProvider).call(
            puzzleId: widget.puzzleId,
            gridState: _board!.toGridState(),
            revealedCells: _board!.toRevealedCells(),
            mistakes: _mistakes,
            hintsUsed: _hintsUsed,
            timeSpentSeconds: _timeSpentSeconds,
          ).run();
    }
    super.dispose();
  }

  void _requestFocusForInput() {
    if (_hiddenInputFocusNode.hasFocus) return;
    _hiddenInputFocusNode.requestFocus();
    // Some devices drop focus while the layout settles (keyboard animating
    // in, rebuilds) — retry shortly after to keep the keyboard up.
    Future.delayed(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      if (!_hiddenInputFocusNode.hasFocus) {
        _hiddenInputFocusNode.requestFocus();
      }
    });
  }

  void _syncActiveSheet(CrosswordBoard board) {
    _activeSheet = board.activeDirection ?? 'across';
  }

  void _onCellChanged(int filledCount) {
    final board = _board;
    setState(() {});
    if (board != null) {
      _syncActiveSheet(board);
      _ensureActiveClueVisible(board);
    }
    _requestFocusForInput();
    _scheduleAutosave();
  }

  void _ensureActiveClueVisible(CrosswordBoard board) {
    final key = _clueKey(board);
    if (key == _lastActiveClueKey) return;
    _lastActiveClueKey = key;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_clueListController.hasClients) return;
      final clues =
          _activeSheet == 'across' ? board.acrossClues : board.downClues;
      final index =
          clues.indexWhere((c) => c.number == board.activeClueNumber);
      if (index < 0) return;
      final target = (index * _clueItemExtent)
          .clamp(0.0, _clueListController.position.maxScrollExtent);
      _clueListController.animateTo(
        target,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  String _clueKey(CrosswordBoard board) =>
      '${board.activeDirection ?? ''}-${board.activeClueNumber ?? ''}';

  void _handleTextInput(String value) {
    final board = _board;
    if (board == null) return;

    if (value.isEmpty) {
      board.handleBackspace();
      _resetHiddenController();
      _onCellChanged(board.filledCellCount);
      return;
    }

    // inputLetter places the letter and advances the cursor — it must NOT
    // be called again here.
    final char = value.substring(value.length - 1);
    if (RegExp(r'^[a-zA-Z]$').hasMatch(char)) {
      board.inputLetter(char);
    }
    _resetHiddenController();
    _onCellChanged(board.filledCellCount);
  }

  void _resetHiddenController() {
    _hiddenInputController.value = const TextEditingValue(
      text: ' ',
      selection: TextSelection.collapsed(offset: 1),
    );
  }

  void _handleKeyEvent(KeyEvent event) {
    final board = _board;
    if (board == null) return;
    if (event is! KeyDownEvent) return;
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowRight) {
      board.moveBy(0, 1);
      _onCellChanged(board.filledCellCount);
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      board.moveBy(0, -1);
      _onCellChanged(board.filledCellCount);
    } else if (key == LogicalKeyboardKey.arrowDown) {
      board.moveBy(1, 0);
      _onCellChanged(board.filledCellCount);
    } else if (key == LogicalKeyboardKey.arrowUp) {
      board.moveBy(-1, 0);
      _onCellChanged(board.filledCellCount);
    } else if (key == LogicalKeyboardKey.backspace ||
        key == LogicalKeyboardKey.delete) {
      board.handleBackspace();
      _onCellChanged(board.filledCellCount);
    } else if (key == LogicalKeyboardKey.space) {
      board.toggleDirection();
      _onCellChanged(board.filledCellCount);
    } else if (key == LogicalKeyboardKey.tab) {
      if (event.character == null) {
        board.toggleDirection();
        _onCellChanged(board.filledCellCount);
      }
    } else if (key == LogicalKeyboardKey.enter) {
      _complete();
    }
  }

  /// Submission is only allowed once every box is filled — and, when the
  /// puzzle ships answers, every letter is correct (no red cells).
  bool _canSubmit(CrosswordBoard board) {
    if (board.hasAnswers) {
      return board.isFullyCorrect;
    }
    return board.filledCellCount >= board.totalActiveCells;
  }

  Future<void> _complete() async {
    final board = _board;
    if (board == null || _saving || !_canSubmit(board)) return;

    setState(() => _saving = true);
    final result = await ref
        .read(completePuzzleUseCaseProvider)
        .call(
          puzzleId: widget.puzzleId,
          gridState: board.toGridState(),
          mistakes: _mistakes,
          hintsUsed: _hintsUsed,
          timeSpentSeconds: _timeSpentSeconds,
        )
        .run();
    if (!mounted) return;
    setState(() => _saving = false);

    final completed = result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
        return null;
      },
      (result) => result,
    );
    if (completed == null) return;

    context.pushReplacement(RouteNames.crossPuzzleResult, extra: completed);
  }

  String get _elapsedLabel {
    final h = _timeSpentSeconds ~/ 3600;
    final m = (_timeSpentSeconds % 3600) ~/ 60;
    final s = _timeSpentSeconds % 60;
    String two(int v) => v.toString().padLeft(2, '0');
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppDimensions.paddingMd),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryAmber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_outlined,
                        size: 14, color: AppColors.primaryAmber),
                    const SizedBox(width: 4),
                    Text(
                      _elapsedLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryAmber,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
            const SizedBox(height: AppDimensions.paddingMd),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: AppDimensions.lg),
            ElevatedButton(
              onPressed: _loadDetail,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final board = _board!;

    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
        child: SafeArea(
          child: Stack(
            children: [
              // Invisible but fully laid-out input capture field. Kept inside
              // the tree (not offstage) so it can hold focus and summon the
              // software keyboard reliably on Android/iOS.
              IgnorePointer(
                child: Opacity(
                  opacity: 0,
                  child: SizedBox(
                    width: 1,
                    height: 1,
                    child: TextField(
                      focusNode: _hiddenInputFocusNode,
                      controller: _hiddenInputController,
                      keyboardType: TextInputType.text,
                      textCapitalization: TextCapitalization.characters,
                      autocorrect: false,
                      enableSuggestions: false,
                      onChanged: _handleTextInput,
                    ),
                  ),
                ),
              ),
            Column(
              children: [
                _buildTopBar(context, board),
                Expanded(child: _buildGridArea(context, board)),
                _buildBottomPanel(context, board),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Progress strip + current-clue banner.
  Widget _buildTopBar(BuildContext context, CrosswordBoard board) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = board.totalActiveCells == 0
        ? 0.0
        : board.filledCellCount / board.totalActiveCells;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.paddingMd,
        AppDimensions.paddingSm,
        AppDimensions.paddingMd,
        0,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.grid_on_rounded,
                size: 16,
                color: isDark ? Colors.grey[400] : AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                'Progress',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.grey[400] : AppColors.textMuted,
                ),
              ),
              const Spacer(),
              Text(
                '${board.filledCellCount} / ${board.totalActiveCells}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.grey[200] : AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              _StatBadge(
                icon: Icons.close_rounded,
                label: '$_mistakes',
                color: AppColors.error,
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor:
                  isDark ? const Color(0xFF334155) : AppColors.borderLight,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
            ),
          ),
          const SizedBox(height: AppDimensions.paddingSm),
          _ClueBanner(board: board, onTap: () => _toggleDirection(board)),
        ],
      ),
    );
  }

  void _toggleDirection(CrosswordBoard board) {
    board.toggleDirection();
    _onCellChanged(board.filledCellCount);
  }

  Widget _buildGridArea(BuildContext context, CrosswordBoard board) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: FittedBox(
            fit: BoxFit.contain,
            child: GestureDetector(
              onTap: _requestFocusForInput,
              child: Container(
                margin: const EdgeInsets.all(AppDimensions.paddingSm),
                child: CrosswordGrid(board: board, onCellChanged: _onCellChanged),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Clue tabs + scrollable clue list + submit action.
  Widget _buildBottomPanel(BuildContext context, CrosswordBoard board) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16233B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF334155) : AppColors.borderLight,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.paddingMd,
              AppDimensions.paddingMd,
              AppDimensions.paddingMd,
              AppDimensions.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _TabChip(
                    label: 'Across',
                    count: board.acrossClues.length,
                    active: _activeSheet == 'across',
                    color: AppColors.primaryBlue,
                    onTap: () => setState(() => _activeSheet = 'across'),
                  ),
                ),
                const SizedBox(width: AppDimensions.sm),
                Expanded(
                  child: _TabChip(
                    label: 'Down',
                    count: board.downClues.length,
                    active: _activeSheet == 'down',
                    color: AppColors.primaryAmber,
                    onTap: () => setState(() => _activeSheet = 'down'),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: _clueItemExtent * 3.6,
              ),
              child: _ClueList(
                controller: _clueListController,
                board: board,
                activeSheet: _activeSheet,
                itemExtent: _clueItemExtent,
                onClueTap: (number, direction) {
                  board.selectClue(number, direction);
                  _onCellChanged(board.filledCellCount);
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.paddingMd,
              AppDimensions.sm,
              AppDimensions.paddingMd,
              AppDimensions.paddingMd,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 46,
              child: Builder(builder: (context) {
                final ready = _canSubmit(board);
                return ElevatedButton.icon(
                  onPressed: (_saving || !ready) ? null : _complete,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          ready ? Icons.check_rounded : Icons.lock_outline_rounded,
                          size: 20,
                        ),
                  label: Text(
                    _saving
                        ? 'Submitting…'
                        : ready
                            ? 'Submit Puzzle'
                            : 'Fill every box correctly to submit',
                    style:
                        const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        isDark ? const Color(0xFF334155) : AppColors.borderLight,
                    disabledForegroundColor:
                        isDark ? Colors.grey[500] : AppColors.textMuted,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClueBanner extends StatelessWidget {
  final CrosswordBoard board;
  final VoidCallback onTap;

  const _ClueBanner({required this.board, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final clue = board.activeClue;
    final isAcross = (board.activeDirection ?? 'across') == 'across';
    final dirColor = isAcross ? AppColors.primaryBlue : AppColors.primaryAmber;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.md,
            vertical: AppDimensions.sm + 2,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : AppColors.bgWhite,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : AppColors.borderLight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 38,
                decoration: BoxDecoration(
                  color: dirColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          clue == null
                              ? '—'
                              : '${clue.number} ${isAcross ? 'ACROSS' : 'DOWN'}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: dirColor,
                          ),
                        ),
                        if (clue != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${clue.answerLength} letters · tap to flip',
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark
                                  ? Colors.grey[500]
                                  : AppColors.textLight,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      clue?.clue ?? 'Select a word to begin',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                        color:
                            isDark ? Colors.grey[100] : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final int count;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.count,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: active
              ? color.withValues(alpha: 0.14)
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F2F4)),
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(
            color: active ? color : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: active
                    ? color
                    : (isDark ? Colors.grey[400] : AppColors.textMuted),
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: active
                    ? color
                    : (isDark ? const Color(0xFF334155) : AppColors.borderLight),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: active
                      ? Colors.white
                      : (isDark ? Colors.grey[400] : AppColors.textMuted),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClueList extends StatelessWidget {
  final ScrollController controller;
  final CrosswordBoard board;
  final String activeSheet;
  final double itemExtent;
  final void Function(int number, String direction) onClueTap;

  const _ClueList({
    required this.controller,
    required this.board,
    required this.activeSheet,
    required this.itemExtent,
    required this.onClueTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAcross = activeSheet == 'across';
    final clues = isAcross ? board.acrossClues : board.downClues;
    final clueMap = isAcross ? board.acrossCells : board.downCells;

    if (clues.isEmpty) {
      return Center(
        child: Text(
          'No ${isAcross ? 'across' : 'down'} words',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.grey[500] : AppColors.textLight,
          ),
        ),
      );
    }

    final activeDirection = board.activeDirection ?? (isAcross ? 'across' : 'down');

    return ListView.builder(
      controller: controller,
      itemExtent: itemExtent,
      itemCount: clues.length,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMd),
      itemBuilder: (context, index) {
        final clue = clues[index];
        final isActive = board.activeClueNumber == clue.number &&
            activeDirection == (isAcross ? 'across' : 'down');
        final cells = clueMap[clue.number] ?? [];
        final filledInClue =
            cells.where((c) => c.value.trim().isNotEmpty).length;
        final solved = cells.isNotEmpty && filledInClue == cells.length;
        final clueColor = isAcross ? AppColors.primaryBlue : AppColors.primaryAmber;

        return InkWell(
          onTap: () => onClueTap(clue.number, activeSheet),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingSm,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: isActive
                  ? clueColor.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive
                        ? clueColor
                        : (isDark
                            ? const Color(0xFF334155)
                            : AppColors.bgGray),
                  ),
                  child: Center(
                    child: Text(
                      '${clue.number}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isActive ? Colors.white : clueColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.paddingSm),
                Expanded(
                  child: Text(
                    clue.clue,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: solved
                          ? (isDark ? Colors.grey[500] : AppColors.textLight)
                          : (isDark
                              ? Colors.grey[300]
                              : AppColors.textSecondary),
                      decoration: solved ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                Icon(
                  filledInClue == cells.length && cells.isNotEmpty
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 14,
                  color: filledInClue == cells.length && cells.isNotEmpty
                      ? AppColors.success
                      : (isDark ? Colors.grey[600] : AppColors.borderLight),
                ),
                const SizedBox(width: 6),
                Text(
                  '$filledInClue/${clue.answerLength}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: isDark ? Colors.grey[500] : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
