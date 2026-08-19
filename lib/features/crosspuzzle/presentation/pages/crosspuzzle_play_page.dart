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

  final FocusNode _keyboardFocusNode = FocusNode();
  final FocusNode _hiddenInputFocusNode = FocusNode();
  final TextEditingController _hiddenInputController =
      TextEditingController(text: ' ');

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
    if (!_hiddenInputFocusNode.hasFocus) {
      FocusScope.of(context).requestFocus(_hiddenInputFocusNode);
    }
  }

  void _onCellChanged(int filledCount) {
    setState(() {
      if (_board != null) {
        _activeSheet = _board!.activeDirection ?? 'across';
      }
    });
    _requestFocusForInput();
    _scheduleAutosave();
  }

  void _handleTextInput(String value) {
    final board = _board;
    if (board == null) return;

    if (value.isEmpty) {
      if (board.selectedCol != null && board.selectedRow != null) {
        final cell = board.grid[board.selectedRow!][board.selectedCol!];
        if (cell.value.isEmpty) {
          if (board.activeDirection == 'across') {
            board.moveBy(0, -1);
          } else {
            board.moveBy(-1, 0);
          }
        }
      }
      board.clearCell();
      _resetHiddenController();
      _onCellChanged(board.filledCellCount);
      return;
    }

    if (value.length > 1) {
      final char = value.substring(value.length - 1);
      
      if (board.inputLetter(char)) {
        if (board.activeDirection == 'across') {
          board.moveBy(0, 1);
        } else {
          board.moveBy(1, 0);
        }
      }
      _resetHiddenController();
      _onCellChanged(board.filledCellCount);
    }
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
    } else if (key == LogicalKeyboardKey.tab) {
      if (event.character == null) {
        board.toggleDirection();
        _onCellChanged(board.filledCellCount);
      }
    }
  }

  void _useHint() {
    final board = _board;
    if (board == null) return;
    final revealed = board.revealNextHint();
    if (revealed != null) {
      setState(() {
        _hintsUsed += 1;
      });
      HapticFeedback.lightImpact();
      _onCellChanged(board.filledCellCount);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That clue is already solved!')),
      );
    }
  }

  Future<void> _complete() async {
    final board = _board;
    if (board == null || _saving) return;

    if (board.filledCellCount < board.totalActiveCells) {
      final confirmed = await _confirmIncomplete();
      if (!confirmed) return;
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

  Future<bool> _confirmIncomplete() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Puzzle not complete'),
        content: const Text(
          'You still have empty cells. Submit anyway? The server grades what you filled.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep playing'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    return result ?? false;
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
              child: Text(
                _elapsedLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryAmber,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            SizedBox(
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
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppDimensions.paddingMd),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _StatPill(
                              icon: Icons.check_circle_outline_rounded,
                              label: '${board.filledCellCount}/${board.totalActiveCells}',
                              color: AppColors.success,
                            ),
                            const SizedBox(width: AppDimensions.sm),
                            _StatPill(
                              icon: Icons.lightbulb_outline_rounded,
                              label: '$_hintsUsed',
                              color: AppColors.primaryAmber,
                            ),
                            const SizedBox(width: AppDimensions.sm),
                            _StatPill(
                              icon: Icons.error_outline_rounded,
                              label: '$_mistakes',
                              color: AppColors.error,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.paddingMd),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: GestureDetector(
                            onTap: _requestFocusForInput,
                            child: CrosswordGrid(
                              board: board,
                              onCellChanged: _onCellChanged,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.paddingMd,
                    AppDimensions.paddingSm,
                    AppDimensions.paddingMd,
                    AppDimensions.paddingSm,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    border: Border(
                      top: BorderSide(
                        color: isDark ? const Color(0xFF334155) : AppColors.borderLight,
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _TabChip(
                              label: 'Across',
                              active: _activeSheet == 'across',
                              color: AppColors.primaryBlue,
                              onTap: () => setState(() => _activeSheet = 'across'),
                            ),
                          ),
                          const SizedBox(width: AppDimensions.sm),
                          Expanded(
                            child: _TabChip(
                              label: 'Down',
                              active: _activeSheet == 'down',
                              color: AppColors.primaryAmber,
                              onTap: () => setState(() => _activeSheet = 'down'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.sm),
                      SizedBox(
                        height: 90,
                        child: _SheetList(
                          board: board,
                          acrossClues: board.acrossClues,
                          downClues: board.downClues,
                          activeSheet: _activeSheet,
                          onClueTap: (number, direction) {
                            board.selectClue(number, direction);
                            _onCellChanged(board.filledCellCount);
                          },
                        ),
                      ),
                      const SizedBox(height: AppDimensions.sm),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _saving ? null : _useHint,
                              icon: const Icon(Icons.lightbulb_outline_rounded, size: 18),
                              label: const Text('Hint'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primaryAmber,
                                side: const BorderSide(color: AppColors.primaryAmber),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppDimensions.sm),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _saving ? null : _complete,
                              icon: _saving
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.check_rounded, size: 18),
                              label: Text(_saving ? 'Grading…' : 'Submit'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue,
                                foregroundColor: Colors.white,
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
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingSm + 2,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
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
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? color.withValues(alpha: 0.12)
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F2F4)),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(
            color: active ? color : Colors.transparent,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: active ? color : (isDark ? Colors.grey[400] : AppColors.textMuted),
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetList extends StatelessWidget {
  final CrosswordBoard board;
  final List<CrossClue> acrossClues;
  final List<CrossClue> downClues;
  final String activeSheet;
  final void Function(int number, String direction) onClueTap;

  const _SheetList({
    required this.board,
    required this.acrossClues,
    required this.downClues,
    required this.activeSheet,
    required this.onClueTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAcross = activeSheet == 'across';
    final clues = isAcross ? acrossClues : downClues;

    final activeDirection = board.activeDirection ?? (isAcross ? 'across' : 'down');

    return ListView(
      children: clues.map((clue) {
        final isActive = board.activeClueNumber == clue.number &&
            activeDirection == (isAcross ? 'across' : 'down');
        final cells = (isAcross ? board.acrossCells : board.downCells)[clue.number] ?? [];
        final filledInClue = cells.where((c) => c.value.trim().isNotEmpty).length;
        final clueColor = isAcross ? AppColors.primaryBlue : AppColors.primaryAmber;

        return InkWell(
          onTap: () => onClueTap(clue.number, activeDirection),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingSm,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: isActive ? clueColor.withValues(alpha: 0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? clueColor : (isDark ? const Color(0xFF334155) : AppColors.bgGray),
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
                      color: isDark ? Colors.grey[300] : AppColors.textSecondary,
                    ),
                  ),
                ),
                Text(
                  '$filledInClue/${clue.answerLength}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}