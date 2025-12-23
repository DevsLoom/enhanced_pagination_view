import 'package:enhanced_pagination_view/enhanced_pagination_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'does not crash when compensateForTrimmedItems enabled but duplicate item keys are present',
    (tester) async {
      final controller = PagingController<int>(
        config: const PagingConfig(
          pageSize: 10,
          infiniteScroll: true,
          cacheMode: CacheMode.limited,
          maxCachedItems: 50,
          compensateForTrimmedItems: true,
          autoLoadFirstPage: true,
        ),
        itemKeyGetter: (item) => item.toString(),
        pageFetcher: (page) async {
          if (page == 0) {
            // Duplicate keys: "1" appears twice.
            return <int>[1, 1, 2, 3];
          }
          return <int>[];
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedPaginationView<int>(
              controller: controller,
              enableItemAnimations: false,
              itemBuilder: (context, item, index) =>
                  ListTile(title: Text('item:$item')),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('item:1'), findsWidgets);
      expect(find.text('item:2'), findsOneWidget);
      expect(find.text('item:3'), findsOneWidget);
    },
  );

  testWidgets(
    'does not crash with empty keys when compensateForTrimmedItems is enabled',
    (tester) async {
      final controller = PagingController<int>(
        config: const PagingConfig(
          pageSize: 10,
          infiniteScroll: true,
          cacheMode: CacheMode.limited,
          maxCachedItems: 50,
          compensateForTrimmedItems: true,
          autoLoadFirstPage: true,
        ),
        itemKeyGetter: (item) => '', // Empty key for all items
        pageFetcher: (page) async {
          if (page == 0) {
            return <int>[1, 2, 3, 4];
          }
          return <int>[];
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedPaginationView<int>(
              controller: controller,
              enableItemAnimations: false,
              itemBuilder: (context, item, index) =>
                  ListTile(title: Text('item:$item')),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should render all items without crashing
      expect(find.text('item:1'), findsOneWidget);
      expect(find.text('item:2'), findsOneWidget);
      expect(find.text('item:3'), findsOneWidget);
      expect(find.text('item:4'), findsOneWidget);
    },
  );

  testWidgets('handles all duplicate keys gracefully', (tester) async {
    final controller = PagingController<int>(
      config: const PagingConfig(
        pageSize: 10,
        infiniteScroll: true,
        cacheMode: CacheMode.limited,
        maxCachedItems: 50,
        compensateForTrimmedItems: true,
        autoLoadFirstPage: true,
      ),
      itemKeyGetter: (item) => 'same-key', // Same key for all items
      pageFetcher: (page) async {
        if (page == 0) {
          return <int>[1, 2, 3, 4, 5];
        }
        return <int>[];
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EnhancedPaginationView<int>(
            controller: controller,
            enableItemAnimations: false,
            itemBuilder: (context, item, index) =>
                ListTile(title: Text('item:$item')),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Should render all items without crashing
    expect(find.text('item:1'), findsOneWidget);
    expect(find.text('item:2'), findsOneWidget);
    expect(find.text('item:3'), findsOneWidget);
    expect(find.text('item:4'), findsOneWidget);
    expect(find.text('item:5'), findsOneWidget);
  });

  testWidgets('scrolls without crashing when duplicate keys present', (
    tester,
  ) async {
    final controller = PagingController<int>(
      config: const PagingConfig(
        pageSize: 20,
        infiniteScroll: true,
        cacheMode: CacheMode.limited,
        maxCachedItems: 50,
        compensateForTrimmedItems: true,
        autoLoadFirstPage: true,
      ),
      itemKeyGetter: (item) => (item % 5).toString(), // Duplicate keys
      pageFetcher: (page) async {
        if (page == 0) {
          return List.generate(20, (i) => i);
        }
        if (page == 1) {
          return List.generate(20, (i) => i + 20);
        }
        return <int>[];
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EnhancedPaginationView<int>(
            controller: controller,
            enableItemAnimations: false,
            itemBuilder: (context, item, index) => SizedBox(
              height: 50,
              child: ListTile(title: Text('item:$item')),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Scroll down
    await tester.drag(
      find.byType(EnhancedPaginationView<int>),
      const Offset(0, -1000),
    );
    await tester.pumpAndSettle();

    // Should not crash during scroll
    expect(find.byType(EnhancedPaginationView<int>), findsOneWidget);

    // Scroll up
    await tester.drag(
      find.byType(EnhancedPaginationView<int>),
      const Offset(0, 500),
    );
    await tester.pumpAndSettle();

    // Should still not crash
    expect(find.byType(EnhancedPaginationView<int>), findsOneWidget);
  });

  testWidgets('mix of empty and duplicate keys handled gracefully', (
    tester,
  ) async {
    final items = [1, 2, 3, 4, 5, 6];
    final controller = PagingController<int>(
      config: const PagingConfig(
        pageSize: 10,
        infiniteScroll: true,
        cacheMode: CacheMode.limited,
        maxCachedItems: 50,
        compensateForTrimmedItems: true,
        autoLoadFirstPage: true,
      ),
      itemKeyGetter: (item) {
        // Mix of empty, duplicate, and valid keys
        if (item == 1 || item == 2) return '';
        if (item == 3 || item == 4) return 'dup';
        return item.toString();
      },
      pageFetcher: (page) async {
        if (page == 0) {
          return items;
        }
        return <int>[];
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EnhancedPaginationView<int>(
            controller: controller,
            enableItemAnimations: false,
            itemBuilder: (context, item, index) =>
                ListTile(title: Text('item:$item')),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Should render all items without crashing
    for (final item in items) {
      expect(find.text('item:$item'), findsOneWidget);
    }
  });
}
