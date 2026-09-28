import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../theme/colors.dart';
import '../../../../router/route_names.dart';
import '../../../../../features/auth/presentation/providers/auth_provider.dart';

/// The single entry point to the profile screen.
///
/// The profile is not a bottom-navigation tab and is not offered as a home
/// quick action — tapping this icon in a top bar is the only way in. Place it
/// in the `actions` of a page `AppBar`, or inline in a custom header row.
class ProfileTopBarButton extends ConsumerWidget {
  /// Shows the user's first initial inside a filled circle instead of the
  /// default person glyph.
  final bool showAvatar;

  const ProfileTopBarButton({super.key, this.showAvatar = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fullName = ref.watch(authProvider).user?.fullName ?? '';
    final initial = fullName.isNotEmpty
        ? fullName.substring(0, 1).toUpperCase()
        : null;

    return IconButton(
      key: const Key('profile_top_bar_button'),
      tooltip: 'Profile',
      onPressed: () => context.push(RouteNames.profile),
      padding: EdgeInsets.zero,
      icon: (showAvatar && initial != null)
          ? CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryBlue,
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : Icon(
              Icons.person_outline,
              color: isDark ? Colors.grey[400] : AppColors.textMuted,
            ),
    );
  }
}
