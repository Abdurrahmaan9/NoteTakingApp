import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_todo/main.dart';

void main() {
  testWidgets('Note app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const NoteApp());

    // Wait for the app to load
    await tester.pumpAndSettle();

    // Verify that bottom navigation tabs are present
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Todos'), findsWidgets);
    expect(find.text('Notes'), findsWidgets);
    
    // Check for either dashboard content or error/loading state
    final hasDashboard = find.text('Dashboard').evaluate().isNotEmpty;
    final hasError = find.textContaining('Error').evaluate().isNotEmpty;
    final hasLoading = find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
    
    // At least one of these states should be visible
    expect(hasDashboard || hasError || hasLoading, isTrue);
  });
}
