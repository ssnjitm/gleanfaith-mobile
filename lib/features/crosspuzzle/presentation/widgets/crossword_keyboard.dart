import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';

enum CrosswordInputMode { pen, pencil }

class CrosswordKeyboard extends StatelessWidget {
  final void Function(String letter) onLetterTap;
  final VoidCallback onBackspace;
  final VoidCallback onToggleMode;
  final CrosswordInputMode mode;
  final Set<String>? revealedHints;

  const CrosswordKeyboard({
    super.key,
    required this.onLetterTap,
    required this.onBackspace,
    required this.onToggleMode,
    this.mode = CrosswordInputMode.pen,
    this.revealedHints,
  });

  static const List<String> _row1 = [
    'Q',
    'W',
    'E',
    'R',
    'T',
    'Y',
    'U',
    'I',
    'O',
    'P',
  ];
  static const List<String> _row2 = [
    'A',
    'S',
    'D',
    'F',
    'G',
    'H',
    'J',
    'K',
    'L',
  ];
  static const List<String> _row3 = ['Z', 'X', 'C', 'V', 'B', 'N', 'M'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE5E7EB),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _lettersRow(context, _row1),
          const SizedBox(height: 6),
          _lettersRow(context, _row2, staggered: true),
          const SizedBox(height: 6),
          Row(
            children: [
              _actionKey(
                isDark: isDark,
                icon: mode == CrosswordInputMode.pen
                    ? Icons.edit_rounded
                    : Icons.edit_off_rounded,
                label: mode == CrosswordInputMode.pen ? 'Pen' : 'Pencil',
                onTap: onToggleMode,
                flex: 4,
                compact: true,
              ),
              const SizedBox(width: 5),
              for (final letter in _row3) ...[
                _letterKey(context, letter, flex: 3),
                const SizedBox(width: 5),
              ],
              _actionKey(
                isDark: isDark,
                icon: Icons.backspace_outlined,
                onTap: onBackspace,
                flex: 4,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _lettersRow(
    BuildContext context,
    List<String> letters, {
    bool staggered = false,
  }) {
    return Row(
      children: [
        if (staggered) const SizedBox(width: 15),
        for (final letter in letters) ...[
          _letterKey(context, letter),
          const SizedBox(width: 5),
        ],
        if (staggered) const SizedBox(width: 15),
      ],
    );
  }

  Widget _letterKey(BuildContext context, String letter, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: _key(context, letter: letter, onTap: () => onLetterTap(letter)),
    );
  }

  Widget _key(
    BuildContext context, {
    required String letter,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(7),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(7),
        onTap: onTap,
        child: Container(
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            boxShadow: isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            letter,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionKey({
    required bool isDark,
    required IconData icon,
    required VoidCallback onTap,
    String? label,
    required int flex,
    bool compact = false,
  }) {
    return Expanded(
      flex: flex,
      child: Material(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(7),
        child: InkWell(
          borderRadius: BorderRadius.circular(7),
          onTap: onTap,
          child: Container(
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              boxShadow: isDark
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: compact && label != null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        size: 18,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.grey[400]
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  )
                : Icon(
                    icon,
                    size: 22,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
          ),
        ),
      ),
    );
  }
}
