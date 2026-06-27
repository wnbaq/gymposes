import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymposesapp/features/workout_session/widgets/good_bad_skip_bar.dart';

void main() {
  testWidgets('GoodBadSkipBar shows three buttons', (tester) async {
    String? tapped;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: GoodBadSkipBar(
              onResult: (r) => tapped = r,
            ),
          ),
        ),
      ),
    );

    expect(find.text('GOOD'), findsOneWidget);
    expect(find.text('BAD'), findsOneWidget);
    expect(find.text('SKIP'), findsOneWidget);

    await tester.tap(find.text('GOOD'));
    expect(tapped, 'GOOD');
  });
}
