import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/common/widgets/alert_widget.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/colors.dart';
import '../../domain/entities/crosspuzzle_entities.dart';
import '../models/crossword_board.dart';
import '../providers/crosspuzzle_provider.dart';
import '../widgets/crossword_clue_bar.dart';
import '../widgets/crossword_grid.dart';
import '../widgets/crossword_keyboard.dart';

enum _BottomPanel { questions, keyboard }

class CrossPuzzlePlayPage extends ConsumerStatefulWidget {
  final String puzzleId;
  final String title;

  const CrossPuzzlePlayPage({
    super.key,
    required this.puzzleId,
    required this.title,
  });

  @override
  ConsumerState<CrossPuzzlePlayPage> createState() =>
      _CrossPuzzlePlayPageState();
}

class _CrossPuzzlePlayPageState extends ConsumerState<CrossPuzzlePlayPage> {
  CrosswordBoard? _board;
  CrossPuzzleDetail? _detail;
  bool _loading = true;
  String? _error;
  bool _saving = false;

  _BottomPanel _bottomPanel = _BottomPanel.keyboard;

  int _mistakes = 0;
  int _hintsUsed = 0;
  int _timeSpentSeconds = 0;
  Timer? _ticker;
  Timer? _autosaveTimer;
  bool _autosaveInFlight = false;
  bool _disposed = false;

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

    final detail = result.fold((failure) {
      setState(() {
        _loading = false;
        _error = failure.message;
      });
      return null;
    }, (detail) => detail);
    if (detail == null) return;

