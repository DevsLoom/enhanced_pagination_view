// Enhanced Pagination View Example Tests
//
// Tests for the pagination view example app to verify that all
// example screens and features are working correctly.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/main.dart';

void main() {
  testWidgets('Home screen displays all example cards', (
    WidgetTester tester,
  ) async {
    // Build the app and trigger a frame
    await tester.pumpWidget(const MyApp());

    // Verify that the app bar is displayed
    expect(find.text('Enhanced Pagination Examples'), findsOneWidget);

    // Verify all example cards are present
    expect(find.text('Infinite Scroll'), findsOneWidget);
    expect(find.text('Pagination Buttons'), findsOneWidget);
    expect(find.text('Item Updates'), findsOneWidget);
    expect(find.text('Error Handling'), findsOneWidget);
    expect(find.text('Layouts'), findsOneWidget);

    // Verify descriptions are present
    expect(find.textContaining('infinite scrolling'), findsOneWidget);
    expect(
      find.textContaining('pagination with next/previous'),
      findsOneWidget,
    );
    expect(find.textContaining('Grid, List, and Wrap'), findsOneWidget);
  });

  testWidgets('Navigation to Infinite Scroll example works', (
    WidgetTester tester,
  ) async {
    // Build the app
    await tester.pumpWidget(const MyApp());

    // Find and tap the Infinite Scroll card
    await tester.tap(find.text('Infinite Scroll'));
    await tester.pumpAndSettle();

    // Verify navigation happened
    expect(find.text('Infinite Scroll Example'), findsOneWidget);
  });

  testWidgets('Navigation to Layouts example works', (
    WidgetTester tester,
  ) async {
    // Build the app
    await tester.pumpWidget(const MyApp());

    // Find and tap the Layouts card
    await tester.tap(find.text('Layouts'));
    await tester.pumpAndSettle();

    // Verify navigation happened
    expect(find.text('Layout Examples'), findsOneWidget);

    // Verify layout mode buttons are present
    expect(find.text('List'), findsOneWidget);
    expect(find.text('Grid'), findsOneWidget);
    expect(find.text('Wrap'), findsOneWidget);
  });

  testWidgets('App theme is applied correctly', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const MyApp());

    // Get the MaterialApp widget
    final MaterialApp app = tester.widget(find.byType(MaterialApp));

    // Verify theme settings
    expect(app.debugShowCheckedModeBanner, false);
    expect(app.title, 'Enhanced Pagination Demo');
    expect(app.theme?.useMaterial3, true);
  });
}
