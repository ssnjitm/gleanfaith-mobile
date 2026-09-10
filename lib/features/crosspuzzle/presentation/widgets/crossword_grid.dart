import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../models/crossword_board.dart';

class CrosswordGrid extends StatefulWidget {
  final CrosswordBoard board;
  final void Function(int row, int col, bool isTapOnSelected) onCellTapped;
  final double cellSize;
  final EdgeInsetsGeometry padding;

  static const double cellGap = 1.0;
  static const double defaultPadding = 6.0;

  const CrosswordGrid({
    super.key,
    required this.board,
    required this.onCellTapped,
    this.cellSize = 36,
    this.padding = const EdgeInsets.all(defaultPadding),
  });

  @override
  State<CrosswordGrid> createState() => _CrosswordGridState();
}

class _CrosswordGridState extends State<CrosswordGrid> {
  bool _prevClueFilled = false;
  bool _flashWordGreen = false;
  int _flashCounter = 0;

  @override
  void didUpdateWidget(covariant CrosswordGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    final filled = widget.board.activeClueFilledCorrectly;
    if (!_prevClueFilled && filled) {
      setState(() {
        _flashWordGreen = true;
        _flashCounter += 1;
      });
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) {
          setState(() => _flashWordGreen = false);
        }
      });
    }
    _prevClueFilled = filled;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final board = widget.board;
    final size = widget.cellSize;
    const gap = CrosswordGrid.cellGap;
    final contentWidth = board.cols * size + math.max(0, board.cols - 1) * gap;
    final contentHeight = board.rows * size + math.max(0, board.rows - 1) * gap;

    return Container(
      width: contentWidth + widget.padding.horizontal,
      height: contentHeight + widget.padding.vertical,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B1220) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var r = 0; r < board.rows; r++)
            Padding(
              padding: EdgeInsets.only(bottom: r == board.rows - 1 ? 0.0 : gap),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var c = 0; c < board.cols; c++)
                    Padding(
                      padding: EdgeInsets.only(
                        right: c == board.cols - 1 ? 0.0 : gap,
                      ),
                      child: _GridCell(
                        key: ValueKey('cell-$r-$c-$_flashCounter'),
                        view: _CellView.fromCell(board.grid[r][c]),
                        isDark: isDark,
                        cellSize: size,
                        flashGreen:
                            _flashWordGreen && board.grid[r][c].inActiveClue,
                        onTap: () => widget.onCellTapped(
                          r,
                          c,
                          board.selectedRow == r && board.selectedCol == c,
                        ),
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

class _CellView {
  final int row;
  final int col;
  final int? number;
  final String value;
  final String pencilValue;
  final bool revealed;
  final bool isActive;
  final bool isSelected;
  final bool inActiveClue;
  final bool isWrong;

  const _CellView({
    required this.row,
    required this.col,
    this.number,
    this.value = '',
    this.pencilValue = '',
    this.revealed = false,
    this.isActive = false,
    this.isSelected = false,
    this.inActiveClue = false,
    this.isWrong = false,
  });

  factory _CellView.fromCell(CrosswordCell cell) {
    return _CellView(
      row: cell.row,
      col: cell.col,
      number: cell.number,
      value: cell.value,
      pencilValue: cell.pencilValue,
      revealed: cell.revealed,
      isActive: cell.isActive,
      isSelected: cell.isSelected,
      inActiveClue: cell.inActiveClue,
      isWrong: cell.isWrong,
    );
  }
}

class _GridCell extends StatefulWidget {
  final _CellView view;
  final bool isDark;
  final double cellSize;
  final bool flashGreen;
  final VoidCallback onTap;

  const _GridCell({
    super.key,
    required this.view,
    required this.isDark,
    required this.cellSize,
    required this.flashGreen,
    required this.onTap,
  });

  @override
  State<_GridCell> createState() => _GridCellState();
}

class _GridCellState extends State<_GridCell> with TickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final Animation<double> _shakeOffset;
  bool _wasWrong = false;

  @override
  void initState() {
    super.initState();
    _wasWrong = widget.view.isWrong && widget.view.value.isNotEmpty;
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    final tween = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: -6.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: -6.0,
          end: 6.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 6.0,
          end: -4.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: -4.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
    ]);
    _shakeOffset = _shakeController.drive(tween);
  }

  @override
  void didUpdateWidget(covariant _GridCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final view = widget.view;
    final nowWrong = view.isWrong && view.value.isNotEmpty;

    if (!_wasWrong && nowWrong) {
      _shakeController.forward(from: 0);
    }
    _wasWrong = nowWrong;
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final view = widget.view;

    if (!view.isActive) {
      return Container(
        width: widget.cellSize,
        height: widget.cellSize,
        decoration: BoxDecoration(
          color: widget.isDark
              ? const Color(0xFF0B1220)
              : const Color(0xFFCBD5E1),
          borderRadius: BorderRadius.circular(2),
        ),
      );
    }

    final isSelected = view.isSelected;
    final inActive = view.inActiveClue;
    final showFlash = widget.flashGreen;

    final Color fill;
    final Color borderColor;
    double borderWidth = 1.0;

    if (isSelected) {
      fill = AppColors.primaryBlue;
      borderColor = AppColors.primaryBlue;
      borderWidth = 0;
    } else if (view.isWrong) {
      fill = AppColors.error.withValues(alpha: 0.18);
      borderColor = AppColors.error.withValues(alpha: 0.55);
    } else if (view.revealed) {
      fill = widget.isDark ? const Color(0xFF1A3A2A) : const Color(0xFFE8F5E9);
      borderColor = widget.isDark
          ? AppColors.success.withValues(alpha: 0.6)
          : AppColors.success.withValues(alpha: 0.4);
    } else if (inActive) {
      fill = widget.isDark
          ? AppColors.primaryBlue.withValues(alpha: 0.28)
          : AppColors.primaryBlue.withValues(alpha: 0.14);
      borderColor = widget.isDark
          ? AppColors.primaryBlue.withValues(alpha: 0.5)
          : AppColors.primaryBlue.withValues(alpha: 0.3);
    } else {
      fill = widget.isDark ? const Color(0xFF16233B) : Colors.white;
      borderColor = widget.isDark
          ? const Color(0xFF2C3E57)
          : const Color(0xFFCBD5E1);
    }

    final hasNumber = view.number != null;
    final showPencil = view.pencilValue.isNotEmpty && !view.revealed;
    final letterColor = isSelected
        ? Colors.white
        : view.isWrong
        ? AppColors.error
        : view.revealed
        ? AppColors.success
        : widget.isDark
        ? Colors.white
        : AppColors.textPrimary;

    final cell = AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      width: widget.cellSize,
      height: widget.cellSize,
      decoration: BoxDecoration(
        color: showFlash ? AppColors.success : fill,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: showFlash ? AppColors.success : borderColor,
          width: borderWidth,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(alpha: 0.45),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : showFlash
            ? [
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fontSize = math.max(13.0, widget.cellSize * 0.48);
          final numSize = math.max(5.0, widget.cellSize * 0.2);
          return Stack(
            fit: StackFit.expand,
            children: [
              if (hasNumber)
                Positioned(
                  left: 2,
                  top: 1,
                  child: Text(
                    '${view.number}',
                    style: TextStyle(
                      fontSize: numSize,
                      fontWeight: FontWeight.w700,
                      height: 1,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.85)
                          : widget.isDark
                          ? Colors.grey[500]
                          : Colors.grey[500],
                    ),
                  ),
                ),
              if (showPencil)
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Text(
                    view.pencilValue,
                    style: TextStyle(
                      fontSize: math.max(8.0, widget.cellSize * 0.24),
                      fontWeight: FontWeight.w600,
                      height: 1,
                      color: widget.isDark
                          ? Colors.grey[400]
                          : Colors.grey[500],
                    ),
                  ),
                ),
              if (view.value.isNotEmpty && !showPencil)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      view.value,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w700,
                        height: 1,
                        letterSpacing: 0.5,
                        color: letterColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _shakeController,
        builder: (context, child) {
          final dx = _shakeOffset.value;
          return Transform.translate(offset: Offset(dx, 0), child: cell);
        },
      ),
    );
  }
}