    try {
      final board = CrosswordBoard.fromPuzzle(detail.puzzle);
      board.restore(detail.progress?.gridState, detail.progress?.revealedCells);
      board.markIncorrectCells();

      if (detail.progress != null) {
        _mistakes = detail.progress!.mistakes;
        _hintsUsed = detail.progress!.hintsUsed;
        _timeSpentSeconds = detail.progress!.timeSpentSeconds;
      }

      setState(() {
        _detail = detail;
        _board = board;
        _loading = false;
      });

      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || _disposed) return;
        setState(() => _timeSpentSeconds += 1);
      });
      _startAutosave();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load puzzle: $e';
      });
    }
  }

  void _startAutosave() {
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _autosave(),
    );
  }

  Future<void> _autosave() async {
    final board = _board;
    if (board == null ||
        _autosaveInFlight ||
        _saving ||
        _disposed ||
        !mounted) {
      return;
    }

    _autosaveInFlight = true;
    final snapshotTime = _timeSpentSeconds;
    final snapshotBoard = board.copy();
    try {
      await ref
          .read(saveProgressUseCaseProvider)
          .call(
            puzzleId: widget.puzzleId,
            gridState: snapshotBoard.toGridState(),
            revealedCells: snapshotBoard.toRevealedCells(),
            mistakes: _mistakes,
            hintsUsed: _hintsUsed,
            timeSpentSeconds: snapshotTime,
          )
          .run();
    } finally {
      _autosaveInFlight = false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _ticker?.cancel();
    _autosaveTimer?.cancel();
    if (_board != null && _detail != null) {
      _persistFinalState();
    }
    super.dispose();
  }

  void _persistFinalState() {
    final board = _board!;
    ref
        .read(saveProgressUseCaseProvider)
        .call(
          puzzleId: widget.puzzleId,
          gridState: board.toGridState(),
          revealedCells: board.toRevealedCells(),
          mistakes: _mistakes,
          hintsUsed: _hintsUsed,
          timeSpentSeconds: _timeSpentSeconds,
        )
        .run();
  }

  void _onBoardUpdated(CrosswordBoard board) {
    if (!mounted) return;
    setState(() {});
  }

  void _handleLetter(String letter) {
    final board = _board;
    if (board == null) return;

    final char = letter.toUpperCase();
    if (!RegExp(r'^[A-Z]$').hasMatch(char)) return;

    if (!board.pencilMode && board.hasAnswers) {
      final cell = _selectedCell(board);
      if (cell != null && cell.value.trim().isEmpty) {
        final expected = board.answerCells[cell.key];
        if (expected != null && expected != char) {
          setState(() => _mistakes += 1);
        }
      }
    }

    board.inputLetter(char);
    _onBoardUpdated(board);
  }

  CrosswordCell? _selectedCell(CrosswordBoard board) {
    final r = board.selectedRow;
    final c = board.selectedCol;
    if (r == null || c == null) return null;
    return board.grid[r][c];
  }

  void _handleBackspace() {
    final board = _board;
    if (board == null) return;
    board.handleBackspace();
    _onBoardUpdated(board);
  }

  void _toggleMode() {
    final board = _board;
    if (board == null) return;
    board.setPencilMode(!board.pencilMode);
    _onBoardUpdated(board);
  }

  void _onClearAll() {
    final board = _board;
    if (board == null) return;
    final confirmed = AlertDialog(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1E293B)
          : Colors.white,
      title: const Text('Clear entire grid?'),
      content: const Text('All your answers in this puzzle will be erased.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Clear', style: TextStyle(color: AppColors.error)),
        ),
      ],
    );
    showDialog<bool>(context: context, builder: (_) => confirmed).then((ok) {
      if (ok == true && _board != null) {
        _board!.clearAll();
        _onBoardUpdated(_board!);
      }
    });
  }

  void _onGridTapped(int row, int col, bool isTapOnSelected) {
    final board = _board;
    if (board == null) return;
    if (isTapOnSelected) {
      board.toggleDirection();
    } else {
      board.selectCell(row, col);
    }
    _onBoardUpdated(board);
  }

  void _cycleClue(int delta) {
    final board = _board;
    if (board == null) return;

    final isAcross = (board.activeDirection ?? 'across') == 'across';
    final primary = isAcross ? board.acrossClues : board.downClues;
    final secondary = isAcross ? board.downClues : board.acrossClues;

    final all = [...primary, ...secondary];
    if (all.isEmpty) return;

    final currentIndex = all.indexWhere(
      (c) =>
          c.number == board.activeClueNumber &&
          c.direction == board.activeDirection,
    );
    if (currentIndex < 0) return;

    final next = all[(currentIndex + delta + all.length) % all.length];
    board.selectClue(next.number, next.direction);
    _onBoardUpdated(board);
  }

  Future<void> _handleComplete() async {
    final board = _board;
    if (board == null || _saving) return;
    if (!_canSubmit(board)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fill all boxes correctly to submit'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

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

    final completed = result.fold((failure) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message)));
      return null;
    }, (result) => result);
    if (completed == null) return;

    context.pushReplacement(RouteNames.crossPuzzleResult, extra: completed);
  }

  bool _canSubmit(CrosswordBoard board) {
    if (board.hasAnswers) {
      return board.isFullyCorrect;
    }
    return board.filledCellCount >= board.totalActiveCells;
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
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1E293B)
          : const Color(0xFFF1F5F9),
      body: _loading
          ? _buildLoading()
          : _error != null
          ? _buildError()
          : _buildGame(),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primaryBlue),
    );
  }

  Widget _buildError() {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(_error!, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadDetail, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildGame() {
    final board = _board!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Column(
        children: [
          _buildHeader(board, isDark),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxGridWidth = constraints.maxWidth - 16;
                const paddingTotal = CrosswordGrid.defaultPadding * 2;
                final gapByCols = (board.cols - 1) * CrosswordGrid.cellGap;
                final byWidth =
                    (maxGridWidth - gapByCols - paddingTotal) / board.cols;
                final cellSize = byWidth.clamp(24.0, 44.0).floorToDouble();

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FittedBox(
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                          child: CrosswordGrid(
                            board: board,
                            cellSize: cellSize,
                            padding: const EdgeInsets.all(
                              CrosswordGrid.defaultPadding,
                            ),
                            onCellTapped: _onGridTapped,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildProgressRow(board, isDark),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          _buildBottomPanel(board, isDark),
        ],
      ),
    );
  }

  Widget _buildBottomPanel(CrosswordBoard board, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildClueBar(board, isDark),
        const SizedBox(height: 8),
        _PanelToggle(
          isDark: isDark,
          value: _bottomPanel,
          onChanged: (v) => setState(() => _bottomPanel = v),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 178,
          child: _bottomPanel == _BottomPanel.questions
              ? _QuestionsList(
                  board: board,
                  isDark: isDark,
                  onClueTap: (number, direction) {
                    board.selectClue(number, direction);
                    _onBoardUpdated(board);
                    setState(() => _bottomPanel = _BottomPanel.keyboard);
                  },
                )
              : CrosswordKeyboard(
                  mode: board.pencilMode
                      ? CrosswordInputMode.pencil
                      : CrosswordInputMode.pen,
                  onLetterTap: _handleLetter,
                  onBackspace: _handleBackspace,
                  onToggleMode: _toggleMode,
                ),
        ),
      ],
    );
  }

  Widget _buildHeader(CrosswordBoard board, bool isDark) {
    final progress = board.totalActiveCells == 0
        ? 0.0
        : board.filledCellCount / board.totalActiveCells;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  iconSize: 18,
                  color: isDark ? Colors.white : AppColors.textSecondary,
                  onPressed: () => context.pop(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${board.filledCellCount} of ${board.totalActiveCells} filled',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey[400] : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message:
                    'Lights up a correct letter. Remaining: ${board.currentHintsNeeded}',
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: _useHint,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.lightbulb_rounded,
                          size: 14,
                          color: AppColors.primaryBlue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$_hintsUsed',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              _OverflowMenu(
                isDark: isDark,
                canSubmit: _canSubmit(board),
                onClear: _onClearAll,
                onSubmit: () => _handleComplete(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _HeaderStat(
                icon: Icons.timer_outlined,
                label: _elapsedLabel,
                color: AppColors.primaryAmber,
              ),
              const SizedBox(width: 8),
              _HeaderStat(
                icon: Icons.close_rounded,
                label: '$_mistakes',
                color: AppColors.error,
              ),
              const Spacer(),
              _HeaderStat(
                icon: Icons.grid_view_rounded,
                label: '${board.filledCellCount}/${board.totalActiveCells}',
                color: AppColors.primaryBlue,
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: isDark
                  ? const Color(0xFF334155)
                  : const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _useHint() async {
    final board = _board;
    if (board == null) return;

    final detail = _detail;
    if (detail != null && !detail.revealAnswers) {
      AlertWidget.showInfo(context, 'Hints are disabled for this puzzle');
      return;
    }

    final next = board.revealNextHint();
    if (next == null) return;

    setState(() => _hintsUsed += 1);
    _onBoardUpdated(board);

    if (Theme.of(context).brightness == Brightness.dark) {
      await HapticFeedback.lightImpact();
    }
  }

  Widget _buildProgressRow(CrosswordBoard board, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _Pill(
            icon: Icons.flag_outlined,
            label:
                'Hint ${board.activeClueNumber?.toString() ?? '-'} ${_directionLabel(board.activeDirection ?? 'across')}',
            color: AppColors.primaryBlue,
            isDark: isDark,
          ),
          _Pill(
            icon: Icons.check_rounded,
            label: '${board.filledCellCount}/${board.totalActiveCells}',
            color: AppColors.success,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  String _directionLabel(String direction) => direction == 'across' ? 'A' : 'D';

  Widget _buildClueBar(CrosswordBoard board, bool isDark) {
    final isAcross = (board.activeDirection ?? 'across') == 'across';
    final primary = isAcross ? board.acrossClues : board.downClues;
    final secondary = isAcross ? board.downClues : board.acrossClues;
    final all = [...primary, ...secondary];

    final currentIndex = all.indexWhere(
      (c) =>
          c.number == board.activeClueNumber &&
          c.direction == board.activeDirection,
    );

    final clue = board.activeClue;

    return CrosswordClueBar(
      clueText: clue?.clue,
      clueNumber: clue?.number,
      direction: clue?.direction,
      answerLength: clue?.answerLength,
      canGoPrev: all.length > 1 && currentIndex > 0,
      canGoNext:
          all.length > 1 && currentIndex >= 0 && currentIndex < all.length - 1,
      mode: board.pencilMode
          ? CrosswordInputMode.pencil
          : CrosswordInputMode.pen,
      onPrev: () => _cycleClue(-1),
      onNext: () => _cycleClue(1),
      onToggleMode: _toggleMode,
      onClueTap: () {
        final b = _board;
        if (b == null) return;
        b.toggleDirection();
        _onBoardUpdated(b);
      },
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _HeaderStat({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
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
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;

  const _Pill({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverflowMenu extends StatelessWidget {
  final bool isDark;
  final bool canSubmit;
  final VoidCallback onClear;
  final VoidCallback onSubmit;

  const _OverflowMenu({
    required this.isDark,
    required this.canSubmit,
    required this.onClear,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: PopupMenuButton<String>(
        tooltip: 'More options',
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        onSelected: (value) {
          if (value == 'clear') {
            onClear();
          } else if (value == 'submit') {
            onSubmit();
          }
        },
        icon: Icon(
          Icons.more_vert_rounded,
          size: 20,
          color: isDark ? Colors.white : AppColors.textSecondary,
        ),
        itemBuilder: (context) => [
          PopupMenuItem<String>(
            value: 'submit',
            enabled: canSubmit,
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: canSubmit ? AppColors.success : Colors.grey,
                ),
                const SizedBox(width: 10),
                Text(
                  canSubmit ? 'Submit puzzle' : 'Fill all boxes correctly',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const PopupMenuItem<String>(
            value: 'clear',
            child: Row(
              children: [
                Icon(
                  Icons.delete_sweep_outlined,
                  size: 18,
                  color: AppColors.error,
                ),
                SizedBox(width: 10),
                Text(
                  'Clear grid',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelToggle extends StatelessWidget {
  final bool isDark;
  final _BottomPanel value;
  final ValueChanged<_BottomPanel> onChanged;

  const _PanelToggle({
    required this.isDark,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 40,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            _segment(
              _BottomPanel.questions,
              Icons.menu_book_rounded,
              'Questions',
              AppColors.primaryBlue,
            ),
            _segment(
              _BottomPanel.keyboard,
              Icons.keyboard_alt_outlined,
              'Keyboard',
              AppColors.primaryAmber,
            ),
          ],
        ),
      ),
    );
  }

  Widget _segment(_BottomPanel v, IconData icon, String label, Color accent) {
    final active = value == v;
    final inactiveColor = isDark ? Colors.grey[400]! : AppColors.textMuted;
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: active ? accent.withValues(alpha: 0.16) : Colors.transparent,
          borderRadius: BorderRadius.circular(19),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(19),
          onTap: () => onChanged(v),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: active ? accent : inactiveColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: active ? accent : inactiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestionsList extends StatelessWidget {
  final CrosswordBoard board;
  final bool isDark;
  final void Function(int number, String direction) onClueTap;

  const _QuestionsList({
    required this.board,
    required this.isDark,
    required this.onClueTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE5E7EB),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.31 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 6),
        children: [
          _sectionHeader('Across', AppColors.primaryBlue),
          for (final clue in board.acrossClues)
            _questionTile(clue, AppColors.primaryBlue),
          _sectionHeader('Down', AppColors.primaryAmber),
          for (final clue in board.downClues)
            _questionTile(clue, AppColors.primaryAmber),
        ],
      ),
    );
  }

  Widget _sectionHeader(String label, Color accent) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: accent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Divider(color: accent.withValues(alpha: 0.3), height: 1),
          ),
        ],
      ),
    );
  }

  Widget _questionTile(CrossClue clue, Color accent) {
    final isActive =
        clue.number == board.activeClueNumber &&
        clue.direction == board.activeDirection;
    final correct = board.isClueFilledCorrectly(clue.number, clue.direction);
    final filled = board.isClueFilled(clue.number, clue.direction);

    return InkWell(
      onTap: () => onClueTap(clue.number, clue.direction),
      child: Container(
        color: isActive ? accent.withValues(alpha: 0.10) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: correct
                    ? AppColors.success
                    : filled
                    ? accent.withValues(alpha: 0.18)
                    : Colors.transparent,
                border: Border.all(
                  color: correct
                      ? AppColors.success
                      : accent.withValues(alpha: filled ? 0 : 0.7),
                  width: 1.4,
                ),
              ),
              child: Text(
                '${clue.number}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  color: correct
                      ? Colors.white
                      : filled
                      ? accent
                      : isDark
                      ? Colors.grey[400]
                      : AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                clue.clue,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.25,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (correct)
              const Icon(
                Icons.check_circle_rounded,
                size: 16,
                color: AppColors.success,
              ),
          ],
        ),
      ),
    );
  }
}
