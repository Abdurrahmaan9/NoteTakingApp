import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_todo/main.dart';

void main() {
  testWidgets('Todo app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TodoApp());

    // Wait for the app to load and show either loading, error, or empty state
    await tester.pumpAndSettle();

    // Verify that our app starts with the correct title
    expect(find.text('Todo App'), findsOneWidget);
    
    // Verify that the add button is present
    expect(find.byIcon(Icons.add), findsOneWidget);
    
    // Check for either loading indicator, error message, or empty state
    final hasLoading = find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
    final hasError = find.textContaining('Error').evaluate().isNotEmpty;
    final hasEmptyState = find.text('No todos yet').evaluate().isNotEmpty;
    
    // At least one of these states should be visible
    expect(hasLoading || hasError || hasEmptyState, isTrue);
  });
}
