import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:field_notes_app/presentation/widgets/status_badge.dart';
import 'package:field_notes_app/presentation/widgets/empty_state.dart';

void main() {
  testWidgets('StatusBadge renders correct status and uppercase text', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatusBadge(status: 'completed'),
        ),
      ),
    );

    expect(find.text('COMPLETED'), findsOneWidget);
  });

  testWidgets('EmptyState renders title, message, and responds to action button', (WidgetTester tester) async {
    bool buttonPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: Icons.assignment_outlined,
            title: 'No Items',
            message: 'Nothing here yet.',
            actionLabel: 'Add One',
            onAction: () => buttonPressed = true,
          ),
        ),
      ),
    );

    expect(find.text('No Items'), findsOneWidget);
    expect(find.text('Nothing here yet.'), findsOneWidget);
    expect(find.text('Add One'), findsOneWidget);

    await tester.tap(find.text('Add One'));
    expect(buttonPressed, isTrue);
  });
}
