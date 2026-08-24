import 'package:flutter/material.dart';

import '../../../../core/theme/colors.dart';
import '../models/crossword_board.dart';

/// Renders the crossword letter grid.
///
/// The logical cell size is fixed; the parent wraps this in a [FittedBox]
/// so the whole board scales to fit the available space.
class CrosswordGrid extends StatelessWidget {
  final CrosswordBoard board;
  final ValueChanged<int> onCellChanged;

  static const double cellSize = 38;

  const CrosswordGrid({
    super.key,
    required this.board,
    required this.onCellChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: board.cols * cellSize,
      height: board.rows * cellSize,
      child: GridView.builder(
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: board.cols,
          childAspectRatio: 1,
        ),
        itemCount: board.rows * board.cols,
        itemBuilder: (context, index) {
          final row = index ~/ board.cols;
          final col = index % board.cols;
          final cell = board.grid[row][col];
          return _Cell(
            cell: cell,
            isDark: isDark,
            onTap: () {
              // Tapping the selected cell again flips Across/Down —
              // standard crossword behaviour.
              if (board.selectedRow == row && board.selectedCol == col) {
                board.toggleDirection();
              } else {
                board.selectCell(row, col);
              }
              onCellChanged(board.filledCellCount);
            },
          );
        },
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final CrosswordCell cell;
  final bool isDark;
  final VoidCallback onTap;

  const _Cell({
    required this.cell,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!cell.isActive) {
      return Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0B1220) : const Color(0xFFF1F2F4),
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }

    final Color fill;
    final Color borderColor;
    var borderWidth = 1.2;

    if (cell.isWrong) {
      fill = AppColors.error.withValues(alpha: 0.28);
      borderColor = AppColors.error.withValues(alpha: 0.7);
    } else if (cell.isSelected) {
      fill = isDark ? const Color(0xFFFFC857) : const Color(0xFFFFD54F);
      borderColor = AppColors.primaryBlue;
      borderWidth = 2.2;
    } else if (cell.inActiveClue) {
      fill = isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE8F0FE);
      borderColor =
          isDark ? const Color(0xFF3B5A80) : AppColors.primaryBlue.withValues(alpha: 0.35);
    } else {
      fill = isDark ? const Color(0xFF16233B) : Colors.white;
      borderColor =
          isDark ? const Color(0xFF2C3E57) : const Color(0xFFCBD5E1);
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(cell.isSelected ? 6 : 4),
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: cell.isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            if (cell.number != null)
              Positioned(
                left: 3,
                top: 1,
                child: Text(
                  '${cell.number}',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    height: 1,
                  ),
                ),
              ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  cell.value,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    color: cell.revealed
                        ? AppColors.success
                        : (isDark ? Colors.white : AppColors.textPrimary),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
