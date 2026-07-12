import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

extension ContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => mediaQuery.size;
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;
  bool get isDarkMode => theme.brightness == Brightness.dark;

  void pop<T>([T? result]) => GoRouter.of(this).pop(result);

  void pushReplacement(String location, {Object? extra}) =>
      GoRouter.of(this).pushReplacement(location, extra: extra);

  void pushNamed(String name, {Map<String, String> pathParameters = const {}, Map<String, dynamic>? extra}) =>
      GoRouter.of(this).pushNamed(name, pathParameters: pathParameters, extra: extra);

  void goNamed(String name, {Map<String, String> pathParameters = const {}, Map<String, dynamic>? extra}) =>
      GoRouter.of(this).goNamed(name, pathParameters: pathParameters, extra: extra);
}
