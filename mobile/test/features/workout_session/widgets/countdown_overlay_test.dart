import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymposesapp/features/workout_session/widgets/countdown_overlay.dart';

void main() {
  testWidgets('shows 3 on first frame', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: CountdownOverlay(onDone: () {})),
    );
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('shows 2 after 1 second', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: CountdownOverlay(onDone: () {})),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('shows 1 after 2 seconds', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: CountdownOverlay(onDone: () {})),
    );
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('calls onDone after 3 seconds', (tester) async {
    bool called = false;
    await tester.pumpWidget(
      MaterialApp(home: CountdownOverlay(onDone: () => called = true)),
    );
    await tester.pump(const Duration(seconds: 3));
    expect(called, true);
  });
}
