import 'package:enhanced_pagination_view/enhanced_pagination_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('separatorBuilder does not crash with zero items', (
    tester,
  ) async {
    final controller = PagingController<int>(
      config: const PagingConfig(
        infiniteScroll: true,
        autoLoadFirstPage: false,
      ),
      itemKeyGetter: (v) => v.toString(),
      pageFetcher: (_) async => <int>[],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EnhancedPaginationView<int>(
            controller: controller,
            enableItemAnimations: false,
            itemBuilder: (context, item, index) => Text('item:$item'),
            separatorBuilder: (context, index) => const Divider(height: 1),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.byType(EnhancedPaginationView<int>), findsOneWidget);
    expect(find.byType(Divider), findsNothing);
  });

  testWidgets('separatorBuilder with empty list after load', (tester) async {
    final controller = PagingController<int>(
      config: const PagingConfig(infiniteScroll: true, autoLoadFirstPage: true),
      itemKeyGetter: (v) => v.toString(),
      pageFetcher: (_) async => <int>[], // Returns empty on first page
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EnhancedPaginationView<int>(
            controller: controller,
            enableItemAnimations: false,
            itemBuilder: (context, item, index) => Text('item:$item'),
            separatorBuilder: (context, index) => const Divider(height: 1),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(EnhancedPaginationView<int>), findsOneWidget);
    expect(find.byType(Divider), findsNothing);
    expect(find.text('item:'), findsNothing);
  });

  testWidgets('separatorBuilder with single item (no separator)', (
    tester,
  ) async {
    final controller = PagingController<int>(
      config: const PagingConfig(infiniteScroll: true, autoLoadFirstPage: true),
      itemKeyGetter: (v) => v.toString(),
      pageFetcher: (_) async => [1], // Single item
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EnhancedPaginationView<int>(
            controller: controller,
            enableItemAnimations: false,
            itemBuilder: (context, item, index) => Text('item:$item'),
            separatorBuilder: (context, index) => const Divider(height: 1),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('item:1'), findsOneWidget);
    expect(find.byType(Divider), findsNothing); // No separator for single item
  });

  testWidgets('separatorBuilder with two items (one separator)', (
    tester,
  ) async {
    final controller = PagingController<int>(
      config: const PagingConfig(infiniteScroll: true, autoLoadFirstPage: true),
      itemKeyGetter: (v) => v.toString(),
      pageFetcher: (_) async => [1, 2],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EnhancedPaginationView<int>(
            controller: controller,
            enableItemAnimations: false,
            itemBuilder: (context, item, index) => Text('item:$item'),
            separatorBuilder: (context, index) => const Divider(height: 1),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('item:1'), findsOneWidget);
    expect(find.text('item:2'), findsOneWidget);
    expect(
      find.byType(Divider),
      findsOneWidget,
    ); // One separator between two items
  });

  testWidgets('separatorBuilder childCount calculation with multiple items', (
    tester,
  ) async {
    final controller = PagingController<int>(
      config: const PagingConfig(infiniteScroll: true, autoLoadFirstPage: true),
      itemKeyGetter: (v) => v.toString(),
      pageFetcher: (_) async => [1, 2, 3, 4, 5],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EnhancedPaginationView<int>(
            controller: controller,
            enableItemAnimations: false,
            itemBuilder: (context, item, index) =>
                SizedBox(height: 50, child: Text('item:$item')),
            separatorBuilder: (context, index) => const Divider(height: 1),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 5 items should have 4 separators
    expect(find.text('item:1'), findsOneWidget);
    expect(find.text('item:5'), findsOneWidget);
    expect(find.byType(Divider), findsNWidgets(4));
  });

  testWidgets('transitions from empty to non-empty with separator', (
    tester,
  ) async {
    var pageData = <int>[];
    final controller = PagingController<int>(
      config: const PagingConfig(infiniteScroll: true, autoLoadFirstPage: true),
      itemKeyGetter: (v) => v.toString(),
      pageFetcher: (_) async => pageData,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EnhancedPaginationView<int>(
            controller: controller,
            enableItemAnimations: false,
            itemBuilder: (context, item, index) => Text('item:$item'),
            separatorBuilder: (context, index) => const Divider(height: 1),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Initially empty
    expect(find.byType(Divider), findsNothing);
    expect(find.text('item:'), findsNothing);

    // Add items and refresh
    pageData = [1, 2, 3];
    controller.refresh();
    await tester.pumpAndSettle();

    // Now should have items and separators
    expect(find.text('item:1'), findsOneWidget);
    expect(find.text('item:2'), findsOneWidget);
    expect(find.text('item:3'), findsOneWidget);
    expect(find.byType(Divider), findsNWidgets(2));
  });

  testWidgets('transitions from non-empty to empty with separator', (
    tester,
  ) async {
    var pageData = [1, 2, 3];
    final controller = PagingController<int>(
      config: const PagingConfig(infiniteScroll: true, autoLoadFirstPage: true),
      itemKeyGetter: (v) => v.toString(),
      pageFetcher: (_) async => pageData,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EnhancedPaginationView<int>(
            controller: controller,
            enableItemAnimations: false,
            itemBuilder: (context, item, index) => Text('item:$item'),
            separatorBuilder: (context, index) => const Divider(height: 1),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Initially has items
    expect(find.text('item:1'), findsOneWidget);
    expect(find.byType(Divider), findsNWidgets(2));

    // Clear items and refresh
    pageData = [];
    controller.refresh();
    await tester.pumpAndSettle();

    // Now should be empty
    expect(find.text('item:'), findsNothing);
    expect(find.byType(Divider), findsNothing);
  });

  testWidgets('custom separator widget with empty list', (tester) async {
    final controller = PagingController<int>(
      config: const PagingConfig(infiniteScroll: true, autoLoadFirstPage: true),
      itemKeyGetter: (v) => v.toString(),
      pageFetcher: (_) async => <int>[],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EnhancedPaginationView<int>(
            controller: controller,
            enableItemAnimations: false,
            itemBuilder: (context, item, index) => Text('item:$item'),
            separatorBuilder: (context, index) => Container(
              height: 20,
              color: Colors.grey,
              child: Text('sep-$index'),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(EnhancedPaginationView<int>), findsOneWidget);
    expect(find.textContaining('sep-'), findsNothing);
  });
}
