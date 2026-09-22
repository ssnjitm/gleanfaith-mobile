import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../theme/colors.dart';
import '../../../../theme/dimensions.dart';
import '../../../../router/route_names.dart';
import '../../../home/presentation/providers/main_tab_provider.dart';
import '../../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../../features/notification/presentation/providers/notification_provider.dart';

class ProfileDrawer extends ConsumerStatefulWidget {
  const ProfileDrawer({super.key});

  @override
  ConsumerState<ProfileDrawer> createState() => _ProfileDrawerState();
}

class _ProfileDrawerState extends ConsumerState<ProfileDrawer> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      final state = ref.read(notificationsProvider);
      if (state.status == NotificationStatus.initial) {
        ref.read(notificationsProvider.notifier).load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final unread = ref.watch(notificationsProvider).unreadCount;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF0F172A) : AppColors.bgWhite,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, user?.fullName, user?.email, isDark),
            const Divider(
              height: 1,
              color: AppColors.borderLight,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: AppDimensions.sm),
                children: [
                  _buildMenuItem(
                    context,
                    icon: Icons.person_outline,
                    title: 'Edit Profile',
                    onTap: () {
                      Navigator.pop(context);
                      context.push(RouteNames.profileEdit);
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.quiz_outlined,
                    title: 'My Quizzes',
                    onTap: () {
                      Navigator.pop(context);
                      ref.read(mainTabIndexProvider.notifier).state = 1;
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.leaderboard_outlined,
                    title: 'My Rankings',
                    onTap: () {
                      Navigator.pop(context);
                      ref.read(mainTabIndexProvider.notifier).state = 2;
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    badgeCount: unread,
                    onTap: () {
                      Navigator.pop(context);
                      context.push(RouteNames.notifications);
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.bookmarks_outlined,
                    title: 'Bible Bookmarks',
                    onTap: () {
                      Navigator.pop(context);
                      context.pushNamed(RouteNames.bibleBookmarks);
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.sticky_note_2_outlined,
                    title: 'Chapter Notes',
                    onTap: () {
                      Navigator.pop(context);
                      context.pushNamed(RouteNames.bibleNotes);
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                      context.push(RouteNames.settings);
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingMd),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) context.go(RouteNames.signin);
                  },
                  icon: Icon(
                    Icons.logout_rounded,
                    size: 18,
                    color: isDark ? AppColors.errorLight : AppColors.error,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        isDark ? AppColors.errorLight : AppColors.error,
                    side: BorderSide(
                      color: isDark ? AppColors.errorLight : AppColors.error,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusMd),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  label: const Text(
                    'Sign Out',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String? fullName, String? email,
      bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingLg),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(
              (fullName?.isNotEmpty == true)
                  ? fullName!.substring(0, 1).toUpperCase()
                  : 'U',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.paddingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName ?? 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  email ?? '',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : AppColors.bgGray,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        child: Icon(
          icon,
          color: isDark ? Colors.grey[400] : AppColors.textMuted,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.grey[200] : AppColors.textPrimary,
        ),
      ),
      trailing: badgeCount > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(999),
              ),
              constraints: const BoxConstraints(minWidth: 22),
              child: Text(
                badgeCount > 99 ? '99+' : '$badgeCount',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : null,
      onTap: onTap,
    );
  }
}