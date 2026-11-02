import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glean_faith_app/features/bible_games/domain/entities/bible_game_entities.dart';
import 'package:glean_faith_app/core/router/app_router.dart';
import 'package:glean_faith_app/features/bible_games/presentation/providers/bible_games_provider.dart';
import 'package:glean_faith_app/features/bible_games/presentation/widgets/home_fun_facts_card.dart';

const List<FunFactRound> _facts = [
  FunFactRound(
    prompt: 'Prompt 1',
    correct: 'Answer 1',
    options: [],
    explain: 'Explain 1',
  ),
  FunFactRound(
    prompt: 'Prompt 2',
    correct: 'Answer 2',
    options: [],
    explain: 'Explain 2',
  ),
  FunFactRound(
    prompt: 'Prompt 3',
    correct: 'Answer 3',
    options: [],
    explain: 'Explain 3',
  ),
];

Future<void> _pumpCard(
  WidgetTester tester, {
  bool isActive = true,
  Duration interval = const Duration(seconds: 1),
  bool disableAnimations = false,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [bibleFunFactsProvider.overrideWith((ref) async => _facts)],
      child: MaterialApp(
        navigatorObservers: [AppRouter.routeObserver],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: disableAnimations),
          child: child!,
        ),
        home: Scaffold(
          body: HomeFunFactsCard(
            isActive: isActive,
            autoSlideInterval: interval,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _disposeCard(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
}

void main() {
  testWidgets('auto-advances to the next fact after the interval', (
    tester,
  ) async {
    await _pumpCard(tester);
    expect(find.text('Prompt 1'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Prompt 2'), findsOneWidget);
    await _disposeCard(tester);
  });

  testWidgets('loops back to the first fact after the last one', (
    tester,
  ) async {
    await _pumpCard(tester);

    for (var i = 0; i < _facts.length; i++) {
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 300));
    }

    expect(find.text('Prompt 1'), findsOneWidget);
    await _disposeCard(tester);
  });

  testWidgets('manual swipe advances and restarts the timer', (tester) async {
    await _pumpCard(tester);

    await tester.drag(find.byType(HomeFunFactsCard), const Offset(-120, 0));
    await tester.pump();
    expect(find.text('Prompt 2'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('Prompt 2'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Prompt 3'), findsOneWidget);

    await _disposeCard(tester);
  });

  testWidgets('play/pause control stops and resumes auto-slide', (
    tester,
  ) async {
    await _pumpCard(tester);

    await tester.tap(find.byTooltip('Pause auto-slide'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Prompt 1'), findsOneWidget);

    await tester.tap(find.byTooltip('Resume auto-slide'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Prompt 2'), findsOneWidget);

    await _disposeCard(tester);
  });

  testWidgets('does not auto-slide while the Home tab is inactive', (
    tester,
  ) async {
    await _pumpCard(tester, isActive: false);

    await tester.pump(const Duration(seconds: 3));

    expect(find.text('Prompt 1'), findsOneWidget);
    await _disposeCard(tester);
  });

  testWidgets('pauses while another route covers Home and resumes on return', (
    tester,
  ) async {
    await _pumpCard(tester);

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    unawaited(
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Overlay')),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Prompt 1', skipOffstage: false), findsOneWidget);

    navigator.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Prompt 1'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Prompt 2'), findsOneWidget);

    await _disposeCard(tester);
  });

  testWidgets('does not auto-slide while the app is backgrounded', (
    tester,
  ) async {
    await _pumpCard(tester);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Prompt 1'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Prompt 2'), findsOneWidget);

    await _disposeCard(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  testWidgets('respects the Reduce Motion setting', (tester) async {
    await _pumpCard(tester, disableAnimations: true);

    await tester.pump(const Duration(seconds: 3));

    expect(find.text('Prompt 1'), findsOneWidget);
    expect(find.byTooltip('Auto-slide is off (Reduce Motion)'), findsOneWidget);
    await _disposeCard(tester);
  });
}
