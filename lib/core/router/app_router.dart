import 'package:go_router/go_router.dart';
import 'route_names.dart';

class AppRouter {
  static GoRouter create() {
    return GoRouter(
      initialLocation: RouteNames.splash,
      routes: [
        // GoRoute(
        //   path: RouteNames.splash,
        //   builder: (context, state) => const SplashPage(),
        // ),
        // GoRoute(
        //   path: RouteNames.home,
        //   builder: (context, state) => const HomePage(),
        // ),
      ],
    );
  }
}
