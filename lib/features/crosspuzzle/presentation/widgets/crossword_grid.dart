import 'package:flutter/material.dart';

import '../../../../core/theme/colors.dart';
import '../models/crossword_board.dart';

/// Renders the crossword letter grid.
class CrosswordGrid extends StatelessWidget {
  final CrosswordBoard board;
  final ValueChanged<int> onCellChanged;

  const CrosswordGrid({
    super.key,
    required this.board,
    required this.onCellChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: AspectRatio(
        aspectRatio: board.cols / board.rows,
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
                board.selectCell(row, col);
                onCellChanged(board.filledCellCount);
              },
            );
          },
        ),
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
    final BorderSide side;

    if (!cell.isActive) {
      return Container(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F2F4),
        margin: const EdgeInsets.all(0.5),
      );
    }

    final baseColor = isDark
        ? (cell.isSelected ? const Color(0xFFFFC857) : const Color(0xFF1E293B))
        : (cell.isSelected ? const Color(0xFFFFD54F) : Colors.white);

    side = BorderSide(
      color: cell.isSelected
          ? AppColors.primaryBlue
          : (cell.inActiveClue
              ? (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1))
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
      width: cell.isSelected ? 2 : 1,
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cell.isWrong
              ? AppColors.error.withValues(alpha: 0.35)
              : baseColor,
          border: Border.fromBorderSide(side),
        ),
        child: Stack(
          children: [
            if (cell.number != null)
              Positioned(
                left: 1,
                top: 0,
                child: Text(
                  '${cell.number}',
                  style: TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    height: 1,
                  ),
                ),
              ),
            Center(
              child: Text(
                cell.value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: cell.revealed
                      ? AppColors.success
                      : (isDark ? Colors.white : AppColors.textPrimary),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}