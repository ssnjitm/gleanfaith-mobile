import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../router/route_names.dart';
import '../../../../../theme/colors.dart';
import '../../../../../theme/dimensions.dart';
import '../../../../../../features/auth/presentation/providers/auth_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: Text('Hi, ${user?.fullName ?? 'User'}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go(RouteNames.signin);
            },
          ),
        ],
      ),
      drawer: _AppDrawer(userName: user?.fullName, userEmail: user?.email),
      body: const Center(
        child: Text(
          'Home',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  final String? userName;
  final String? userEmail;

  const _AppDrawer({this.userName, this.userEmail});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF111827) : AppColors.bgWhite;

    return Drawer(
      child: Container(
        color: bgColor,
        child: SafeArea(
          child: Column(
            children: [
              _DrawerHeader(userName: userName, userEmail: userEmail),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _DrawerTile(
                      icon: Icons.home_rounded,
                      title: 'Home',
                      onTap: () => Navigator.pop(context),
                    ),
                    _DrawerTile(
                      icon: Icons.quiz_rounded,
                      title: 'Quizzes',
                      onTap: () => Navigator.pop(context),
                    ),
                    _DrawerTile(
                      icon: Icons.leaderboard_rounded,
                      title: 'Leaderboard',
                      onTap: () => Navigator.pop(context),
                    ),
                    _DrawerTile(
                      icon: Icons.library_books_rounded,
                      title: 'Library',
                      onTap: () => Navigator.pop(context),
                    ),
                    const Divider(indent: 16, endIndent: 16),
                    _DrawerTile(
                      icon: Icons.settings_rounded,
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
                child: Text(
                  'v1.0.0',
                  style: TextStyle(
                    color: isDark ? Colors.grey[600] : AppColors.textLight,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  final String? userName;
  final String? userEmail;

  const _DrawerHeader({this.userName, this.userEmail});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryBlue, Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(
              (userName?.isNotEmpty == true) ? userName!.substring(0, 1).toUpperCase() : 'U',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            userName ?? 'User',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (userEmail != null) ...[
            const SizedBox(height: 4),
            Text(
              userEmail!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      leading: Icon(icon, color: isDark ? Colors.grey[400] : AppColors.textMuted),
      title: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.grey[300] : AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}