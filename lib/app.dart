import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'bootstrap.dart';
import 'core/common/providers/theme_mode_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/colors.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = AppRouter.create();
    AppBootstrap.init();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    ref.listen(authProvider, (_, next) {
      AppRouter.redirectNotifier.update(next.status);
    });

    return MaterialApp.router(
      title: 'Glean Faith',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      // A slow cross-fade between themes avoids the white flash that a hard
      // swap produces on pages whose background is painted manually.
      themeAnimationDuration: const Duration(milliseconds: 300),
      themeAnimationCurve: Curves.easeInOut,
      // Pages without an AppBar would otherwise keep the platform's default
      // status-bar icons, which disappear against the dark background.
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: (isDark
                  ? SystemUiOverlayStyle.light
                  : SystemUiOverlayStyle.dark)
              .copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor:
                isDark ? AppColors.darkBg : AppColors.bgWhite,
            systemNavigationBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
            systemNavigationBarDividerColor: Colors.transparent,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      routerConfig: _router,
    );
  }
}
