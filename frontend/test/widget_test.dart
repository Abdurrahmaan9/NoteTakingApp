import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_todo/main.dart';

void main() {
  testWidgets('Note app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const NoteApp());

    // Wait for the app to load
    await tester.pumpAndSettle();

    // Verify that our app starts with the correct title (appears twice - in MaterialApp and AppBar)
    expect(find.text('Note Taking App'), findsWidgets);
    
    // Verify that tabs are present
    expect(find.text('Todos'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
    
    // Verify that the add button is present
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
}
